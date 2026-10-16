#!/usr/bin/env bash
set -euo pipefail

REGION="us-east-1"

echo "============================================================"
echo "      REALWORLD MANUAL RESOURCES CLEANUP SCRIPT             "
echo "============================================================"
echo "Region: ${REGION}"
echo "SAFEGUARD: Route 53 DNS & ACM Certificate will NOT be touched."
echo "SAFEGUARD: Terraform Remote State S3 Bucket will NOT be touched."
echo "============================================================"

# 0. Check AWS Credentials
echo "--> Checking AWS STS caller identity..."
if ! aws sts get-caller-identity --output table; then
  echo "ERROR: AWS credentials are expired or invalid."
  echo "Please refresh your AWS session credentials and re-run."
  exit 1
fi

# 1. ECS (Service & Cluster)
echo "--> [1/8] Cleaning up ECS resources..."
if aws ecs describe-services --cluster realworld-cluster --services realworld-backend-service --region "${REGION}" --query "services[0].serviceName" --output text 2>/dev/null | grep -q "realworld-backend-service"; then
  echo "Scaling ECS service realworld-backend-service to 0..."
  aws ecs update-service --cluster realworld-cluster --service realworld-backend-service --desired-count 0 --region "${REGION}" >/dev/null 2>&1 || true
  echo "Deleting ECS service realworld-backend-service..."
  aws ecs delete-service --cluster realworld-cluster --service realworld-backend-service --force --region "${REGION}" >/dev/null 2>&1 || true
fi

if aws ecs describe-clusters --clusters realworld-cluster --region "${REGION}" --query "clusters[0].clusterName" --output text 2>/dev/null | grep -q "realworld-cluster"; then
  echo "Deleting ECS cluster realworld-cluster..."
  aws ecs delete-cluster --cluster realworld-cluster --region "${REGION}" >/dev/null 2>&1 || true
fi

# Clean up CloudWatch log group if exists
aws logs delete-log-group --log-group-name "/ecs/realworld-backend" --region "${REGION}" 2>/dev/null || true
echo "ECS cleanup initiated."

# 2. ALB & Target Group
echo "--> [2/8] Cleaning up ALB & Target Group..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names realworld-alb --region "${REGION}" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null || true)
if [ -n "${ALB_ARN}" ] && [ "${ALB_ARN}" != "None" ]; then
  echo "Deleting ALB: ${ALB_ARN}..."
  aws elbv2 delete-load-balancer --load-balancer-arn "${ALB_ARN}" --region "${REGION}"
  echo "Waiting for ALB deletion to complete..."
  aws elbv2 wait load-balancers-deleted --load-balancer-arns "${ALB_ARN}" --region "${REGION}" 2>/dev/null || true
fi

TG_ARN=$(aws elbv2 describe-target-groups --names realworld-backend-tg --region "${REGION}" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null || true)
if [ -n "${TG_ARN}" ] && [ "${TG_ARN}" != "None" ]; then
  echo "Deleting Target Group: ${TG_ARN}..."
  aws elbv2 delete-target-group --target-group-arn "${TG_ARN}" --region "${REGION}" 2>/dev/null || true
fi

# 3. S3 Frontend Bucket (PRESERVING TERRAFORM STATE BUCKET!)
echo "--> [3/8] Cleaning up Frontend S3 bucket..."
FRONTEND_BUCKET="salma-realworld-frontend-253650698585"
if aws s3api head-bucket --bucket "${FRONTEND_BUCKET}" 2>/dev/null; then
  echo "Emptying bucket ${FRONTEND_BUCKET}..."
  aws s3 rm "s3://${FRONTEND_BUCKET}" --recursive || true
  echo "Deleting bucket ${FRONTEND_BUCKET}..."
  aws s3api delete-bucket --bucket "${FRONTEND_BUCKET}" --region "${REGION}" || true
else
  echo "Frontend bucket ${FRONTEND_BUCKET} does not exist or already deleted."
fi

