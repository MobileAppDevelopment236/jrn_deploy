import 'package:flutter/foundation.dart';
import '../models/document_model.dart';

class DocumentsProvider with ChangeNotifier {
  final List<Document> _documents = [];

  List<Document> get documents => _documents;

  void addDocument(Document document) {
    _documents.add(document);
    notifyListeners();
  }

  void removeDocument(String filePath) {
    _documents.removeWhere((doc) => doc.filePath == filePath);
    notifyListeners();
  }

  void clearDocuments() {
    _documents.clear();
    notifyListeners();
  }
}