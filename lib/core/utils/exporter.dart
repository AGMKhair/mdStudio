import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:docx_creator/docx_creator.dart';

class DocumentExporter {
  static pw.Widget _parseInlineText(String text, {double fontSize = 10, bool isHeader = false}) {
    final List<pw.InlineSpan> spans = [];
    final RegExp regExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');
    final matches = regExp.allMatches(text);
    
    int lastIndex = 0;
    
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(pw.TextSpan(
          text: text.substring(lastIndex, match.start),
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ));
      }
      
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(pw.TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(pw.TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: pw.TextStyle(
            fontSize: fontSize,
            fontStyle: pw.FontStyle.italic,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(pw.TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: pw.TextStyle(
            fontSize: fontSize,
            font: pw.Font.courier(),
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ));
      }
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      spans.add(pw.TextSpan(
        text: text.substring(lastIndex),
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ));
    }
    
    return pw.RichText(
      text: pw.TextSpan(children: spans),
    );
  }

  static String _markdownToHtml(String title, String content) {
    final lines = content.split('\n');
    final List<String> htmlLines = [];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        htmlLines.add('<br>');
        continue;
      }

      String parseInline(String text) {
        return text
            .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<strong>${m[1]}</strong>')
            .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => '<em>${m[1]}</em>')
            .replaceAllMapped(RegExp(r'`(.*?)`'), (m) => '<code>${m[1]}</code>');
      }

      if (line.startsWith('# ')) {
        htmlLines.add('<h1>${parseInline(line.substring(2))}</h1>');
      } else if (line.startsWith('## ')) {
        htmlLines.add('<h2>${parseInline(line.substring(3))}</h2>');
      } else if (line.startsWith('### ')) {
        htmlLines.add('<h3>${parseInline(line.substring(4))}</h3>');
      } else if (line.startsWith('> ')) {
        htmlLines.add('<blockquote>${parseInline(line.substring(2))}</blockquote>');
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        htmlLines.add('<li>${parseInline(line.substring(2))}</li>');
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(line)!;
        htmlLines.add('<li>${parseInline(line.substring(match.end))}</li>');
      } else {
        htmlLines.add('<p>${parseInline(line)}</p>');
      }
    }

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title</title>
  <style>
    body { font-family: system-ui, sans-serif; padding: 2rem; line-height: 1.6; max-width: 800px; margin: 0 auto; color: #1e293b; background-color: #f8fafc; }
    h1 { border-bottom: 2px solid #e2e8f0; padding-bottom: 0.5rem; color: #0f172a; margin-top: 1.5rem; }
    h2 { color: #1e293b; margin-top: 1.5rem; }
    h3 { color: #334155; margin-top: 1.25rem; }
    blockquote { border-left: 4px solid #cbd5e1; padding-left: 1rem; color: #64748b; font-style: italic; margin: 1rem 0; }
    code { font-family: monospace; background: #e2e8f0; padding: 0.2rem 0.4rem; border-radius: 4px; color: #0f172a; }
    p { margin: 0.5rem 0; }
    li { margin: 0.25rem 0; }
  </style>
</head>
<body>
  <h1>$title</h1>
  <div>
    ${htmlLines.join('\n')}
  </div>
</body>
</html>
''';
  }

  static List<pw.Widget> _parseMarkdownToWidgets(String content) {
    final lines = content.split('\n');
    final List<pw.Widget> widgets = [];
    
    int i = 0;
    while (i < lines.length) {
      final rawLine = lines[i];
      final line = rawLine.trim();

      if (line.isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        i++;
        continue;
      }

      if (line == '---' || line == '***' || line == '___') {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Divider(thickness: 1, color: PdfColor.fromHex('#cbd5e1')),
        ));
        i++;
        continue;
      }

      if (line.startsWith('# ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: _parseInlineText(line.substring(2), fontSize: 20, isHeader: true),
        ));
        i++;
        continue;
      } else if (line.startsWith('## ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: _parseInlineText(line.substring(3), fontSize: 16, isHeader: true),
        ));
        i++;
        continue;
      } else if (line.startsWith('### ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
          child: _parseInlineText(line.substring(4), fontSize: 13, isHeader: true),
        ));
        i++;
        continue;
      }

      if (line.startsWith('```')) {
        final List<String> codeLines = [];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++;
        
        widgets.add(pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#f1f5f9'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(
            codeLines.join('\n'),
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: 9,
              color: PdfColor.fromHex('#0f172a'),
            ),
          ),
        ));
        continue;
      }

      if (line.startsWith('> ')) {
        final List<String> quoteLines = [line.substring(2)];
        i++;
        while (i < lines.length && lines[i].trim().startsWith('> ')) {
          quoteLines.add(lines[i].trim().substring(2));
          i++;
        }
        widgets.add(pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: PdfColor.fromHex('#cbd5e1'), width: 3)),
          ),
          padding: const pw.EdgeInsets.only(left: 8),
          margin: const pw.EdgeInsets.symmetric(vertical: 6),
          child: _parseInlineText(quoteLines.join(' '), fontSize: 10),
        ));
        continue;
      }

      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) {
        final content = line.startsWith('• ') ? line.substring(2) : line.substring(2);
        widgets.add(pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 15,
              child: pw.Text('• ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              child: _parseInlineText(content, fontSize: 10),
            ),
          ],
        ));
        i++;
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(line)!;
        final textContent = line.substring(match.end);
        widgets.add(pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 15,
              child: pw.Text(line.substring(0, match.end - 1), style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              child: _parseInlineText(textContent, fontSize: 10),
            ),
          ],
        ));
        i++;
        continue;
      }

      if (line.startsWith('|') && i + 1 < lines.length && lines[i + 1].trim().startsWith('|') && lines[i + 1].trim().contains('-')) {
        final List<List<String>> tableData = [];
        final headerRow = line.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        tableData.add(headerRow);
        
        i += 2;
        
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          final dataRow = lines[i].split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          tableData.add(dataRow);
          i++;
        }

        widgets.add(pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#e2e8f0'), width: 0.5),
            children: tableData.map((row) {
              final isHeaderRow = tableData.indexOf(row) == 0;
              return pw.TableRow(
                decoration: isHeaderRow ? pw.BoxDecoration(color: PdfColor.fromHex('#f8fafc')) : null,
                children: row.map((cell) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: _parseInlineText(
                      cell,
                      fontSize: 9,
                      isHeader: isHeaderRow,
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ));
        continue;
      }

      final List<String> paragraphLines = [line];
      i++;
      while (i < lines.length) {
        final nextLine = lines[i].trim();
        if (nextLine.isEmpty ||
            nextLine.startsWith('# ') ||
            nextLine.startsWith('## ') ||
            nextLine.startsWith('### ') ||
            nextLine.startsWith('```') ||
            nextLine.startsWith('> ') ||
            nextLine.startsWith('- ') ||
            nextLine.startsWith('* ') ||
            nextLine.startsWith('• ') ||
            nextLine.startsWith('|') ||
            nextLine == '---' ||
            nextLine == '***' ||
            nextLine == '___' ||
            RegExp(r'^\d+\.\s').hasMatch(nextLine)) {
          break;
        }
        paragraphLines.add(nextLine);
        i++;
      }

      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: _parseInlineText(paragraphLines.join(' '), fontSize: 10),
      ));
    }
    
    return widgets;
  }

  static Future<bool> exportFile({
    required String title,
    required String content,
    required String format, // 'md', 'txt', 'html', 'pdf'
  }) async {
    try {
      final sanitizedTitle = title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();

      final String extension = format == 'doc' ? 'docx' : format;
      final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

      // Generate content representation
      late final List<int> pdfBytes;
      late final List<int> docxBytes;
      late final String fileContent;

      if (format == 'pdf') {
        final pdf = pw.Document();
        final pdfWidgets = _parseMarkdownToWidgets(content);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) => [
              pw.Header(level: 0, text: title, textStyle: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              ...pdfWidgets,
            ],
          ),
        );

        pdfBytes = await pdf.save();
      } else if (format == 'doc') {
        final nodes = await MarkdownParser.parse(content);
        final doc = DocxBuiltDocument(elements: nodes);
        docxBytes = await DocxExporter().exportToBytes(doc);
      } else if (format == 'html') {
        fileContent = _markdownToHtml(title, content);
      } else {
        fileContent = content;
      }

      if (isMobile) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$sanitizedTitle.$extension');

        if (format == 'pdf') {
          await tempFile.writeAsBytes(pdfBytes);
        } else if (format == 'doc') {
          await tempFile.writeAsBytes(docxBytes);
        } else {
          await tempFile.writeAsString(fileContent);
        }

        // Determine MimeType for FileSaver
        MimeType fileSaverMime;
        if (format == 'pdf') {
          fileSaverMime = MimeType.pdf;
        } else if (format == 'doc') {
          fileSaverMime = MimeType.other;
        } else {
          fileSaverMime = MimeType.text;
        }

        // Save using native ACTION_CREATE_DOCUMENT file picker on Android
        final savedPath = await FileSaver.instance.saveAs(
          name: sanitizedTitle,
          filePath: tempFile.path,
          fileExtension: extension,
          mimeType: fileSaverMime,
        );

        // If the user successfully saved the file, open it in Chrome/Drive/PDF Viewer immediately
        if (savedPath != null && savedPath.isNotEmpty) {
          final openResult = await OpenFilex.open(tempFile.path);
          return openResult.type == ResultType.done;
        }

        return false;
      } else {
        // Desktop & Web: use FilePicker saving flow
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Select where to save the file:',
          fileName: '$sanitizedTitle.$extension',
        );

        if (outputFile == null) {
          return false; // User cancelled
        }

        final file = File(outputFile);

        if (format == 'pdf') {
          await file.writeAsBytes(pdfBytes);
        } else if (format == 'doc') {
          await file.writeAsBytes(docxBytes);
        } else {
          await file.writeAsString(fileContent);
        }
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
