import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document_model.dart';

class DocumentListWidget extends StatelessWidget {
  final List<Document> documents;
  final Function(Document)? onDocumentTap;
  final Function(Document)? onDocumentDelete;

  const DocumentListWidget({
    Key? key,
    required this.documents,
    this.onDocumentTap,
    this.onDocumentDelete,
  }) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  String _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) return '📄';
    if (fileName.toLowerCase().endsWith('.doc') || 
        fileName.toLowerCase().endsWith('.docx')) {
      return '📝';
    }
    if (fileName.toLowerCase().endsWith('.txt')) return '📃';
    if (fileName.toLowerCase().endsWith('.jpg') || 
        fileName.toLowerCase().endsWith('.png') || 
        fileName.toLowerCase().endsWith('.jpeg')) {
      return '🖼️';
    }
    return '📎';
  }

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No documents uploaded yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Documents:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...documents.map((document) => Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Text(
              _getFileIcon(document.name),
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              document.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploaded: ${_formatDate(document.uploadedAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Click to view/download',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: onDocumentDelete != null
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDocumentDelete!(document),
                  )
                : null,
            onTap: () => _launchUrl(document.downloadUrl),
          ),
        )).toList(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}