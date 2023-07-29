// TODO Implement this library.// pdf_view_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewPage extends StatelessWidget {
  final String filePath;

  const PdfViewPage({required this.filePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monggo ditingali ryin'),
      ),
      body: PDFView(filePath: filePath),
    );
  }
}
