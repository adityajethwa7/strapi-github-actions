# Strapi AWS ECS Fargate Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying a Strapi application on AWS using ECS Fargate with Terraform infrastructure as code.

## Pre-Deployment Checklist

### Prerequisites
- [ ] AWS CLI installed and configured
- [ ] Docker installed and running
- [ ] Terraform installed (version 1.0+)
- [ ] Git repository cloned locally
- [ ] AWS account with appropriate permissions

### AWS Permissions Required
Your AWS user/role needs the following permissions:
- [ ] ECR (Elastic Container Registry) - Full access
- [ ] ECS (Elastic Container Service) - Full access
- [ ] EC2 - VPC, Security Groups, Load Balancer management
- [ ] IAM - Role and policy management
- [ ] CloudWatch - Log group management

### AWS Configuration
```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

## Deployment Options

### Option 1: Automated Deployment (Recommended)

1. **Navigate to project directory:**
   ```bash
   cd strapi-project
   ```

2. **Run the deployment script:**
   ```bash
   ./scripts/deploy.sh
   ```

3. **Wait for completion** (typically 5-10 minutes)

4. **Access your application** using the provided ALB URL

### Option 2: Manual Deployment

1. **Initialize Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform workspace new dev
   ```

2. **Create ECR repository:**
   ```bash
   terraform apply -target=aws_ecr_repository.strapi -auto-approve
   ECR_URL=$(terraform output -raw ecr_repository_url)
   ```

3. **Build and push Docker image:**
   ```bash
   cd ..
   docker build -t strapi-app:latest .
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
   docker tag strapi-app:latest $ECR_URL:latest
   docker push $ECR_URL:latest
   ```

4. **Deploy infrastructure:**
   ```bash
   cd terraform
   terraform plan
   terraform apply -auto-approve
   ```

5. **Get application URL:**
   ```bash
   terraform output alb_url
   ```

## Testing

### Local Testing
Before deploying to AWS, test the application locally:

```bash
./scripts/test-local.sh
```

This will:
- Build the Docker image
- Run the container locally
- Test the endpoints
- Provide connection information

### Post-Deployment Testing
After deployment, verify the application:

1. **Check service health:**
   ```bash
   aws ecs describe-services --cluster strapi-cluster-dev --services strapi-service-dev
   ```

2. **View application logs:**
   ```bash
   aws logs tail /ecs/strapi-dev --follow
   ```

3. **Test endpoints:**
   ```bash
   curl -I http://your-alb-url.us-east-1.elb.amazonaws.com
   ```

## Monitoring and Maintenance

### CloudWatch Logs
- Log Group: `/ecs/strapi-dev`
- Retention: 7 days
- Access via AWS Console or CLI

### ECS Service Monitoring
- Service: `strapi-service-dev`
- Cluster: `strapi-cluster-dev`
- Desired Count: 1
- Health Check: HTTP on port 1337

### Application Load Balancer
- Health Check Path: `/`
- Health Check Port: 1337
- Healthy Threshold: 2
- Unhealthy Threshold: 5

## Scaling and Updates

### Updating the Application
1. Make code changes
2. Run deployment script: `./scripts/deploy.sh`
3. The script will build and push a new image
4. ECS will automatically deploy the new version

### Scaling the Service
```bash
aws ecs update-service \
  --cluster strapi-cluster-dev \
  --service strapi-service-dev \
  --desired-count 2
```

### Resource Scaling
Modify `terraform/main.tf`:
- CPU: Change `cpu = 256` (256 = 0.25 vCPU)
- Memory: Change `memory = 512` (in MB)

## Troubleshooting

### Common Issues

1. **Service fails to start**
   - Check CloudWatch logs for errors
   - Verify Docker image builds locally
   - Check environment variables

2. **Cannot access application**
   - Verify security group rules
   - Check ALB target group health
   - Ensure service is running

3. **Image push fails**
   - Verify AWS credentials
   - Check ECR repository exists
   - Ensure Docker is logged into ECR

4. **Terraform errors**
   - Check AWS permissions
   - Verify resource limits
   - Review Terraform state

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster strapi-cluster-dev --services strapi-service-dev

# View recent logs
aws logs tail /ecs/strapi-dev --since 1h

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn $(cd terraform && terraform output -raw target_group_arn)

# Force new deployment
aws ecs update-service --cluster strapi-cluster-dev --service strapi-service-dev --force-new-deployment
```

## Cleanup

### Automated Cleanup
```bash
./scripts/cleanup.sh
```

### Manual Cleanup
```bash
cd terraform
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete dev
```

## Cost Considerations

### Estimated Monthly Costs (us-east-1)
- **ECS Fargate**: ~$15-20/month (0.25 vCPU, 512MB RAM, 24/7)
- **Application Load Balancer**: ~$16/month
- **ECR Storage**: ~$1/month (for images)
- **CloudWatch Logs**: ~$1/month (7-day retention)
- **Data Transfer**: Variable based on usage

**Total Estimated Cost**: ~$33-38/month

### Cost Optimization Tips
- Use Fargate Spot for non-production environments
- Implement auto-scaling based on demand
- Set up CloudWatch alarms for cost monitoring
- Use lifecycle policies for ECR images

## Security Best Practices

- [ ] Use least privilege IAM roles
- [ ] Enable VPC Flow Logs
- [ ] Implement WAF for ALB (optional)
- [ ] Use HTTPS with SSL certificates (recommended)
- [ ] Enable ECR image scanning
- [ ] Regularly update base images
- [ ] Monitor CloudTrail logs

## Next Steps

1. **Set up HTTPS**: Add SSL certificate to ALB
2. **Configure Domain**: Point custom domain to ALB
3. **Set up CI/CD**: Automate deployments with GitHub Actions
4. **Add Database**: Replace SQLite with RDS for production
5. **Implement Monitoring**: Set up CloudWatch alarms
6. **Add Backup**: Configure automated backups

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS documentation
3. Check Strapi documentation
4. Review CloudWatch logs
5. Contact your DevOps team
