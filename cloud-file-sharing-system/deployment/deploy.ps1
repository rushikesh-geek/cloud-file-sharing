# Cloud File Sharing System - PowerShell Deployment Script
# This script configures your existing AWS resources for the file sharing system

param(
    [string]$Region = "us-east-1",
    [string]$BucketName = "rushikesh-file-sharing-876715058144",
    [string]$UploadFunctionName = "rushikesh-file-upload",
    [string]$DownloadFunctionName = "rushikesh-file-download",
    [string]$TableName = "file-sharing-codes-rushikesh",
    [string]$ApiName = "rushikesh-file-sharing-api"
)

Write-Host "🚀 Starting Cloud File Sharing System Deployment..." -ForegroundColor Green

# Set AWS credentials for Academy Learner Lab
Write-Host "🔑 Setting up AWS Academy credentials..." -ForegroundColor Yellow
$env:AWS_ACCESS_KEY_ID = "ASIA4YICKEPQNEISFOIR"
$env:AWS_SECRET_ACCESS_KEY = "VBFoU8HlgWk8SVxWuZj4Tb6G0drSe4R3a7FzbYZY"
$env:AWS_SESSION_TOKEN = "IQoJb3JpZ2luX2VjEMT//////////wEaCXVzLXdlc3QtMiJHMEUCIQDJijHnIAKP9KvU281NrmpS+GWHwmhLgMT2BvifoAv7GwIgGRvSC9ic1tox0UMrsYtje5ZfuEOCUPs82g/lNtnl2d8qrAIIXRAAGgw4NzY3MTUwNTgxNDQiDIt2BLINNe3eHYF+YSqJAgT/DCoEX0qL/XMHfT7Io3s54tOYBqGGN+KUtzHLsYBBkerTWLRDTp9oYpy4OkaLy/b4ZjOXRu3PpJxHXkkZRMp0gRRCQhMnIWCY+T4jtg8XLoKqwAsnKsYRC9eX4RM/06Ys5as46/LzV/4JuDWEh59C2CsAlV6KAR8F0bYjhMHEVuSvlxhOuf4gjfcqTtFdzZO3LUCQHmZMTAHG2qiwAUH05iG/uTJrcYhWdffXuroDlq25Eay3c+68SkN+GKT3VWfKawYcxLjErSVpvBO3EbqRRPqziYRnSvbnQ0xndFfmv6kXanuy0vYVLojKcipLxlUM8B4/oL72gf9tyWQ64UePFd7a0FY3iqkws5uExwY6nQFP58aQKaxz+QZYSXq27xZsANwuT7peyinC34myTFkYZSY8kkFbVnPpOoOX5vsMGdbuaKaG7rPFh6BXmYkez2ZgbsLvtTystEHJOdavQ0s1J0zGLmGLr/tIlgNwyot3+Z/j3jsTkDWRhhYlOWfRsf219KTRleEzl5CTB5bJdsvwKgM8KMuqNsHCD5q1v7ml33fSdnZGLu0gak/uBNqr"
$env:AWS_DEFAULT_REGION = $Region

# Check if AWS CLI is installed
if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
Write-Host "📋 Checking AWS credentials..." -ForegroundColor Yellow
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS credentials verified" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured properly." -ForegroundColor Red
    exit 1
}

# Function to create a zip file for Lambda deployment
function New-LambdaZip {
    param(
        [string]$FunctionName,
        [string]$SourceFile
    )
    
    Write-Host "📦 Creating deployment package for $FunctionName..." -ForegroundColor Yellow
    
    # Create temporary directory
    $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; mkdir $_ }
    
    # Copy the Lambda function code and rename it
    Copy-Item $SourceFile "$tempDir\lambda_function.py"
    
    # Create zip file
    $zipPath = ".\deployment\$FunctionName.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    
    Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
    
    # Cleanup
    Remove-Item $tempDir -Recurse -Force
    
    Write-Host "✅ Created deployment package: $zipPath" -ForegroundColor Green
    return $zipPath
}

# Create deployment packages
Write-Host "📦 Creating Lambda deployment packages..." -ForegroundColor Yellow
$uploadZip = New-LambdaZip -FunctionName $UploadFunctionName -SourceFile ".\lambda-functions\upload_handler.py"
$downloadZip = New-LambdaZip -FunctionName $DownloadFunctionName -SourceFile ".\lambda-functions\download_handler.py"

# Update Lambda function code
Write-Host "⬆️  Updating Lambda functions..." -ForegroundColor Yellow

Write-Host "  Updating upload function..." -ForegroundColor Cyan
aws lambda update-function-code --function-name $UploadFunctionName --zip-file "fileb://$uploadZip" --region $Region

Write-Host "  Updating download function..." -ForegroundColor Cyan
aws lambda update-function-code --function-name $DownloadFunctionName --zip-file "fileb://$downloadZip" --region $Region

# Update Lambda environment variables
Write-Host "🔧 Configuring Lambda environment variables..." -ForegroundColor Yellow

Write-Host "  Setting environment variables for upload function..." -ForegroundColor Cyan
aws lambda update-function-configuration --function-name $UploadFunctionName --environment "Variables={BUCKET_NAME=$BucketName,TABLE_NAME=$TableName,CODE_EXPIRY_HOURS=24}" --region $Region

