# File Upload Requirements and Validation

## Supported File Types

### Documents
- **PDF**: `.pdf`
- **Microsoft Word**: `.doc`, `.docx`
- **Microsoft Excel**: `.xls`, `.xlsx`
- **Microsoft PowerPoint**: `.ppt`, `.pptx`
- **Text Files**: `.txt`

### Images
- **JPEG**: `.jpg`, `.jpeg`
- **PNG**: `.png`
- **GIF**: `.gif`
- **BMP**: `.bmp`
- **SVG**: `.svg`

### Videos
- **MP4**: `.mp4`
- **AVI**: `.avi`
- **MOV**: `.mov`
- **WMV**: `.wmv`

### Audio
- **MP3**: `.mp3`
- **WAV**: `.wav`
- **FLAC**: `.flac`

### Archives
- **ZIP**: `.zip`
- **RAR**: `.rar`
- **7-Zip**: `.7z`
- **TAR**: `.tar`
- **GZIP**: `.gz`

## File Size Limits

- **Maximum file size**: 50 MB (52,428,800 bytes)
- **Minimum file size**: 1 byte
- **Empty files**: Not allowed

## Security Validations

### File Name Restrictions
- Maximum length: 255 characters
- Allowed characters: A-Z, a-z, 0-9, spaces, hyphens, underscores, periods
- Prohibited characters: `< > : " | ? * \ /`
- No leading or trailing spaces
- No consecutive periods

### Content Validation
- File extension must match content type
- MIME type validation for common formats
- Magic number verification for binary files
- Virus scanning (recommended for production)

## Upload Process

### 1. Client-Side Validation
```javascript
function validateFile(file) {
    // Check file size
    if (file.size > 50 * 1024 * 1024) {
        return { valid: false, error: 'File too large (max 50MB)' };
    }
    
    // Check file type
    const allowedTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        // ... more types
    ];
    
    if (!allowedTypes.includes(file.type)) {
        return { valid: false, error: 'File type not supported' };
    }
    
    return { valid: true };
}
```

### 2. Server-Side Validation
```python
def validate_file(file_content, filename):
    # Check file size
    if len(file_content) > 50 * 1024 * 1024:
        return False, "File too large"
    
    # Check file extension
    allowed_extensions = {'.pdf', '.doc', '.docx', ...}
    file_ext = os.path.splitext(filename.lower())[1]
    
    if file_ext not in allowed_extensions:
        return False, "File type not allowed"
    
    # Additional security checks
    if is_malicious_file(file_content):
        return False, "File appears to be malicious"
    
    return True, None
```

## Error Handling

### Upload Errors
- **File too large**: "File size exceeds 50MB limit"
- **Invalid type**: "File type not supported"
- **Network error**: "Upload failed, please try again"
- **Server error**: "Server temporarily unavailable"

### Validation Errors
- **Empty file**: "Cannot upload empty file"
- **Corrupted file**: "File appears to be corrupted"
- **Invalid filename**: "Filename contains invalid characters"

## Best Practices

### For Users
1. Compress large files before uploading
2. Use standard file formats when possible
3. Avoid special characters in filenames
4. Check file integrity before sharing codes

### For Developers
1. Implement progressive upload for large files
2. Show upload progress to users
3. Provide clear error messages
4. Log all upload attempts for monitoring

## Performance Considerations

### Upload Optimization
- **Chunked uploads**: For files > 10MB
- **Compression**: Automatic for text-based files
- **Parallel uploads**: Multiple file support
- **Resume capability**: For interrupted uploads

### Monitoring
- Track upload success rates
- Monitor average upload times
- Alert on unusual file types or sizes
- Monitor storage usage patterns