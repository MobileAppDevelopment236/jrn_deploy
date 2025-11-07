import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.blue[700]),
            const SizedBox(height: 20),
            Text('My Documents',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('Secure document storage and management',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}