Write-Host "  Setting environment variables for download function..." -ForegroundColor Cyan
aws lambda update-function-configuration --function-name $DownloadFunctionName --environment "Variables={BUCKET_NAME=$BucketName,TABLE_NAME=$TableName,PRESIGNED_URL_EXPIRY=300}" --region $Region

# Get API Gateway ID
Write-Host "🔍 Finding API Gateway..." -ForegroundColor Yellow
$apiId = aws apigateway get-rest-apis --query "items[?name=='$ApiName'].id" --output text --region $Region

if ([string]::IsNullOrEmpty($apiId) -or $apiId -eq "None") {
    Write-Host "❌ API Gateway '$ApiName' not found" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found API Gateway: $apiId" -ForegroundColor Green

# Deploy API Gateway
Write-Host "🚀 Deploying API Gateway..." -ForegroundColor Yellow
aws apigateway create-deployment --rest-api-id $apiId --stage-name "prod" --region $Region

Write-Host "✅ API Gateway deployed" -ForegroundColor Green

# Get API Gateway URL
$apiUrl = "https://$apiId.execute-api.$Region.amazonaws.com/prod"
Write-Host "🌐 API Gateway URL: $apiUrl" -ForegroundColor Green

# Update frontend configuration
Write-Host "🔧 Updating frontend configuration..." -ForegroundColor Yellow
$frontendConfig = ".\frontend\config.js"

@"
// Auto-generated configuration file
const CONFIG = {
    API_BASE_URL: '$apiUrl',
    UPLOAD_ENDPOINT: '$apiUrl/upload',
    DOWNLOAD_ENDPOINT: '$apiUrl/download',
    AWS_REGION: '$Region'
};

// Update the API URLs in script.js
if (typeof window !== 'undefined') {
    window.API_BASE_URL = CONFIG.API_BASE_URL;
    window.UPLOAD_ENDPOINT = CONFIG.UPLOAD_ENDPOINT;
    window.DOWNLOAD_ENDPOINT = CONFIG.DOWNLOAD_ENDPOINT;
}
"@ | Out-File -FilePath $frontendConfig -Encoding UTF8

# Update script.js with actual API URLs
Write-Host "📝 Updating script.js with API URLs..." -ForegroundColor Yellow
$scriptJsPath = ".\frontend\script.js"
$scriptContent = Get-Content $scriptJsPath -Raw

# Replace the placeholder URLs with actual API URLs
$pattern1 = "const API_BASE_URL = '.*'"
$replacement1 = "const API_BASE_URL = '$apiUrl'"
$scriptContent = $scriptContent -replace $pattern1, $replacement1
$scriptContent = $scriptContent -replace "https://YOUR_API_GATEWAY_URL\.execute-api\.YOUR_REGION\.amazonaws\.com/YOUR_STAGE", $apiUrl

Set-Content -Path $scriptJsPath -Value $scriptContent -Encoding UTF8

Write-Host "✅ Frontend configuration updated" -ForegroundColor Green

# Test the API endpoints
Write-Host "🧪 Testing API endpoints..." -ForegroundColor Yellow

Write-Host "  Testing upload endpoint..." -ForegroundColor Cyan
try {
    $uploadTest = Invoke-WebRequest -Uri "$apiUrl/upload" -Method OPTIONS -UseBasicParsing -ErrorAction SilentlyContinue
    if ($uploadTest.StatusCode -eq 200) {
        Write-Host "  ✅ Upload endpoint responding" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Upload endpoint test failed (HTTP $($uploadTest.StatusCode))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Upload endpoint test failed" -ForegroundColor Yellow
}

Write-Host "  Testing download endpoint..." -ForegroundColor Cyan
try {
    $downloadTest = Invoke-WebRequest -Uri "$apiUrl/download" -Method OPTIONS -UseBasicParsing -ErrorAction SilentlyContinue
    if ($downloadTest.StatusCode -eq 200) {
        Write-Host "  ✅ Download endpoint responding" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Download endpoint test failed (HTTP $($downloadTest.StatusCode))" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Download endpoint test failed" -ForegroundColor Yellow
}

# Clean up deployment files
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
Remove-Item $uploadZip -Force -ErrorAction SilentlyContinue
Remove-Item $downloadZip -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor White
Write-Host "  • S3 Bucket: $BucketName" -ForegroundColor Cyan
Write-Host "  • DynamoDB Table: $TableName" -ForegroundColor Cyan
Write-Host "  • Upload Function: $UploadFunctionName" -ForegroundColor Cyan
Write-Host "  • Download Function: $DownloadFunctionName" -ForegroundColor Cyan
Write-Host "  • API Gateway: $apiUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Frontend URLs:" -ForegroundColor White
Write-Host "  • Open .\frontend\index.html in your browser" -ForegroundColor Cyan
Write-Host "  • Or serve from a web server for full functionality" -ForegroundColor Cyan
Write-Host ""
Write-Host "📚 Next Steps:" -ForegroundColor White
Write-Host "  1. Open .\frontend\index.html in your browser" -ForegroundColor Cyan
Write-Host "  2. Test file upload and download functionality" -ForegroundColor Cyan
Write-Host "  3. Check the README.md for additional configuration options" -ForegroundColor Cyan
Write-Host ""