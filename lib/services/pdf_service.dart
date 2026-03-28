import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:civic_net/features/profile/models/user.dart';
import 'package:intl/intl.dart';
import 'package:civic_net/services/logger_service.dart';

class PdfService {
  static Future<void> generateVolunteerCertificate(User user) async {
    try {
      final pdf = pw.Document();

      // Brand colors from app_theme.dart (converted to PdfColors)
      const primaryColor = PdfColor.fromInt(0xFF7B61FF); // Vivid Violet
      const secondaryColor = PdfColor.fromInt(0xFFB388FF); // Soft Lavender
      const darkColor = PdfColor.fromInt(0xFF2D2436); // textPrimaryLight

      // Use NotoSans which has excellent Unicode support
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryColor, width: 6),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(24)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 10),
                  // Logo / Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: const pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Text(
                      'CIVICNET',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 32,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Community Impact Certificate',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      color: secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(
                    width: 150,
                    height: 2,
                    color: const PdfColor.fromInt(0x4D7B61FF), // 30% Opacity primaryColor
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    'This is to certify that',
                    style: pw.TextStyle(font: font, fontSize: 16, color: darkColor),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    user.name,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 36,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text(
                      'has demonstrated exceptional dedication to community service and neighborly support through the CivicNet platform.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
                    ),
                  ),
                  pw.SizedBox(height: 50),
                  // Stats Section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(fontBold, font, '${user.hoursSaved}h', 'Hours Saved', primaryColor),
                      _buildStat(fontBold, font, '${user.neighborsImpacted}', 'Neighbors Helped', primaryColor),
                      _buildStat(fontBold, font, '${user.points}', 'Karma Points', primaryColor),
                    ],
                  ),
                  pw.Spacer(),
                  // Footer
                  pw.Divider(color: PdfColors.grey300, thickness: 1),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Issued on: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                          pw.Text('Verification ID: ${user.id.length > 8 ? user.id.substring(0, 8).toUpperCase() : user.id.toUpperCase()}',
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Official Community Document',
                              style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)),
                          pw.Text('© 2026 CivicNet. All rights reserved.',
                              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
                          pw.Text('www.civicnet.app',
                              style: pw.TextStyle(font: font, fontSize: 10, color: secondaryColor)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'This certificate is an official record of community contribution generated by the CivicNet Network.',
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey400),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Pre-save the bytes to ensure no threading issues during layoutPdf
      final bytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: 'Certificate_${user.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf',
      );
    } catch (e, stack) {
      logger.e('Failed to generate PDF: $e\n$stack');
    }
  }

  static pw.Widget _buildStat(pw.Font fontBold, pw.Font font, String value, String label, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 24, color: color),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
