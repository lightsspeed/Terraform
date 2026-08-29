# 1. Define your variables (Bucket name must be globally unique)
BUCKET_NAME="my-automated-tf-state-bucket-$(date +%s)"
REGION="us-east-1"

# 2. Create the S3 bucket
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION"

# 3. Enable Object Versioning (Crucial for state history backups)
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# 4. Turn on Default AES-256 Encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]} '

# 5. Block all Public Access (Security best practice)
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "✅ Success! S3 Bucket Created: $BUCKET_NAME"
