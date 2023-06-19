# !/bin/zsh
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text | cut -f 1)
ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
IMAGE=$ECR_REPO:$TAG
docker buildx build . -t $IMAGE
docker tag $IMAGE $ECR_URL/$IMAGE
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL/$IMAGE
IMAGES_TO_DELETE=$(aws ecr list-images --region $REGION --repository-name $ECR_REPO --filter "tagStatus=UNTAGGED" --query 'imageIds[*]' --output json)
echo $IMAGES_TO_DELETE
aws ecr batch-delete-image --region $REGION --repository-name $ECR_REPO --image-ids "$IMAGES_TO_DELETE" --no-cli-pager || true
