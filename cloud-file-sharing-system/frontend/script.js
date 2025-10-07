// Configuration - Update these URLs with your API Gateway endpoints
const API_BASE_URL = 'https://0wg2reeia1.execute-api.us-east-1.amazonaws.com/prod';
const UPLOAD_ENDPOINT = `${API_BASE_URL}/upload`;
const DOWNLOAD_ENDPOINT = `${API_BASE_URL}/download`;
const INFO_ENDPOINT = `${API_BASE_URL}/info`;

// Global variables
let selectedFile = null;
let uploadInProgress = false;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    setupDropZone();
    setupFileInput();
    setupDownloadInput();
    
    // Check if API URLs are configured
    if (API_BASE_URL.includes('YOUR_API_GATEWAY_URL')) {
        showMessage('Please configure your API Gateway URLs in script.js', 'error');
    }
}

// Tab Management
function showTab(tabName) {
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    // Add active class to clicked button
    event.target.classList.add('active');
    
    // Reset forms when switching tabs
    if (tabName === 'upload') {
        resetUpload();
    } else if (tabName === 'download') {
        resetDownload();
    }
}

// File Upload Functions
function setupDropZone() {
    const dropZone = document.getElementById('dropZone');
    
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
    });
    
    ['dragenter', 'dragover'].forEach(eventName => {
        dropZone.addEventListener(eventName, highlight, false);
    });
    
    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, unhighlight, false);
    });
    
    dropZone.addEventListener('drop', handleDrop, false);
    dropZone.addEventListener('click', () => document.getElementById('fileInput').click());
}

function setupFileInput() {
    const fileInput = document.getElementById('fileInput');
    fileInput.addEventListener('change', handleFileSelect);
}

function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
}

function highlight(e) {
    document.getElementById('dropZone').classList.add('dragover');
}

function unhighlight(e) {
    document.getElementById('dropZone').classList.remove('dragover');
}

function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    
    if (files.length > 0) {
        handleFileSelection(files[0]);
    }
}

function handleFileSelect(e) {
    const files = e.target.files;
    if (files.length > 0) {
        handleFileSelection(files[0]);
    }
}

function handleFileSelection(file) {
    if (uploadInProgress) {
        showMessage('Upload already in progress', 'error');
        return;
    }
    
    // Validate file size (50MB limit)
    const maxSize = 50 * 1024 * 1024;
    if (file.size > maxSize) {
        showMessage('File size exceeds 50MB limit', 'error');
        return;
    }
    
    selectedFile = file;
    displaySelectedFile(file);
    document.getElementById('uploadBtn').disabled = false;
}

function displaySelectedFile(file) {
    const selectedFileDiv = document.getElementById('selectedFile');
    const fileName = document.getElementById('fileName');
    const fileSize = document.getElementById('fileSize');
    
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);
    
    selectedFileDiv.style.display = 'block';
    document.getElementById('dropZone').style.display = 'none';
}

