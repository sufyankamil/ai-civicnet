class UserSession {
  final String id;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String userAgent;
  final String ipAddress;
  final bool isCurrent;

  UserSession({
    required this.id,
    required this.createdAt,
    required this.lastActiveAt,
    required this.userAgent,
    required this.ipAddress,
    required this.isCurrent,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      userAgent: json['user_agent'] as String? ?? 'Active Session',
      ipAddress: json['ip_address'] as String? ?? 'Unknown IP',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  /// Parses the user agent to a more friendly device name.
  String get deviceName {
    final ua = userAgent; // Keep case for extraction
    final lowerUa = ua.toLowerCase();
    
    // 1. Try to extract from our custom format: "CivicNet/1.1.5 (iPhone 15 Pro; iOS 17.5)"
    if (ua.contains('(') && ua.contains(')')) {
      try {
        final startIndex = ua.indexOf('(') + 1;
        final endIndex = ua.indexOf(')');
        final content = ua.substring(startIndex, endIndex);
        
        // If it contains a semicolon, the first part is the model
        if (content.contains(';')) {
          return content.split(';').first.trim();
        }
        return content.trim();
      } catch (_) {
        // Fallback to basic patterns
      }
    }

    // 2. Check for specific mobile/desktop patterns
    if (lowerUa.contains('iphone')) return 'iPhone';
    if (lowerUa.contains('ipad')) return 'iPad';
    if (lowerUa.contains('android')) return 'Android Device';
    if (lowerUa.contains('macintosh')) return 'Mac';
    if (lowerUa.contains('windows')) return 'Windows PC';
    if (lowerUa.contains('linux')) return 'Linux PC';
    
    // 3. Clean up technical legacy strings (e.g. "dart:io", "dart", "active session")
    if (lowerUa.contains('dart') || 
        lowerUa.contains('active session') || 
        lowerUa.contains('io') ||
        lowerUa.length < 5) {
      return 'Mobile Device';
    }
    
    return 'Unknown Device';
  }

  /// Returns a representative icon for the device.
  bool get isMobile => userAgent.toLowerCase().contains('iphone') || 
                        userAgent.toLowerCase().contains('android') || 
                        userAgent.toLowerCase().contains('ipad') ||
                        userAgent.toLowerCase().contains('dart');
}
