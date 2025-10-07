import boto3
import os
import uuid
import string
import secrets
import mimetypes
from datetime import datetime, timedelta
from typing import Dict, Any
import json
import base64

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'rushikesh-file-sharing-876715058144')
TABLE_NAME = os.environ.get('TABLE_NAME', 'file-sharing-codes-rushikesh')
CODE_EXPIRY_HOURS = int(os.environ.get('CODE_EXPIRY_HOURS', '24'))

def create_response(status_code: int, body: dict) -> dict:
    """Create a standardized HTTP response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Access-Control-Max-Age': '86400'
        },
        'body': json.dumps(body, default=str)
    }

def generate_unique_code(length: int = 8) -> str:
    """Generate a unique code for file sharing"""
    # Use uppercase letters and numbers for better readability
    alphabet = string.ascii_uppercase + string.digits
    # Remove confusing characters (0, O, 1, I, L)
    alphabet = alphabet.replace('0', '').replace('O', '').replace('1', '').replace('I', '').replace('L', '')
    
    # Generate random code
    code = ''.join(secrets.choice(alphabet) for _ in range(length))
    
    # Add timestamp component to ensure uniqueness
    timestamp_suffix = str(int(datetime.now().timestamp()))[-2:]
    return code + timestamp_suffix

def validate_file(file_content: bytes, filename: str) -> Dict[str, Any]:
    """Validate uploaded file"""
    max_file_size = 50 * 1024 * 1024  # 50MB limit
    
    if len(file_content) > max_file_size:
        return {
            'valid': False,
            'error': f'File size ({len(file_content)} bytes) exceeds maximum allowed size (50MB)'
        }
    
    # Check file extension
    allowed_extensions = {
        '.txt', '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
        '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg',
        '.mp3', '.mp4', '.avi', '.mov', '.wmv',
        '.zip', '.rar', '.7z', '.tar', '.gz'
    }
    
    file_ext = os.path.splitext(filename.lower())[1]
    if file_ext not in allowed_extensions:
        return {
            'valid': False,
            'error': f'File type {file_ext} is not allowed'
        }
    
    return {'valid': True}

def upload_to_s3(file_content: bytes, filename: str, unique_code: str) -> Dict[str, Any]:
    """Upload file to S3 bucket"""
    try:
        # Create unique S3 key
        file_extension = os.path.splitext(filename)[1]
        s3_key = f"files/{unique_code}/{filename}"
        
        # Determine content type
        content_type, _ = mimetypes.guess_type(filename)
        if not content_type:
            content_type = 'application/octet-stream'
        
        # Upload to S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=s3_key,
            Body=file_content,
            ContentType=content_type,
            Metadata={
                'original-filename': filename,
                'upload-code': unique_code,
                'upload-time': datetime.utcnow().isoformat()
            }
        )
        
        return {
            'success': True,
            's3_key': s3_key,
            'content_type': content_type
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': f'Failed to upload to S3: {str(e)}'
        }

def save_to_dynamodb(unique_code: str, s3_key: str, filename: str, file_size: int, content_type: str) -> Dict[str, Any]:
    """Save file metadata to DynamoDB"""
    try:
        table = dynamodb.Table(TABLE_NAME)
        
        # Calculate expiry time
        expiry_time = datetime.utcnow() + timedelta(hours=CODE_EXPIRY_HOURS)
        expiry_timestamp = int(expiry_time.timestamp())
        
        # Save to DynamoDB with TTL attribute
        table.put_item(
            Item={
                'code': unique_code,
                's3_key': s3_key,
                'filename': filename,
                'file_size': file_size,
                'content_type': content_type,
                'upload_time': datetime.utcnow().isoformat(),
                'expiry_time': expiry_timestamp,
                'expires_at': expiry_timestamp,  # TTL attribute
                'download_count': 0,
                'max_downloads': 10  # Maximum downloads allowed
            }
        )
        
        return {
            'success': True,
            'expiry_time': expiry_time.isoformat()
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': f'Failed to save to DynamoDB: {str(e)}'
        }

def lambda_handler(event, context):
    """Main Lambda handler for file upload"""
    # CORS headers that work with API Gateway
    cors_headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
    }
    
    try:
        print(f"Received event: {json.dumps(event, default=str)}")
        
        # Handle OPTIONS request for CORS
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': json.dumps({'message': 'CORS preflight success'})
            }
        
        # Validate HTTP method
        if event.get('httpMethod') != 'POST':
            return create_response(405, {'error': 'Method not allowed. Use POST to upload files.'})
        
        # Parse the request
        if 'body' not in event or not event['body']:
            return create_response(400, {'error': 'No file data in request body'})
        
        # Handle base64 encoded body
        body = event['body']
        if event.get('isBase64Encoded', False):
            body = base64.b64decode(body)
        
        # Parse multipart form data
        content_type = event.get('headers', {}).get('content-type', '') or event.get('headers', {}).get('Content-Type', '')
        if 'multipart/form-data' not in content_type:
            return create_response(400, {'error': 'Content-Type must be multipart/form-data'})
        
        # Extract boundary from content-type header
        boundary = None
        for part in content_type.split(';'):
            if 'boundary=' in part:
                boundary = part.split('boundary=')[1].strip()
                break
        
        if not boundary:
            return create_response(400, {'error': 'No boundary found in multipart data'})
        
        # Convert body to bytes if it's a string
        if isinstance(body, str):
            body = body.encode('utf-8')
        
        # Parse multipart data
        parts = body.split(f'--{boundary}'.encode())
        
        file_content = None
        filename = None
        
        for part in parts:
            if b'Content-Disposition: form-data' in part and b'filename=' in part:
                # Extract filename
                lines = part.split(b'\r\n')
                for line in lines:
                    if b'Content-Disposition' in line:
                        line_str = line.decode('utf-8', errors='ignore')
                        if 'filename=' in line_str:
                            filename_part = line_str.split('filename=')[1].strip('"').strip("'")
                            filename = filename_part
                            break
                
                # Extract file content (after double newline)
                if b'\r\n\r\n' in part:
                    file_content = part.split(b'\r\n\r\n', 1)[1]
                    # Remove trailing boundary marker
                    if file_content.endswith(b'\r\n'):
                        file_content = file_content[:-2]
        
        if not file_content or not filename:
            return create_response(400, {'error': 'No file found in request. Please select a file to upload.'})
        
        # Validate file
        validation_result = validate_file(file_content, filename)
        if not validation_result['valid']:
            return create_response(400, {'error': validation_result['error']})
        
        # Generate unique code
        unique_code = generate_unique_code()
        
        # Check if code already exists (very unlikely but good practice)
        table = dynamodb.Table(TABLE_NAME)
        try:
            response = table.get_item(Key={'code': unique_code})
            if 'Item' in response:
                # Generate a new code if collision occurs
                unique_code = generate_unique_code()
        except Exception as e:
            print(f"Warning: Could not check for code collision: {str(e)}")
        
        # Upload to S3
        upload_result = upload_to_s3(file_content, filename, unique_code)
        if not upload_result['success']:
            return create_response(500, {'error': upload_result['error']})
        
        # Save to DynamoDB
        db_result = save_to_dynamodb(
            unique_code, 
            upload_result['s3_key'], 
            filename, 
            len(file_content),
            upload_result['content_type']
        )
        
        if not db_result['success']:
            # Clean up S3 file if DynamoDB save fails
            try:
                s3_client.delete_object(Bucket=BUCKET_NAME, Key=upload_result['s3_key'])
            except Exception as cleanup_error:
                print(f"Failed to cleanup S3 object: {str(cleanup_error)}")
            return create_response(500, {'error': db_result['error']})
        
        # Return success response
        return create_response(200, {
            'message': 'File uploaded successfully!',
            'code': unique_code,
            'filename': filename,
            'file_size': len(file_content),
            'expiry_time': db_result['expiry_time'],
            'expires_in_hours': CODE_EXPIRY_HOURS
        })
        
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        import traceback
        print(f"Traceback: {traceback.format_exc()}")
        return create_response(500, {'error': f'Internal server error: {str(e)}'})