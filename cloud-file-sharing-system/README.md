# Cloud-Based Secure File Sharing System

A serverless file sharing system built with AWS Lambda, S3, DynamoDB, and API Gateway. Share files securely using unique codes with automatic expiration.

## 🌟 Features

- **Secure File Upload**: Upload files up to 50MB with unique 8-character codes
- **Temporary Access**: Files automatically expire after 24 hours (configurable)
- **Download Tracking**: Track download attempts with configurable limits
- **Multiple File Types**: Support for documents, images, videos, and archives
- **CORS Enabled**: Works from any web application
- **Serverless Architecture**: Cost-effective and scalable
- **Modern Web Interface**: Responsive design with drag-and-drop functionality

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │────│ API Gateway │────│   Lambda    │
│ (HTML/JS)   │    │             │    │ Functions   │
└─────────────┘    └─────────────┘    └─────────────┘
                                             │
                    ┌─────────────┐    ┌─────────────┐
                    │  DynamoDB   │    │     S3      │
                    │   (Codes)   │    │   (Files)   │
                    └─────────────┘    └─────────────┘
```

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- PowerShell (Windows) or Bash (Linux/Mac)
- Python 3.8+ (for local development)
- Web browser for testing

## ⚠️ Important Notes

### boto3 Import Warnings
If you see import warnings for `boto3` in your IDE, this is normal and expected:
- The `boto3` library is pre-installed in AWS Lambda Python runtime
- These warnings appear only in local development environments
- The code will work correctly when deployed to AWS Lambda
- For local testing, run `pip install -r requirements.txt`

## 🚀 Quick Start

### 1. Clone or Download the Project
```bash
# If using git
git clone <repository-url>
cd cloud-file-sharing-system

# Or download and extract the ZIP file
```

### 2. Set Up Local Development (Optional)
```bash
# Windows
.\setup-dev.ps1

# Linux/Mac
chmod +x setup-dev.sh
./setup-dev.sh
```

### 3. Configure AWS Credentials
```bash
# Configure AWS CLI with your credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_SESSION_TOKEN=your_session_token  # if using temporary credentials
```

### 4. Deploy the System

#### Option A: Using PowerShell (Windows)
```powershell
# Navigate to the deployment directory
cd deployment

# Run the deployment script
.\deploy.ps1
```

#### Option B: Using Bash (Linux/Mac)
```bash
# Navigate to the deployment directory
cd deployment

# Make the script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

### 5. Test the Application
1. Open `frontend/index.html` in your web browser
2. Upload a test file
3. Copy the generated code
4. Switch to the download tab and test the code

## 📁 Project Structure

```
cloud-file-sharing-system/
├── lambda-functions/
│   ├── upload_handler.py      # File upload Lambda function
│   └── download_handler.py    # File download Lambda function
├── frontend/
│   ├── index.html            # Main web interface
│   ├── style.css             # Styling
│   ├── script.js             # JavaScript functionality
│   └── config.js             # API configuration (auto-generated)
├── deployment/
│   ├── deploy.ps1            # PowerShell deployment script
│   ├── deploy.sh             # Bash deployment script
│   └── cloudformation-template.json  # Infrastructure as Code
└── README.md                 # This file
```

## 🔧 Configuration

### Environment Variables

The Lambda functions use the following environment variables:

**Upload Function:**
- `BUCKET_NAME`: S3 bucket name for file storage
- `TABLE_NAME`: DynamoDB table name for code storage
- `CODE_EXPIRY_HOURS`: Hours until codes expire (default: 24)

**Download Function:**
- `BUCKET_NAME`: S3 bucket name for file storage
- `TABLE_NAME`: DynamoDB table name for code storage
- `PRESIGNED_URL_EXPIRY`: Seconds for download URL expiry (default: 300)

### File Restrictions

- **Maximum file size**: 50MB
- **Supported file types**: 
  - Documents: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT
  - Images: JPG, JPEG, PNG, GIF, BMP, SVG
  - Videos: MP4, AVI, MOV, WMV
  - Audio: MP3, WAV, FLAC
  - Archives: ZIP, RAR, 7Z, TAR, GZ

### Security Settings

- **Code expiration**: 24 hours (configurable)
- **Download limit**: 10 downloads per code (configurable)
- **File cleanup**: Automatic deletion after 7 days
- **CORS**: Enabled for web browser access

## 📚 API Documentation

### Upload Endpoint

**POST** `/upload`

Uploads a file and returns a unique sharing code.

**Request:**
- Content-Type: `multipart/form-data`
- Body: File data

**Response:**
```json
{
  "message": "File uploaded successfully",
  "code": "ABC12345",
  "filename": "example.pdf",
  "file_size": 1048576,
  "expiry_time": "2025-10-04T12:00:00Z",
  "expires_in_hours": 24
}
```

