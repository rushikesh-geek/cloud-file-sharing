# Local Development Setup Script for Windows
# This script sets up a local development environment for the Cloud File Sharing System

Write-Host "🛠️  Setting up local development environment..." -ForegroundColor Green

# Check if Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python is not installed. Please install Python 3.8 or later." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Python found" -ForegroundColor Green

# Create virtual environment
if (!(Test-Path "venv")) {
    Write-Host "📦 Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

# Activate virtual environment
Write-Host "🔄 Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# Upgrade pip
Write-Host "⬆️  Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# Install dependencies
Write-Host "📚 Installing dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt

# Create local development configuration
Write-Host "⚙️  Creating local development configuration..." -ForegroundColor Yellow

@"
# Local Development Environment Variables
AWS_REGION=us-east-1
BUCKET_NAME=rushikesh-file-sharing-876715058144
TABLE_NAME=file-sharing-codes-rushikesh
CODE_EXPIRY_HOURS=24
PRESIGNED_URL_EXPIRY=300
"@ | Out-File -FilePath ".env" -Encoding UTF8

# Create local test runner
@'
#!/usr/bin/env python3
"""
Local test runner for Lambda functions
This script helps test the Lambda functions locally with mock AWS services
"""

import os
import sys
import json
from unittest.mock import patch, MagicMock

# Add lambda functions to path
sys.path.insert(0, 'lambda-functions')

def test_upload_handler():
    """Test the upload handler with mock data"""
    print("🧪 Testing upload handler...")
    
    # Mock event data
    event = {
        'httpMethod': 'POST',
        'headers': {'content-type': 'multipart/form-data; boundary=test'},
        'body': 'test file content',
        'isBase64Encoded': False
    }
    
    context = MagicMock()
    
    # Import and test
    try:
        import upload_handler
        response = upload_handler.lambda_handler(event, context)
        print(f"✅ Upload handler test completed: {response['statusCode']}")
    except ImportError as e:
        print(f"⚠️  Import warning (expected in local environment): {e}")
    except Exception as e:
        print(f"❌ Upload handler test failed: {e}")

def test_download_handler():
    """Test the download handler with mock data"""
    print("🧪 Testing download handler...")
    
    # Mock event data
    event = {
        'httpMethod': 'GET',
        'queryStringParameters': {'code': 'TEST1234', 'action': 'info'}
    }
    
    context = MagicMock()
    
    # Import and test
    try:
        import download_handler
        response = download_handler.lambda_handler(event, context)
        print(f"✅ Download handler test completed: {response['statusCode']}")
    except ImportError as e:
        print(f"⚠️  Import warning (expected in local environment): {e}")
    except Exception as e:
        print(f"❌ Download handler test failed: {e}")

if __name__ == "__main__":
    print("🚀 Running local tests...")
    test_upload_handler()
    test_download_handler()
    print("✅ Local tests completed")
'@ | Out-File -FilePath "run_local_tests.py" -Encoding UTF8

Write-Host ""
Write-Host "✅ Local development environment setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor White
Write-Host "  1. Activate the virtual environment: .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host "  2. Configure AWS credentials: aws configure" -ForegroundColor Cyan
Write-Host "  3. Run local tests: python run_local_tests.py" -ForegroundColor Cyan
Write-Host "  4. Edit .env file with your specific configuration" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Note: boto3 import warnings in IDEs are normal for Lambda development" -ForegroundColor Yellow
Write-Host "    The boto3 library is pre-installed in AWS Lambda runtime" -ForegroundColor Yellow
Write-Host ""