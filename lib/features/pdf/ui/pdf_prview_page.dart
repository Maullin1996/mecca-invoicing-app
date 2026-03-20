import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({super.key, required this.pdfBytes});

  final Uint8List pdfBytes;

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  String? _tempPath;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _saveTempFile();
  }

  Future<void> _saveTempFile() async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(widget.pdfBytes);
    setState(() => _tempPath = file.path);
  }

  Future<void> _sharePdf() async {
    if (_tempPath == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(_tempPath!)], text: 'Compartir PDF'),
    );
  }

  @override
  void dispose() {
    // Limpiar archivo temporal
    if (_tempPath != null) File(_tempPath!).deleteSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vista previa PDF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_isReady)
              Text(
                'Página ${_currentPage + 1} de $_totalPages',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: _tempPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: _tempPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() {
                _totalPages = pages ?? 0;
                _isReady = true;
              }),
              onPageChanged: (page, total) => setState(() {
                _currentPage = page ?? 0;
              }),
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al cargar PDF: $error')),
                );
              },
            ),
    );
  }
}
