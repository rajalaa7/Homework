class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String contactInfo;
  final String type; // 'lost' or 'found'
  final String? imageUrl;
  final DateTime dateReported;
  final bool isClaimed;
  final String reporterName;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.contactInfo,
    required this.type,
    this.imageUrl,
    required this.dateReported,
    this.isClaimed = false,
    required this.reporterName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'contactInfo': contactInfo,
      'type': type,
      'imageUrl': imageUrl,
      'dateReported': dateReported.millisecondsSinceEpoch,
      'isClaimed': isClaimed,
      'reporterName': reporterName,
    };
  }

  factory LostFoundItem.fromMap(Map<String, dynamic> map) {
    return LostFoundItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      contactInfo: map['contactInfo'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'],
      dateReported: DateTime.fromMillisecondsSinceEpoch(map['dateReported'] ?? 0),
      isClaimed: map['isClaimed'] ?? false,
      reporterName: map['reporterName'] ?? '',
    );
  }
}