function clearSelectedFile() {
    selectedFile = null;
    document.getElementById('selectedFile').style.display = 'none';
    document.getElementById('dropZone').style.display = 'block';
    document.getElementById('fileInput').value = '';
    document.getElementById('uploadBtn').disabled = true;
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

async function uploadFile() {
    if (!selectedFile || uploadInProgress) {
        return;
    }
    
    uploadInProgress = true;
    
    try {
        // Show progress
        showUploadProgress();
        updateProgress(10);
        
        // Prepare form data
        const formData = new FormData();
        formData.append('file', selectedFile);
        
        updateProgress(30);
        
        // Upload file
        const response = await fetch(UPLOAD_ENDPOINT, {
            method: 'POST',
            body: formData
        });
        
        updateProgress(80);
        
        const result = await response.json();
        
        updateProgress(100);
        
        if (response.ok && result.code) {
            showUploadResult(result);
        } else {
            throw new Error(result.error || 'Upload failed');
        }
        
    } catch (error) {
        console.error('Upload error:', error);
        showMessage(error.message || 'Upload failed', 'error');
        hideUploadProgress();
    } finally {
        uploadInProgress = false;
    }
}

function showUploadProgress() {
    document.getElementById('uploadProgress').style.display = 'block';
    document.getElementById('uploadBtn').disabled = true;
}

function hideUploadProgress() {
    document.getElementById('uploadProgress').style.display = 'none';
    document.getElementById('uploadBtn').disabled = false;
}

function updateProgress(percent) {
    const progressFill = document.getElementById('progressFill');
    const progressText = document.getElementById('progressText');
    
    progressFill.style.width = percent + '%';
    progressText.textContent = percent + '%';
}

function showUploadResult(result) {
    hideUploadProgress();
    
    document.getElementById('generatedCode').value = result.code;
    document.getElementById('resultFileName').textContent = result.filename;
    document.getElementById('resultFileSize').textContent = formatFileSize(result.file_size);
    
    // Format expiry time
    const expiryDate = new Date(result.expiry_time);
    document.getElementById('resultExpiry').textContent = expiryDate.toLocaleString();
    
    document.getElementById('uploadResult').style.display = 'block';
    document.getElementById('selectedFile').style.display = 'none';
    
    showMessage('File uploaded successfully!', 'success');
}

function copyCode() {
    const codeInput = document.getElementById('generatedCode');
    codeInput.select();
    codeInput.setSelectionRange(0, 99999); // For mobile devices
    
    navigator.clipboard.writeText(codeInput.value).then(() => {
        showMessage('Code copied to clipboard!', 'success');
    }).catch(() => {
        showMessage('Failed to copy code', 'error');
    });
}

function resetUpload() {
    clearSelectedFile();
    hideUploadProgress();
    document.getElementById('uploadResult').style.display = 'none';
    document.getElementById('uploadBtn').disabled = true;
    updateProgress(0);
}

// File Download Functions
function setupDownloadInput() {
    const downloadInput = document.getElementById('downloadCode');
    downloadInput.addEventListener('input', function(e) {
        // Convert to uppercase and limit length
        e.target.value = e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
    });
    
    downloadInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            getFileInfo();
        }
    });
}

