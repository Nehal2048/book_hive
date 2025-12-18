import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class PdfReaderScreen extends StatefulWidget {
  final BookDetails bookDetails;
  final Book book;

  const PdfReaderScreen({
    super.key,
    required this.bookDetails,
    required this.book,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  static const String _viewType = 'pdf-viewer-bookhive';
  static bool _isRegistered = false;
  static String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.bookDetails.pdfLink;
    if (!_isRegistered) {
      _registerPdfViewer();
      _isRegistered = true;
    }
  }

  void _registerPdfViewer() {
    // Register the iframe for PDF viewing
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = _currentUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reading: ${widget.book.title} by ${widget.book.author}'),
      ),
      body: SizedBox.expand(child: HtmlElementView(viewType: _viewType)),
    );
  }
}
