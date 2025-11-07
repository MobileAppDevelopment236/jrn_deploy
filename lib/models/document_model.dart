class Document {
  final String name;
  final String downloadUrl;
  final DateTime uploadedAt;
  final String filePath;

  Document({
    required this.name,
    required this.downloadUrl,
    required this.uploadedAt,
    required this.filePath,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      name: map['name'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      uploadedAt: DateTime.parse(map['uploadedAt'] ?? DateTime.now().toString()),
      filePath: map['filePath'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'downloadUrl': downloadUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'filePath': filePath,
    };
  }
}