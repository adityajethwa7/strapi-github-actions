# Stage 1: Base image with TypeScript support
FROM node:18-alpine AS base

# Remove dumb-init step
# RUN apk add --no-cache dumb-init 👈 removed

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001

WORKDIR /opt/app

# Stage 2: Dependencies stage
FROM base AS deps

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies (keep silent to reduce build logs)
RUN npm ci --silent

# Stage 3: Build stage
FROM base AS build

# Copy dependencies from deps stage
COPY --from=deps /opt/app/node_modules ./node_modules
COPY --from=deps /opt/app/package*.json ./
COPY --from=deps /opt/app/tsconfig.json ./

# Copy rest of the app source
COPY . .

# ADDED: Debug line to print the database.js content during build
RUN cat config/database.js

# Build the application (includes Strapi build)
RUN npm run build

# Stage 4: Production runtime stage
FROM base AS runtime

# Copy only required packages
COPY --from=deps /opt/app/package*.json ./
COPY --from=deps /opt/app/node_modules ./node_modules
COPY --from=deps /opt/app/tsconfig.json ./

# Copy built application from build stage
COPY --from=build --chown=strapi:nodejs /opt/app/dist ./dist

COPY --from=build --chown=strapi:nodejs /opt/app/public ./public
COPY --from=build --chown=strapi:nodejs /opt/app/config ./config
COPY --from=build --chown=strapi:nodejs /opt/app/database ./database
COPY --from=build --chown=strapi:nodejs /opt/app/src ./src

# Use non-root user
USER strapi

# Expose Strapi port
EXPOSE 1337

# DO NOT require dumb-init — just run the app directly
CMD ["npm", "start"]
