import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class DocumentExporter {
  static Future<bool> exportFile({
    required String title,
    required String content,
    required String format, // 'md', 'txt', 'html', 'pdf'
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();

      if (format == 'md') {
        final file = File('${tempDir.path}/$sanitizedTitle.md');
        await file.writeAsString(content);
        await Share.shareXFiles([XFile(file.path)], subject: 'Export Markdown File');
        return true;
      }

      if (format == 'txt') {
        final file = File('${tempDir.path}/$sanitizedTitle.txt');
        await file.writeAsString(content);
        await Share.shareXFiles([XFile(file.path)], subject: 'Export Text File');
        return true;
      }

      if (format == 'html') {
        final file = File('${tempDir.path}/$sanitizedTitle.html');
        final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <style>
    body { font-family: system-ui, sans-serif; padding: 2rem; line-height: 1.6; max-width: 800px; margin: 0 auto; color: #1e293b; background-color: #f8fafc; }
    h1 { border-bottom: 2px solid #e2e8f0; padding-bottom: 0.5rem; color: #0f172a; }
    pre { background: #0f172a; color: #f8fafc; padding: 1rem; border-radius: 6px; overflow-x: auto; font-family: monospace; }
    code { font-family: monospace; background: #e2e8f0; padding: 0.2rem 0.4rem; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>$title</h1>
  <div>
    <pre style="white-space: pre-wrap;">$content</pre>
  </div>
</body>
</html>
''';
        await file.writeAsString(htmlContent);
        await Share.shareXFiles([XFile(file.path)], subject: 'Export HTML File');
        return true;
      }

      if (format == 'pdf') {
        final pdf = pw.Document();
        final lines = content.split('\n');

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => [
              pw.Header(level: 0, text: title),
              ...lines.map((line) => pw.Paragraph(
                    text: line,
                    style: const pw.TextStyle(fontSize: 10),
                  )),
            ],
          ),
        );

        final file = File('${tempDir.path}/$sanitizedTitle.pdf');
        await file.writeAsBytes(await pdf.save());
        await Share.shareXFiles([XFile(file.path)], subject: 'Export PDF File');
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