# 4. CloudFront Distribution (Disable first, then delete)
echo "--> [4/8] Disabling CloudFront distribution (E2PR72U1PW6XJD)..."
CF_ID="E2PR72U1PW6XJD"
CF_CONFIG_JSON=$(aws cloudfront get-distribution-config --id "${CF_ID}" 2>/dev/null || true)
if [ -n "${CF_CONFIG_JSON}" ]; then
  ETAG=$(echo "${CF_CONFIG_JSON}" | jq -r '.ETag')
  STATUS=$(aws cloudfront get-distribution --id "${CF_ID}" --query "Distribution.Status" --output text)
  ENABLED=$(echo "${CF_CONFIG_JSON}" | jq -r '.DistributionConfig.Enabled')

  if [ "${ENABLED}" = "true" ]; then
    echo "Distribution ${CF_ID} is currently enabled. Disabling it now..."
    NEW_CONFIG=$(echo "${CF_CONFIG_JSON}" | jq '.DistributionConfig.Enabled = false | .DistributionConfig')
    aws cloudfront update-distribution --id "${CF_ID}" --if-match "${ETAG}" --distribution-config "${NEW_CONFIG}" >/dev/null
    echo "Distribution disabled. CloudFront distributions take several minutes to deploy before final deletion."
  else
    echo "Distribution ${CF_ID} is already disabled. Checking status: ${STATUS}..."
    if [ "${STATUS}" = "Deployed" ]; then
      echo "Deleting CloudFront distribution ${CF_ID}..."
      aws cloudfront delete-distribution --id "${CF_ID}" --if-match "${ETAG}" || true
    else
      echo "CloudFront distribution is still deploying/disabling. It can be deleted once status is 'Deployed'."
    fi
  fi
fi

# 5. RDS Database Instance & Subnet Group
echo "--> [5/8] Cleaning up RDS PostgreSQL..."
if aws rds describe-db-instances --db-instance-identifier realworld-postgres --region "${REGION}" >/dev/null 2>&1; then
  echo "Deleting RDS instance realworld-postgres (skipping final snapshot)..."
  aws rds delete-db-instance --db-instance-identifier realworld-postgres --skip-final-snapshot --delete-automated-backups --region "${REGION}" >/dev/null 2>&1 || true
  echo "Waiting for RDS instance deletion (this may take 3-5 minutes)..."
  aws rds wait db-instance-deleted --db-instance-identifier realworld-postgres --region "${REGION}" 2>/dev/null || true
fi

if aws rds describe-db-subnet-groups --db-subnet-group-name realworld-db-subnet-group --region "${REGION}" >/dev/null 2>&1; then
  echo "Deleting DB Subnet Group realworld-db-subnet-group..."
  aws rds delete-db-subnet-group --db-subnet-group-name realworld-db-subnet-group --region "${REGION}" >/dev/null 2>&1 || true
fi

# 6. SSM Parameters & Secrets Manager
echo "--> [6/8] Cleaning up SSM Parameters and Secrets Manager..."
for param in "/salma-realworld/POSTGRES_HOST" "/salma-realworld/POSTGRES_PORT" "/salma-realworld/POSTGRES_DB" "/salma-realworld/POSTGRES_USER"; do
  aws ssm delete-parameter --name "${param}" --region "${REGION}" 2>/dev/null || true
done

SECRET_ARN=$(aws secretsmanager list-secrets --filters Key=name,Values=salma-realworld/db-password --region "${REGION}" --query "SecretList[0].ARN" --output text 2>/dev/null || true)
if [ -n "${SECRET_ARN}" ] && [ "${SECRET_ARN}" != "None" ]; then
  echo "Deleting Secret: ${SECRET_ARN}..."
  aws secretsmanager delete-secret --secret-id "${SECRET_ARN}" --force-delete-without-recovery --region "${REGION}" >/dev/null 2>&1 || true
fi

