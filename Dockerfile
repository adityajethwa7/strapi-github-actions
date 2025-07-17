FROM node:22-slim

# Install native deps needed for better-sqlite3
RUN apt-get update && apt-get install -y \
  python3 \
  make \
  g++ \
  sqlite3 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only package.json + lock to install deps
COPY package*.json ./

# Install deps inside container
RUN npm install

# Now copy rest of your code
COPY . .

# Build admin panel
RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "develop"]
