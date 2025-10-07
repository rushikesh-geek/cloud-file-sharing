import json
import boto3
import os
from datetime import datetime
import base64

def lambda_handler(event, context):
    # CORS headers for ALL responses
    cors_headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
        'Content-Type': 'application/json'
    }
    
    print(f"Event received: {json.dumps(event)}")
    print(f"HTTP Method: {event.get('httpMethod')}")
    
    # Handle OPTIONS request (CORS preflight) - CRITICAL FIX
    if event.get('httpMethod') == 'OPTIONS':
        print("*** HANDLING OPTIONS REQUEST - RETURNING 200 IMMEDIATELY ***")
        print(f"CORS headers being returned: {cors_headers}")
        return {
            'statusCode': 200,
            'headers': cors_headers,
            'body': json.dumps({'message': 'CORS preflight successful', 'timestamp': datetime.now().isoformat()})
        }
    
    try:
        # Get parameters from query string
        query_params = event.get('queryStringParameters') or {}
        print(f"Query parameters: {query_params}")
        
        code = query_params.get('code')
        action = query_params.get('action', 'download')
        
        if not code:
            print("*** ERROR: No code parameter provided ***")
            return {
                'statusCode': 400,
                'headers': cors_headers,
                'body': json.dumps({'error': 'Code parameter is required'})
            }
        
        # Initialize AWS clients
        dynamodb = boto3.resource('dynamodb')
        s3_client = boto3.client('s3')
        
        table_name = os.environ['TABLE_NAME']
        bucket_name = os.environ['BUCKET_NAME']
        
        table = dynamodb.Table(table_name)
        
        # Get file metadata from DynamoDB
        response = table.get_item(Key={'code': code})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': cors_headers,
                'body': json.dumps({'error': 'File not found or code expired'})
            }
        
        item = response['Item']
        print(f"Found item: {item}")
        
        # Check if file is expired
        current_time = datetime.now().timestamp()
        if current_time > item.get('expires_at', 0):
            return {
                'statusCode': 410,
                'headers': cors_headers,
                'body': json.dumps({'error': 'File code has expired'})
            }
        
        # If action is 'info', return file information
        if action == 'info':
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': json.dumps({
                    'message': 'File information retrieved successfully',
                    'file_info': {
                        'filename': item.get('filename', 'Unknown'),
                        'file_size': str(item.get('size', 0)),
                        'content_type': item.get('content_type', 'application/octet-stream'),
                        'upload_time': item.get('upload_time', ''),
                        'expires_at': item.get('expires_at', 0)
                    }
                })
            }
        
        # For download action, generate presigned URL
        s3_key = item.get('s3_key')
        
        if not s3_key:
            return {
                'statusCode': 500,
                'headers': cors_headers,
                'body': json.dumps({'error': 'File location not found'})
            }
        
        try:
            # Generate presigned URL for download
            presigned_url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucket_name, 'Key': s3_key},
                ExpiresIn=3600  # 1 hour
            )
            
            return {
                'statusCode': 200,
                'headers': cors_headers,
                'body': json.dumps({
                    'download_url': presigned_url,
                    'filename': item.get('filename', 'download'),
                    'size': item.get('size', 0)
                })
            }
            
        except Exception as e:
            print(f"Error generating presigned URL: {str(e)}")
            return {
                'statusCode': 500,
                'headers': cors_headers,
                'body': json.dumps({'error': 'Failed to generate download link'})
            }
            
    except Exception as e:
        print(f"Error in download handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers,
            'body': json.dumps({'error': 'Internal server error'})
        }