async function getFileInfo() {
    const code = document.getElementById('downloadCode').value.trim();
    
    if (!code) {
        showMessage('Please enter a code', 'error');
        return;
    }
    
    if (code.length < 6) {
        showMessage('Code must be at least 6 characters', 'error');
        return;
    }
    
    try {
        showDownloadProgress();
        
        // Use the download endpoint with action=info parameter
        const response = await fetch(`${DOWNLOAD_ENDPOINT}?code=${code}&action=info`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const result = await response.json();
        
        hideDownloadProgress();
        
        if (response.ok && result.file_info) {
            displayFileInfo(result.file_info);
        } else {
            throw new Error(result.error || 'File not found');
        }
        
    } catch (error) {
        console.error('File info error:', error);
        showMessage(error.message || 'Failed to get file information', 'error');
        hideDownloadProgress();
        hideFileInfo();
    }
}

function displayFileInfo(fileInfo) {
    // Update file icon based on file type
    const fileIcon = document.getElementById('fileIcon');
    fileIcon.className = getFileIcon(fileInfo.filename);
    
    // Update file information
    document.getElementById('downloadFileName').textContent = fileInfo.filename;
    document.getElementById('downloadFileSize').textContent = formatFileSize(fileInfo.file_size);
    
    // Format dates
    const uploadDate = new Date(fileInfo.upload_time);
    const expiryDate = new Date(fileInfo.expires_at);
    
    document.getElementById('uploadTime').textContent = uploadDate.toLocaleString();
    document.getElementById('downloadCount').textContent = fileInfo.download_count;
    document.getElementById('maxDownloads').textContent = fileInfo.max_downloads;
    document.getElementById('expiryTime').textContent = expiryDate.toLocaleString();
    
    document.getElementById('fileInfoDisplay').style.display = 'block';
}

function getFileIcon(filename) {
    const extension = filename.split('.').pop().toLowerCase();
    
    const iconMap = {
        // Documents
        'pdf': 'fas fa-file-pdf',
        'doc': 'fas fa-file-word',
        'docx': 'fas fa-file-word',
        'xls': 'fas fa-file-excel',
        'xlsx': 'fas fa-file-excel',
        'ppt': 'fas fa-file-powerpoint',
        'pptx': 'fas fa-file-powerpoint',
        'txt': 'fas fa-file-alt',
        
        // Images
        'jpg': 'fas fa-file-image',
        'jpeg': 'fas fa-file-image',
        'png': 'fas fa-file-image',
        'gif': 'fas fa-file-image',
        'bmp': 'fas fa-file-image',
        'svg': 'fas fa-file-image',
        
        // Videos
        'mp4': 'fas fa-file-video',
        'avi': 'fas fa-file-video',
        'mov': 'fas fa-file-video',
        'wmv': 'fas fa-file-video',
        
        // Audio
        'mp3': 'fas fa-file-audio',
        'wav': 'fas fa-file-audio',
        'flac': 'fas fa-file-audio',
        
        // Archives
        'zip': 'fas fa-file-archive',
        'rar': 'fas fa-file-archive',
        '7z': 'fas fa-file-archive',
        'tar': 'fas fa-file-archive',
        'gz': 'fas fa-file-archive'
    };
    
    return iconMap[extension] || 'fas fa-file';
}

async function downloadFile() {
    const code = document.getElementById('downloadCode').value.trim();
    
    if (!code) {
        showMessage('Please enter a code', 'error');
        return;
    }
    
    try {
        showDownloadProgress();
        
        const response = await fetch(`${DOWNLOAD_ENDPOINT}?code=${code}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const result = await response.json();
        
        hideDownloadProgress();
        
        if (response.ok && result.download_url) {
            // Create temporary link to trigger download
            const link = document.createElement('a');
            link.href = result.download_url;
            link.download = result.filename;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            showMessage('Download started!', 'success');
        } else {
            throw new Error(result.error || 'Download failed');
        }
        
    } catch (error) {
        console.error('Download error:', error);
        showMessage(error.message || 'Download failed', 'error');
        hideDownloadProgress();
    }
}

function showDownloadProgress() {
    document.getElementById('downloadProgress').style.display = 'block';
}

function hideDownloadProgress() {
    document.getElementById('downloadProgress').style.display = 'none';
}

function hideFileInfo() {
    document.getElementById('fileInfoDisplay').style.display = 'none';
}

function resetDownload() {
    document.getElementById('downloadCode').value = '';
    hideFileInfo();
    hideDownloadProgress();
}

// Message System
function showMessage(text, type = 'info') {
    const messageBox = document.getElementById('messageBox');
    const messageText = document.getElementById('messageText');
    
    messageText.textContent = text;
    messageBox.className = `message ${type}`;
    messageBox.style.display = 'flex';
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        hideMessage();
    }, 5000);
}

function hideMessage() {
    document.getElementById('messageBox').style.display = 'none';
}

// Utility Functions
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString();
}

// Error handling for fetch requests
window.addEventListener('unhandledrejection', event => {
    console.error('Unhandled promise rejection:', event.reason);
    showMessage('An unexpected error occurred', 'error');
});

// CRITICAL: Aggressive Service Worker cleanup to prevent CORS issues
if ('serviceWorker' in navigator) {
    // Unregister ALL service workers
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        console.log('Found', registrations.length, 'service workers');
        for(let registration of registrations) {
            registration.unregister().then(function(boolean) {
                console.log('Service Worker unregistered:', boolean);
            });
        }
    });
    
    // Clear all caches
    if ('caches' in window) {
        caches.keys().then(function(names) {
            names.forEach(function(name) {
                caches.delete(name);
                console.log('Cache deleted:', name);
            });
        });
    }
}

// Service worker registration (DISABLED - was causing CORS issues)
/*
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
            .then(registration => {
                console.log('SW registered: ', registration);
            })
            .catch(registrationError => {
                console.log('SW registration failed: ', registrationError);
            });
    });
}
*/