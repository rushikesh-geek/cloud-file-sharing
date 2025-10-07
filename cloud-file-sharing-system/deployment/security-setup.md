# Security Configuration for Cloud File Sharing System

## 1. Configure S3 Bucket Security

### Apply Bucket Policy
```bash
aws s3api put-bucket-policy \
    --bucket rushikesh-file-sharing-876715058144 \
    --policy file://s3-bucket-policy.json
```

### Enable Server-Side Encryption
```bash
aws s3api put-bucket-encryption \
    --bucket rushikesh-file-sharing-876715058144 \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'
```

### Configure CORS for Web Access
```bash
aws s3api put-bucket-cors \
    --bucket rushikesh-file-sharing-876715058144 \
    --cors-configuration '{
        "CORSRules": [
            {
                "AllowedHeaders": ["*"],
                "AllowedMethods": ["GET", "POST", "PUT", "DELETE", "HEAD"],
                "AllowedOrigins": ["*"],
                "ExposeHeaders": ["ETag"],
                "MaxAgeSeconds": 3000
            }
        ]
    }'
```

### Enable Versioning
```bash
aws s3api put-bucket-versioning \
    --bucket rushikesh-file-sharing-876715058144 \
    --versioning-configuration Status=Enabled
```

### Configure Lifecycle Policy
```bash
aws s3api put-bucket-lifecycle-configuration \
    --bucket rushikesh-file-sharing-876715058144 \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "DeleteOldFiles",
                "Status": "Enabled",
                "Filter": {"Prefix": "files/"},
                "Expiration": {"Days": 7},
                "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 1}
            }
        ]
    }'
```

## 2. Configure DynamoDB Security

### Enable Point-in-Time Recovery
```bash
aws dynamodb update-continuous-backups \
    --table-name file-sharing-codes-rushikesh \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

### Configure TTL for Automatic Cleanup
```bash
aws dynamodb update-time-to-live \
    --table-name file-sharing-codes-rushikesh \
    --time-to-live-specification Enabled=true,AttributeName=expiry_time
```

## 3. Configure API Gateway Security

### Enable WAF (Web Application Firewall)
```bash
# Create WAF ACL
aws wafv2 create-web-acl \
    --scope REGIONAL \
    --default-action Allow={} \
    --name file-sharing-waf \
    --description "WAF for file sharing API"

# Associate with API Gateway (replace with actual ACL ARN)
aws apigatewayv2 associate-route \
    --api-id YOUR_API_ID \
    --route-key "POST /upload" \
    --web-acl-arn "arn:aws:wafv2:region:account:webacl/file-sharing-waf"
```

### Enable Request Throttling
```bash
aws apigateway put-usage-plan \
    --name file-sharing-throttle \
    --throttle BurstLimit=100,RateLimit=50 \
    --quota Limit=10000,Period=DAY \
    --api-stages ApiId=YOUR_API_ID,Stage=prod
```

## 4. Lambda Security Configuration

### Update Execution Role
```bash
# Create IAM role with minimal permissions
aws iam create-role \
    --role-name lambda-file-sharing-role \
    --assume-role-policy-document file://lambda-trust-policy.json

# Attach custom policy
aws iam put-role-policy \
    --role-name lambda-file-sharing-role \
    --policy-name LambdaFileSharePolicy \
    --policy-document file://lambda-execution-policy.json
```

### Enable VPC Configuration (Optional)
```bash
# If you want to run Lambda in VPC for additional security
aws lambda update-function-configuration \
    --function-name rushikesh-file-upload \
    --vpc-config SubnetIds=subnet-12345,SecurityGroupIds=sg-12345
```

## 5. CloudWatch Monitoring

### Create Custom Metrics
```bash
# Set up CloudWatch alarms for unusual activity
aws cloudwatch put-metric-alarm \
    --alarm-name "FileShare-HighErrorRate" \
    --alarm-description "High error rate in file sharing" \
    --metric-name Errors \
    --namespace AWS/Lambda \
    --statistic Sum \
    --period 300 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=FunctionName,Value=rushikesh-file-upload \
    --evaluation-periods 2
```

### Enable CloudTrail
```bash
# Create CloudTrail for audit logging
aws cloudtrail create-trail \
    --name file-sharing-audit \
    --s3-bucket-name your-cloudtrail-bucket
```

## 6. Security Best Practices

### Environment Variables Encryption
```bash
# Enable encryption for Lambda environment variables
aws lambda update-function-configuration \
    --function-name rushikesh-file-upload \
    --kms-key-arn arn:aws:kms:region:account:key/key-id
```

### Network Security
- Use HTTPS only (enforced by API Gateway)
- Consider implementing API keys for additional access control
- Set up IP whitelisting if needed

### Data Classification
- Implement content scanning for malicious files
- Add virus scanning using AWS Lambda layers
- Monitor for sensitive data uploads

### Access Logging
```bash
# Enable S3 access logging
aws s3api put-bucket-logging \
    --bucket rushikesh-file-sharing-876715058144 \
    --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "your-access-logs-bucket",
            "TargetPrefix": "access-logs/"
        }
    }'
```

## 7. Compliance and Governance

### AWS Config Rules
```bash
# Set up Config rules for compliance
aws configservice put-config-rule \
    --config-rule '{
        "ConfigRuleName": "s3-bucket-ssl-requests-only",
        "Source": {
            "Owner": "AWS",
            "SourceIdentifier": "S3_BUCKET_SSL_REQUESTS_ONLY"
        }
    }'
```

### Resource Tagging
```bash
# Tag resources for better governance
aws s3api put-bucket-tagging \
    --bucket rushikesh-file-sharing-876715058144 \
    --tagging '{
        "TagSet": [
            {"Key": "Project", "Value": "FileSharing"},
            {"Key": "Environment", "Value": "Production"},
            {"Key": "Owner", "Value": "YourName"}
        ]
    }'
```

## 8. Security Testing

### Penetration Testing Checklist
- [ ] Test file upload size limits
- [ ] Test malicious file uploads
- [ ] Test SQL injection in codes
- [ ] Test XSS in filenames
- [ ] Test unauthorized access attempts
- [ ] Test rate limiting
- [ ] Test CORS configuration

### Automated Security Scanning
```bash
# Use AWS Inspector for vulnerability assessment
aws inspector create-assessment-target \
    --assessment-target-name file-sharing-security \
    --resource-group-arn arn:aws:inspector:region:account:resourcegroup/your-group
```

## 9. Incident Response

### Security Event Response
1. **Detection**: CloudWatch alarms and logs
2. **Analysis**: Review CloudTrail and application logs
3. **Containment**: Disable affected functions/API endpoints
4. **Eradication**: Remove malicious files and codes
5. **Recovery**: Restore from backups if needed
6. **Lessons Learned**: Update security measures

### Emergency Procedures
```bash
# Quickly disable API Gateway
aws apigateway update-stage \
    --rest-api-id YOUR_API_ID \
    --stage-name prod \
    --patch-ops op=replace,path=/throttle/rateLimit,value=0

# Disable Lambda functions
aws lambda put-function-concurrency \
    --function-name rushikesh-file-upload \
    --reserved-concurrent-executions 0
```

## 10. Regular Security Maintenance

### Monthly Tasks
- Review CloudWatch logs for anomalies
- Update Lambda runtime versions
- Review IAM permissions
- Check for unused resources

### Quarterly Tasks
- Security assessment
- Update dependency versions
- Review and update policies
- Penetration testing

### Annual Tasks
- Complete security audit
- Update disaster recovery plan
- Review compliance requirements
- Update security documentation