### Download Endpoint

**GET** `/download?code={CODE}&action={ACTION}`

Retrieves file information or download URL.

**Parameters:**
- `code`: The unique sharing code
- `action`: Either `info` (get file info) or `download` (get download URL)

**Response for action=info:**
```json
{
  "message": "File information retrieved",
  "file_info": {
    "filename": "example.pdf",
    "file_size": 1048576,
    "content_type": "application/pdf",
    "upload_time": "2025-10-03T12:00:00Z",
    "download_count": 0,
    "max_downloads": 10,
    "expires_at": "2025-10-04T12:00:00Z"
  }
}
```

**Response for action=download:**
```json
{
  "message": "Download link generated",
  "download_url": "https://s3.amazonaws.com/...",
  "filename": "example.pdf",
  "file_size": 1048576,
  "content_type": "application/pdf",
  "expires_in_seconds": 300
}
```

## 🛠️ Advanced Configuration

### Custom Domain Setup

1. **Register a domain** in Route 53
2. **Create SSL certificate** in ACM
3. **Configure custom domain** in API Gateway
4. **Update frontend** configuration with new domain

### CloudWatch Monitoring

The system automatically logs to CloudWatch. Key metrics to monitor:
- Lambda function duration and errors
- API Gateway request count and latency
- DynamoDB read/write capacity
- S3 storage usage

### Cost Optimization

- **S3 Lifecycle policies**: Automatically delete files after 7 days
- **DynamoDB TTL**: Automatic cleanup of expired codes
- **Lambda provisioned concurrency**: Only if high traffic expected
- **API Gateway caching**: Enable for better performance

## 🔒 Security Best Practices

### Access Control
- Use IAM roles with least privilege
- Enable CloudTrail for audit logging
- Set up AWS Config for compliance

### Data Protection
- Enable S3 encryption at rest
- Use HTTPS only (enforced by API Gateway)
- Regular security assessments

### Monitoring
- Set up CloudWatch alarms for unusual activity
- Monitor failed authentication attempts
- Track file access patterns

## 🐛 Troubleshooting

### Common Issues

**1. "Access Denied" errors**
- Check IAM permissions for Lambda execution role
- Verify S3 bucket policies
- Ensure DynamoDB permissions are correct

**2. "File not found" errors**
- Check if the code has expired
- Verify DynamoDB table exists and is accessible
- Check S3 bucket name in environment variables

**3. CORS errors in browser**
- Verify API Gateway CORS configuration
- Check if origin is allowed
- Ensure preflight OPTIONS requests are handled

**4. Upload failures**
- Check file size limits
- Verify supported file types
- Check Lambda timeout settings

### Debugging

**Enable detailed logging:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Check CloudWatch logs:**
1. Go to CloudWatch console
2. Navigate to Logs > Log groups
3. Find your Lambda function log groups
4. Review recent log streams

**Test API endpoints directly:**
```bash
# Test upload endpoint
curl -X OPTIONS https://your-api-url.com/upload

# Test download endpoint
curl -X GET "https://your-api-url.com/download?code=TEST1234&action=info"
```

## 📊 Monitoring and Analytics

### Key Metrics to Track

1. **Upload Success Rate**: Percentage of successful uploads
2. **Download Success Rate**: Percentage of successful downloads
3. **Average File Size**: Monitor storage usage
4. **Code Usage Patterns**: Track popular sharing times
5. **Error Rates**: Monitor for system issues

### CloudWatch Dashboards

Create custom dashboards to monitor:
- Lambda function performance
- API Gateway metrics
- S3 storage costs
- DynamoDB usage

## 🔄 Backup and Recovery

### Data Backup
- **S3**: Cross-region replication for critical files
- **DynamoDB**: Point-in-time recovery enabled
- **Lambda**: Code stored in version control

### Disaster Recovery
1. **Multi-region deployment**: Deploy to secondary region
2. **Database replication**: DynamoDB Global Tables
3. **DNS failover**: Route 53 health checks

## 📈 Scaling Considerations

### Performance Optimization
- **API Gateway caching**: Reduce Lambda invocations
- **S3 Transfer Acceleration**: Faster uploads globally
- **CloudFront CDN**: Cache static frontend assets

### High Availability
- **Multi-AZ deployment**: Automatic with AWS services
- **Auto-scaling**: Lambda scales automatically
- **Load balancing**: API Gateway handles distribution

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review CloudWatch logs
3. Open an issue on GitHub
4. Contact the development team

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks
- Monitor AWS costs monthly
- Review and update IAM policies quarterly
- Update Lambda runtime versions annually
- Security audit semi-annually

### Updating the System
1. Test changes in development environment
2. Use deployment scripts for consistency
3. Monitor post-deployment metrics
4. Have rollback plan ready

---

**Built with ❤️ using AWS Serverless Technologies**