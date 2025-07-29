# Strapi AWS ECS Fargate Deployment

This project contains a Strapi application configured for deployment on AWS using ECS Fargate, managed entirely via Terraform.

## Architecture Overview

The deployment creates the following AWS resources:

- **ECR Repository**: Stores the Docker images
- **ECS Cluster**: Manages the containerized application
- **ECS Task Definition**: Defines the container configuration
- **ECS Service**: Runs the application with Fargate launch type
- **Application Load Balancer (ALB)**: Provides public access to the application
- **Security Groups**: Controls network access
- **IAM Roles**: Provides necessary permissions for ECS tasks
- **CloudWatch Log Group**: Collects application logs

## Prerequisites

Before deploying, ensure you have the following installed:

1. **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **Docker** - [Installation Guide](https://docs.docker.com/get-docker/)
3. **Terraform** - [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## AWS Configuration

1. Configure your AWS credentials:
   ```bash
   aws configure
   ```

2. Ensure your AWS user has the following permissions:
   - ECR (Elastic Container Registry)
   - ECS (Elastic Container Service)
   - EC2 (for VPC, Security Groups, Load Balancer)
   - IAM (for roles and policies)
   - CloudWatch (for logging)

## Quick Start

### Deploy the Application

1. Clone this repository and navigate to the project directory:
   ```bash
   cd strapi-project
   ```

2. Run the deployment script:
   ```bash
   ./scripts/deploy.sh
   ```

The script will:
- Check prerequisites and AWS credentials
- Initialize Terraform
- Build the Docker image
- Push the image to ECR
- Deploy the infrastructure
- Wait for the service to become healthy
- Display the application URL

### Access Your Application

After successful deployment, the script will output the Application Load Balancer URL. Your Strapi application will be accessible at:
```
http://your-alb-url.us-east-1.elb.amazonaws.com
```

### Clean Up Resources

To destroy all AWS resources and clean up:
```bash
./scripts/cleanup.sh
```

## Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### 1. Initialize Terraform

```bash
cd terraform
terraform init
terraform workspace new dev  # or select existing workspace
```

### 2. Create ECR Repository

```bash
terraform apply -target=aws_ecr_repository.strapi -auto-approve
```

### 3. Build and Push Docker Image

```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)

# Build the image
docker build -t strapi-app:latest .

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL

# Tag and push
docker tag strapi-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Deploy Infrastructure

```bash
terraform plan
terraform apply -auto-approve
```

### 5. Get Application URL

```bash
terraform output alb_url
```

## Project Structure

```
strapi-project/
├── Dockerfile                 # Docker configuration for Strapi
├── docker-compose.yml         # Local development setup
├── package.json              # Node.js dependencies
├── src/                      # Strapi application source code
├── terraform/                # Terraform infrastructure code
│   ├── main.tf              # Main infrastructure resources
│   ├── iam.tf               # IAM roles and policies
│   └── outputs.tf           # Output values
└── scripts/                  # Deployment scripts
    ├── deploy.sh            # Automated deployment script
    └── cleanup.sh           # Resource cleanup script
```

## Configuration

### Environment Variables

The application uses the following environment variables in production:

- `NODE_ENV=production`
- `HOST=0.0.0.0`
- `PORT=1337`
- `DATABASE_CLIENT=sqlite`

### Resource Specifications

- **CPU**: 256 CPU units (0.25 vCPU)
- **Memory**: 512 MB
- **Storage**: Ephemeral (container-based)
- **Database**: SQLite (for simplicity)

## Monitoring and Logs

- **CloudWatch Logs**: Application logs are automatically sent to CloudWatch
- **ECS Console**: Monitor service health and task status
- **ALB Health Checks**: Automatic health monitoring on port 1337

## Troubleshooting

### Common Issues

1. **Service fails to start**: Check CloudWatch logs for application errors
2. **Cannot access application**: Verify security group rules and ALB configuration
3. **Image push fails**: Ensure AWS credentials are configured and ECR repository exists
4. **Terraform errors**: Check AWS permissions and resource limits

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster strapi-cluster-dev --services strapi-service-dev

# View CloudWatch logs
aws logs tail /ecs/strapi-dev --follow

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Security Considerations

- Application runs in private subnets with public ALB
- Security groups restrict access to necessary ports only
- IAM roles follow principle of least privilege
- Container images are scanned by ECR

## Cost Optimization

- Uses Fargate Spot pricing when possible
- CloudWatch log retention set to 7 days
- Resources are tagged for cost tracking
- Auto-scaling can be configured based on demand

## Git Repository Management

### Repository Size Optimization

This repository has been optimized to stay under Git hosting limits (100MB) by excluding large files and directories:

**Excluded Files and Directories:**
- `terraform/.terraform/` - Terraform provider binaries (672MB+)
- `terraform/*.tfstate*` - Terraform state files (contain sensitive data)
- `data/uploads/` - User uploaded files and media
- `node_modules/` - Node.js dependencies (auto-installed)
- Build artifacts and temporary files

**Important Notes:**
- Terraform state is managed separately and should not be committed
- Upload directories are recreated automatically by Strapi
- Use `npm install` to restore node_modules after cloning
- Run `terraform init` to download providers after cloning

### Deployment Workflow

1. **Clone Repository**: `git clone <repo-url>`
2. **Install Dependencies**: `npm install`
3. **Initialize Terraform**: `cd terraform && terraform init`
4. **Deploy**: `./scripts/deploy.sh`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

**Before Committing:**
- Ensure no large files (>10MB) are added
- Run `git status` to check file sizes
- Test deployment scripts locally

## License

This project is licensed under the MIT License.
