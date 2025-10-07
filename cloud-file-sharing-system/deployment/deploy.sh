#!/bin/bash

# Cloud File Sharing System - Deployment Script
# This script configures your existing AWS resources for the file sharing system

set -e

# Configuration Variables
AWS_REGION="us-east-1"
BUCKET_NAME="rushikesh-file-sharing-876715058144"
UPLOAD_FUNCTION_NAME="rushikesh-file-upload"
DOWNLOAD_FUNCTION_NAME="rushikesh-file-download"
TABLE_NAME="file-sharing-codes-rushikesh"
API_NAME="rushikesh-file-sharing-api"

echo "🚀 Starting Cloud File Sharing System Deployment..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
echo "📋 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS credentials verified"

# Function to create a zip file for Lambda deployment
create_lambda_zip() {
    local function_name=$1
    local source_file=$2
    
    echo "📦 Creating deployment package for $function_name..."
    
    # Create temporary directory
    temp_dir=$(mktemp -d)
    
    # Copy the Lambda function code
    cp "$source_file" "$temp_dir/lambda_function.py"
    
    # Create zip file
    cd "$temp_dir"
    zip -r "../${function_name}.zip" .
    cd - > /dev/null
    
    # Move zip to deployment directory
    mv "$temp_dir/../${function_name}.zip" "./deployment/"
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✅ Created deployment package: ./deployment/${function_name}.zip"
}

# Create deployment packages
echo "📦 Creating Lambda deployment packages..."
create_lambda_zip "$UPLOAD_FUNCTION_NAME" "./lambda-functions/upload_handler.py"
create_lambda_zip "$DOWNLOAD_FUNCTION_NAME" "./lambda-functions/download_handler.py"

# Update Lambda function code
echo "⬆️  Updating Lambda functions..."

echo "  Updating upload function..."
aws lambda update-function-code \
    --function-name "$UPLOAD_FUNCTION_NAME" \
    --zip-file "fileb://./deployment/${UPLOAD_FUNCTION_NAME}.zip" \
    --region "$AWS_REGION"

echo "  Updating download function..."
aws lambda update-function-code \
    --function-name "$DOWNLOAD_FUNCTION_NAME" \
    --zip-file "fileb://./deployment/${DOWNLOAD_FUNCTION_NAME}.zip" \
    --region "$AWS_REGION"

# Update Lambda environment variables
echo "🔧 Configuring Lambda environment variables..."

echo "  Setting environment variables for upload function..."
aws lambda update-function-configuration \
    --function-name "$UPLOAD_FUNCTION_NAME" \
    --environment Variables="{BUCKET_NAME=$BUCKET_NAME,TABLE_NAME=$TABLE_NAME,CODE_EXPIRY_HOURS=24}" \
    --region "$AWS_REGION"

echo "  Setting environment variables for download function..."
aws lambda update-function-configuration \
    --function-name "$DOWNLOAD_FUNCTION_NAME" \
    --environment Variables="{BUCKET_NAME=$BUCKET_NAME,TABLE_NAME=$TABLE_NAME,PRESIGNED_URL_EXPIRY=300}" \
    --region "$AWS_REGION"

# Get API Gateway ID
echo "🔍 Finding API Gateway..."
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$API_NAME'].id" --output text --region "$AWS_REGION")

if [ -z "$API_ID" ] || [ "$API_ID" == "None" ]; then
    echo "❌ API Gateway '$API_NAME' not found"
    exit 1
fi

echo "✅ Found API Gateway: $API_ID"

# Deploy API Gateway
echo "🚀 Deploying API Gateway..."
aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name "prod" \
    --region "$AWS_REGION"

echo "✅ API Gateway deployed"

# Get API Gateway URL
API_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/prod"
echo "🌐 API Gateway URL: $API_URL"

# Update frontend configuration
echo "🔧 Updating frontend configuration..."
FRONTEND_CONFIG="./frontend/config.js"

cat > "$FRONTEND_CONFIG" << EOF
// Auto-generated configuration file
const CONFIG = {
    API_BASE_URL: '$API_URL',
    UPLOAD_ENDPOINT: '$API_URL/upload',
    DOWNLOAD_ENDPOINT: '$API_URL/download',
    AWS_REGION: '$AWS_REGION'
};

// Update the API URLs in script.js
if (typeof window !== 'undefined') {
    window.API_BASE_URL = CONFIG.API_BASE_URL;
    window.UPLOAD_ENDPOINT = CONFIG.UPLOAD_ENDPOINT;
    window.DOWNLOAD_ENDPOINT = CONFIG.DOWNLOAD_ENDPOINT;
}
EOF

# Update script.js with actual API URLs
echo "📝 Updating script.js with API URLs..."
sed -i.bak "s|const API_BASE_URL = '.*';|const API_BASE_URL = '$API_URL';|g" ./frontend/script.js
sed -i.bak "s|https://YOUR_API_GATEWAY_URL.execute-api.YOUR_REGION.amazonaws.com/YOUR_STAGE|$API_URL|g" ./frontend/script.js

echo "✅ Frontend configuration updated"

# Test the API endpoints
echo "🧪 Testing API endpoints..."

echo "  Testing upload endpoint..."
UPLOAD_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$API_URL/upload")
if [ "$UPLOAD_TEST" == "200" ]; then
    echo "  ✅ Upload endpoint responding"
else
    echo "  ⚠️  Upload endpoint test failed (HTTP $UPLOAD_TEST)"
fi

echo "  Testing download endpoint..."
DOWNLOAD_TEST=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$API_URL/download")
if [ "$DOWNLOAD_TEST" == "200" ]; then
    echo "  ✅ Download endpoint responding"
else
    echo "  ⚠️  Download endpoint test failed (HTTP $DOWNLOAD_TEST)"
fi

# Clean up deployment files
echo "🧹 Cleaning up..."
rm -f "./deployment/${UPLOAD_FUNCTION_NAME}.zip"
rm -f "./deployment/${DOWNLOAD_FUNCTION_NAME}.zip"
rm -f "./frontend/script.js.bak"

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📋 Summary:"
echo "  • S3 Bucket: $BUCKET_NAME"
echo "  • DynamoDB Table: $TABLE_NAME"
echo "  • Upload Function: $UPLOAD_FUNCTION_NAME"
echo "  • Download Function: $DOWNLOAD_FUNCTION_NAME"
echo "  • API Gateway: $API_URL"
echo ""
echo "🌐 Frontend URLs:"
echo "  • Open ./frontend/index.html in your browser"
echo "  • Or serve from a web server for full functionality"
echo ""
echo "📚 Next Steps:"
echo "  1. Open ./frontend/index.html in your browser"
echo "  2. Test file upload and download functionality"
echo "  3. Check the README.md for additional configuration options"
echo ""