import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/ui/helpers/format_currency.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  Future<Uint8List> buildJobPdf({
    required Company company,
    required Job job,
    required List<String> photoPaths,
  }) async {
    final pdf = pw.Document();

    final compressedImages = <pw.MemoryImage>[];

    // 🔹 Comprimir imágenes antes de agregarlas
    for (final path in photoPaths) {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        quality: 60,
      );

      if (result != null) {
        compressedImages.add(pw.MemoryImage(result));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(job),
          pw.SizedBox(height: 16),
          _buildServiceSection(job),
          pw.SizedBox(height: 16),
          _buildBillingTable(job),
          pw.SizedBox(height: 24),
          if (compressedImages.isNotEmpty)
            _buildPhotosSection(compressedImages),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Job job) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MECCA - Fecha: ${job.date}',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Hora inicio: ${job.startTime}'),
        pw.Text('Hora salida: ${job.endTime}'),
      ],
    );
  }

  pw.Widget _buildServiceSection(Job job) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Descripción del servicio',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(job.service),
      ],
    );
  }

  pw.Widget _buildBillingTable(Job job) {
    final rows = <pw.TableRow>[];

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [_cell('Servicio', bold: true), _cell('Valor', bold: true)],
      ),
    );

    rows.add(
      pw.TableRow(
        children: [
          _cell(
            'Horas trabajadas ${job.hoursCharged} x ${formatCurrency(job.valuePerHour)}',
          ),
          _cell(formatCurrency(job.hoursCharged * job.valuePerHour)),
        ],
      ),
    );

    for (final extra in job.extras) {
      rows.add(
        pw.TableRow(
          children: [
            _cell(extra.description),
            _cell(formatCurrency(extra.value)),
          ],
        ),
      );
    }

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _cell('TOTAL', bold: true),
          _cell(formatCurrency(job.totalDay), bold: true),
        ],
      ),
    );

    return pw.Table(border: pw.TableBorder.all(), children: rows);
  }

  pw.Widget _buildPhotosSection(List<pw.MemoryImage> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Evidencia fotográfica',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images
              .map(
                (img) => pw.Container(
                  width: 150,
                  height: 150,
                  child: pw.Image(img, fit: pw.BoxFit.cover),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