# 7. NAT Gateway & Elastic IP
echo "--> [7/8] Cleaning up NAT Gateway and Elastic IP..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=realworld-vpc" --region "${REGION}" --query "Vpcs[0].VpcId" --output text 2>/dev/null || true)
if [ -n "${VPC_ID}" ] && [ "${VPC_ID}" != "None" ]; then
  NAT_GW_ID=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${VPC_ID}" "Name=state,Values=available,pending" --region "${REGION}" --query "NatGateways[0].NatGatewayId" --output text 2>/dev/null || true)
  if [ -n "${NAT_GW_ID}" ] && [ "${NAT_GW_ID}" != "None" ]; then
    EIP_ALLOC=$(aws ec2 describe-nat-gateways --nat-gateway-ids "${NAT_GW_ID}" --region "${REGION}" --query "NatGateways[0].NatGatewayAddresses[0].AllocationId" --output text 2>/dev/null || true)
    echo "Deleting NAT Gateway: ${NAT_GW_ID}..."
    aws ec2 delete-nat-gateway --nat-gateway-id "${NAT_GW_ID}" --region "${REGION}" >/dev/null
    echo "Waiting for NAT Gateway to delete..."
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "${NAT_GW_ID}" --region "${REGION}" 2>/dev/null || true

    if [ -n "${EIP_ALLOC}" ] && [ "${EIP_ALLOC}" != "None" ]; then
      echo "Releasing Elastic IP: ${EIP_ALLOC}..."
      aws ec2 release-address --allocation-id "${EIP_ALLOC}" --region "${REGION}" 2>/dev/null || true
    fi
  fi
fi

# 8. VPC, Subnets, Route Tables, Internet Gateway, Security Groups
echo "--> [8/8] Cleaning up VPC networking (${VPC_ID})..."
if [ -n "${VPC_ID}" ] && [ "${VPC_ID}" != "None" ]; then
  # Security groups in VPC (except default)
  for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=${VPC_ID}" --region "${REGION}" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text 2>/dev/null || true); do
    echo "Deleting Security Group: ${sg}..."
    aws ec2 delete-security-group --group-id "${sg}" --region "${REGION}" 2>/dev/null || true
  done

  # Detach and delete Internet Gateway
  IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=${VPC_ID}" --region "${REGION}" --query "InternetGateways[0].InternetGatewayId" --output text 2>/dev/null || true)
  if [ -n "${IGW_ID}" ] && [ "${IGW_ID}" != "None" ]; then
    echo "Detaching IGW: ${IGW_ID}..."
    aws ec2 detach-internet-gateway --internet-gateway-id "${IGW_ID}" --vpc-id "${VPC_ID}" --region "${REGION}" 2>/dev/null || true
    echo "Deleting IGW: ${IGW_ID}..."
    aws ec2 delete-internet-gateway --internet-gateway-id "${IGW_ID}" --region "${REGION}" 2>/dev/null || true
  fi

  # Delete Subnets
  for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --region "${REGION}" --query "Subnets[*].SubnetId" --output text 2>/dev/null || true); do
    echo "Deleting Subnet: ${subnet}..."
    aws ec2 delete-subnet --subnet-id "${subnet}" --region "${REGION}" 2>/dev/null || true
  done

  # Delete Custom Route Tables (exclude main route table)
  for rtb in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${VPC_ID}" --region "${REGION}" --query "RouteTables[?Associations[0].Main!=true].RouteTableId" --output text 2>/dev/null || true); do
    echo "Deleting Route Table: ${rtb}..."
    aws ec2 delete-route-table --route-table-id "${rtb}" --region "${REGION}" 2>/dev/null || true
  done

  # Delete VPC
  echo "Deleting VPC: ${VPC_ID}..."
  aws ec2 delete-vpc --vpc-id "${VPC_ID}" --region "${REGION}" 2>/dev/null || true
fi

echo "============================================================"
echo "Cleanup completed successfully!"
echo "Route 53 DNS zone 'app.salmah.pp.ua' and ACM certificate remain preserved."
echo "============================================================"
