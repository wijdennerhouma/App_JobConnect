import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/translations.dart';

class PdfViewerPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const PdfViewerPage({
    super.key,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  PdfController? _pdfController;
  int _pageNumber = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
      final document = await PdfDocument.openData(widget.pdfBytes);
      _pdfController = PdfController(document: Future.value(document));
      setState(() {
        _totalPages = document.pagesCount;
      });
    } catch (e) {
      if (mounted) {
        final lang = context.read<AppSettings>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.tr('error_prefix')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _totalPages > 0 && _pdfController != null
          ? PdfView(
              controller: _pdfController!,
              onPageChanged: (page) {
                setState(() {
                  _pageNumber = page + 1;
                });
              },
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: _totalPages > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang
                        .tr('page_x_of_y')
                        .replaceAll('{x}', '$_pageNumber')
                        .replaceAll('{y}', '$_totalPages'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.navigate_before),
                        onPressed: _pageNumber > 1
                            ? () {
                                _pdfController!.previousPage(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 300),
                                );
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: _pageNumber < _totalPages
                            ? () {
                                _pdfController!.nextPage(
                                  curve: Curves.ease,
                                  duration: const Duration(milliseconds: 300),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}
