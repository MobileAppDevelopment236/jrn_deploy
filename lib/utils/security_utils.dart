class SecurityUtils {
  // More comprehensive HTML/XML tag sanitization
  static final _htmlTagRegex = RegExp(r'<[^>]*>', multiLine: true);
  static final _dangerousPatterns = [
    'script', 'javascript', 'vbscript', 'onload', 'onerror', 
    'onclick', 'onmouseover', 'eval(', 'expression('
  ];
  
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final _fileNameRegex = RegExp(r'[^a-zA-Z0-9._-]');
  static final _phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    var sanitized = input
        // Remove HTML tags
        .replaceAll(_htmlTagRegex, '')
        // Escape special characters
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;')
        .trim();
    
    return sanitized;
  }

  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final sanitized = sanitizeInput(email);
    return _emailRegex.hasMatch(sanitized);
  }

  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    final sanitized = sanitizeInput(phone);
    final cleaned = sanitized.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _phoneRegex.hasMatch(cleaned);
  }

  static bool hasMaliciousContent(String input) {
    if (input.isEmpty) return false;
    final lower = input.toLowerCase();
    
    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }
    
    // Check for SQL injection patterns
    if (_hasSqlInjectionPatterns(lower)) {
      return true;
    }
    
    return false;
  }

  static bool _hasSqlInjectionPatterns(String input) {
    final sqlPatterns = [
      r'\b(select|insert|update|delete|drop|create|alter)\b',
      r'(\-\-)|(\/\*)',
      r'union\s+select',
      r'1=1',
      r'or\s+1=1'
    ];
    
    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  static String sanitizeFileName(String fileName) {
    if (fileName.isEmpty) return 'file';
    
    // Remove path traversal attempts
    var safeName = fileName.replaceAll(RegExp(r'\.\./|\.\.\\'), '');
    
    // Replace unsafe characters
    safeName = safeName.replaceAll(_fileNameRegex, '_');
    
    // Limit length
    if (safeName.length > 255) {
      safeName = safeName.substring(0, 255);
    }
    
    return safeName;
  }

  // Additional security utility methods
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static bool isValidName(String name) {
    if (name.isEmpty) return false;
    // Allow letters, spaces, hyphens, apostrophes for names
    return RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s'\-]+$").hasMatch(name) &&
           !hasMaliciousContent(name);
  }

  static String truncateForLogging(String input, {int maxLength = 500}) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength)}...[truncated ${input.length - maxLength} chars]';
  }
}