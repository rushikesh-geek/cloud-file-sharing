# Simple deployment script
param(
    [string]$Region = "us-east-1",
    [string]$BucketName = "rushikesh-file-sharing-876715058144",
    [string]$UploadFunctionName = "rushikesh-file-upload",
    [string]$DownloadFunctionName = "rushikesh-file-download",
    [string]$TableName = "file-sharing-codes-rushikesh",
    [string]$ApiName = "rushikesh-file-sharing-api"
)

Write-Host "🚀 Starting deployment..." -ForegroundColor Green

# Create zip files
Write-Host "📦 Creating packages..." -ForegroundColor Yellow

# Upload function
$uploadDir = "upload-temp"
New-Item -ItemType Directory -Name $uploadDir -Force | Out-Null
Copy-Item "..\lambda-functions\upload_handler.py" "$uploadDir\lambda_function.py"
Compress-Archive -Path "$uploadDir\*" -DestinationPath "upload.zip" -Force
Remove-Item $uploadDir -Recurse -Force

# Download function  
$downloadDir = "download-temp"
New-Item -ItemType Directory -Name $downloadDir -Force | Out-Null
Copy-Item "..\lambda-functions\download_handler.py" "$downloadDir\lambda_function.py"
Compress-Archive -Path "$downloadDir\*" -DestinationPath "download.zip" -Force
Remove-Item $downloadDir -Recurse -Force

Write-Host "✅ Packages created" -ForegroundColor Green

# Update Lambda functions
Write-Host "⬆️ Updating Lambda functions..." -ForegroundColor Yellow

aws lambda update-function-code --function-name $UploadFunctionName --zip-file "fileb://upload.zip" --region $Region
aws lambda update-function-code --function-name $DownloadFunctionName --zip-file "fileb://download.zip" --region $Region

Write-Host "✅ Lambda functions updated" -ForegroundColor Green

# Set environment variables
Write-Host "🔧 Setting environment..." -ForegroundColor Yellow

aws lambda update-function-configuration --function-name $UploadFunctionName --environment "Variables={BUCKET_NAME=$BucketName,TABLE_NAME=$TableName}" --region $Region
aws lambda update-function-configuration --function-name $DownloadFunctionName --environment "Variables={BUCKET_NAME=$BucketName,TABLE_NAME=$TableName}" --region $Region

Write-Host "✅ Environment set" -ForegroundColor Green

# Deploy API Gateway
Write-Host "🌐 Deploying API..." -ForegroundColor Yellow

$apiId = aws apigateway get-rest-apis --query "items[?name=='$ApiName'].id" --output text --region $Region
if ($apiId) {
    aws apigateway create-deployment --rest-api-id $apiId --stage-name "prod" --region $Region
    $apiUrl = "https://$apiId.execute-api.$Region.amazonaws.com/prod"
    Write-Host "✅ API deployed: $apiUrl" -ForegroundColor Green
} else {
    Write-Host "❌ API not found" -ForegroundColor Red
}

# Clean up
Remove-Item "upload.zip" -Force -ErrorAction SilentlyContinue
Remove-Item "download.zip" -Force -ErrorAction SilentlyContinue

Write-Host "🎉 Deployment complete!" -ForegroundColor Green
Write-Host "🌐 API URL: $apiUrl" -ForegroundColor Cyan