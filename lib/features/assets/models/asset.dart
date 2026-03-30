enum AssetCategory {
  tools,
  garden,
  transport,
  electronics,
  household,
  other,
}

enum AssetStatus {
  available,
  lent,
  private,
}

class CommunityAsset {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final AssetCategory category;
  final String? imageUrl;
  final AssetStatus status;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final double? similarity; // For AI matching
  final String? ownerName; // Fetched via join

  CommunityAsset({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.status,
    this.lat,
    this.lng,
    required this.createdAt,
    this.similarity,
    this.ownerName,
  });

  factory CommunityAsset.fromJson(Map<String, dynamic> json) {
    return CommunityAsset(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category']),
      imageUrl: json['image_url'],
      status: _parseStatus(json['status']),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      similarity: (json['similarity'] as num?)?.toDouble(),
      ownerName: json['owner_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'category': _capitalize(category.name),
      'image_url': imageUrl,
      'status': status.name,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  static AssetCategory _parseCategory(String? category) {
    if (category == null) return AssetCategory.other;
    final normalized = category.toLowerCase();
    return AssetCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => AssetCategory.other,
    );
  }

  static AssetStatus _parseStatus(String? status) {
    return AssetStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => AssetStatus.available,
    );
  }

  CommunityAsset copyWith({
    String? title,
    String? description,
    AssetCategory? category,
    String? imageUrl,
    AssetStatus? status,
    double? similarity,
    String? ownerName,
  }) {
    return CommunityAsset(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      lat: lat,
      lng: lng,
      createdAt: createdAt,
      similarity: similarity ?? this.similarity,
      ownerName: ownerName ?? this.ownerName,
    );
  }
}
