import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─── Paleta de colores ────────────────────────────────────────────────────────
const _kBlack = PdfColor.fromInt(0xFF1A1A1A);
const _kGold = PdfColor.fromInt(0xFFB8860B);
const _kGoldBg = PdfColor.fromInt(0xFFFFF8E7);
const _kRowAlt = PdfColor.fromInt(0xFFF9F6F0);
const _kBorder = PdfColor.fromInt(0xFFD4B896);
const _kGrey = PdfColor.fromInt(0xFF666666);
const _kWhite = PdfColors.white;

String formatCurrency(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return '\$ ${buffer.toString()}';
}

class PdfService {
  Future<Uint8List> buildJobPdf({
    required Company company,
    required Job job,
    required List<String> photoPaths,
  }) async {
    final pdf = pw.Document();

    // ── Comprimir imágenes ──────────────────────────────────────────────────
    final compressedImages = <pw.MemoryImage>[];
    for (final path in photoPaths) {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        quality: 60,
      );
      if (result != null) compressedImages.add(pw.MemoryImage(result));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (context) => [
          _buildHeader(job, company),
          pw.SizedBox(height: 20),
          _buildBillTo(company),
          pw.SizedBox(height: 16),
          _buildServiceSection(job),
          pw.SizedBox(height: 16),
          _buildBillingTable(job),
          if (compressedImages.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildPhotosHeader(),
            pw.SizedBox(height: 12),
            // ✅ Cada fila de fotos es un widget independiente →
            //    MultiPage puede romper entre filas naturalmente.
            ..._buildPhotoRows(compressedImages),
          ],
          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(Job job, Company company) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _kBlack,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Branding izquierda
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MECCA',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: _kGold,
                  letterSpacing: 4,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Puntadas perfectas, máquinas impecables.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _kWhite,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Profesional: Haleson Valencia Loaiza',
                style: pw.TextStyle(fontSize: 9, color: _kGold),
              ),
            ],
          ),
          // Info factura derecha
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _kGold,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'FACTURA',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _kBlack,
                    letterSpacing: 2,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              _infoRow('Fecha:', job.date),
              _infoRow('Hora de entrada:', job.startTime),
              _infoRow('Hora de salida:', job.endTime),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _kGold)),
          pw.SizedBox(width: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, color: _kWhite)),
        ],
      ),
    );
  }

  // ── FACTURA A ──────────────────────────────────────────────────────────────
  pw.Widget _buildBillTo(Company company) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder),
        borderRadius: pw.BorderRadius.circular(4),
        color: _kGoldBg,
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FACTURA A:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _kGold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            company.name,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _kBlack,
            ),
          ),
          if (company.address != null)
            pw.Text(
              company.address!,
              style: pw.TextStyle(fontSize: 9, color: _kGrey),
            ),
          if (company.city != null)
            pw.Text(
              company.city!,
              style: pw.TextStyle(fontSize: 9, color: _kGrey),
            ),
        ],
      ),
    );
  }

  // ── SERVICIO PRESTADO ──────────────────────────────────────────────────────
  pw.Widget _buildServiceSection(Job job) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Servicio Prestado'),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            job.service,
            style: pw.TextStyle(fontSize: 10, color: _kBlack),
          ),
        ),
      ],
    );
  }

  // ── TABLA DE COBRO ─────────────────────────────────────────────────────────
  pw.Widget _buildBillingTable(Job job) {
    final rows = <pw.TableRow>[];

    // Encabezado
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kBlack),
        children: [
          _tableCell('Descripción', bold: true, color: _kWhite),
          _tableCell(
            'Total',
            bold: true,
            color: _kWhite,
            align: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    // Horas
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kWhite),
        children: [
          _tableCell(
            'Horas trabajadas: ${job.hoursCharged} × ${formatCurrency(job.valuePerHour)}',
          ),
          _tableCell(
            formatCurrency(job.hoursCharged * job.valuePerHour),
            align: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    // Extras
    for (int i = 0; i < job.extras.length; i++) {
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i.isEven ? _kRowAlt : _kWhite),
          children: [
            _tableCell(job.extras[i].description),
            _tableCell(
              formatCurrency(job.extras[i].value),
              align: pw.Alignment.centerRight,
            ),
          ],
        ),
      );
    }

    // Total
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kGold),
        children: [
          _tableCell('TOTAL', bold: true, color: _kBlack),
          _tableCell(
            formatCurrency(job.totalDay),
            bold: true,
            color: _kBlack,
            align: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Descripción de Cobro'),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _kBorder, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
          },
          children: rows,
        ),
      ],
    );
  }

  // ── FOTOS ──────────────────────────────────────────────────────────────────
  pw.Widget _buildPhotosHeader() {
    return _sectionTitle('Evidencia Fotográfica');
  }

  /// Divide las imágenes en filas de 3.
  /// Cada fila es un widget independiente → MultiPage puede paginar entre filas.
  List<pw.Widget> _buildPhotoRows(List<pw.MemoryImage> images) {
    final rows = <pw.Widget>[];
    const perRow = 3;
    const imgSize = 160.0;

    for (int i = 0; i < images.length; i += perRow) {
      final slice = images.sublist(i, (i + perRow).clamp(0, images.length));

      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              ...slice.map(
                (img) => pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 8),
                  child: pw.Container(
                    width: imgSize,
                    height: imgSize,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _kBorder, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 4,
                      verticalRadius: 4,
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  ),
                ),
              ),
              // Relleno si la última fila tiene menos de 3 fotos
              if (slice.length < perRow) pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  // ── FOOTER ─────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: pw.Text(
        'MECCA · Puntadas perfectas, máquinas impecables.',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, color: _kGrey),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  pw.Widget _sectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 14, color: _kGold),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _kBlack,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool bold = false,
    PdfColor color = _kBlack,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
