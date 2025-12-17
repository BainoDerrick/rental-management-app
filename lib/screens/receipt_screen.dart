import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rental_management_app/models/payment_model.dart';
import 'package:rental_management_app/models/tenant_model.dart';
import 'package:rental_management_app/screens/home_screen.dart';

class ReceiptScreen extends StatelessWidget {
  final Payment payment;
  final Tenant tenant;

  ReceiptScreen({super.key, required this.payment, required this.tenant});

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  late final Future<int> _receiptNumberFuture = _getNextReceiptNumber();

  static const primaryBlue = Color(0xFF1E88E5);
  static const accentYellow = Color(0xFFFFCA28);

  // ------------------------------------------------------------
  // RECEIPT NUMBER
  // ------------------------------------------------------------
  static Future<int> _getNextReceiptNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_receipt_number') ?? 999;
    final next = last + 1;
    await prefs.setInt('last_receipt_number', next);
    return next;
  }

  // ------------------------------------------------------------
  // NUMBER TO WORDS
  // ------------------------------------------------------------
  String _numberToWords(int number) {
    if (number == 0) return 'Zero shillings';

    const units = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];

    const tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    const thousands = ['', 'thousand', 'million', 'billion'];

    List<String> words = [];
    int i = 0;

    while (number > 0) {
      int part = number % 1000;
      if (part > 0) {
        List<String> segment = [];

        if (part >= 100) {
          segment.add('${units[part ~/ 100]} hundred');
          part %= 100;
        }

        if (part > 0) {
          if (part < 20) {
            segment.add(units[part]);
          } else {
            segment.add(tens[part ~/ 10]);
            if (part % 10 > 0) {
              segment.add(units[part % 10]);
            }
          }
        }

        if (i > 0) segment.add(thousands[i]);
        words.insertAll(0, segment);
      }
      number ~/= 1000;
      i++;
    }

    words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    return '${words.join(' ')} shillings';
  }

  // ------------------------------------------------------------
  // PDF
  // ------------------------------------------------------------
  Future<void> _downloadReceiptAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    final totalPaid = (payment.rentPaid + payment.waterBillPaid).toInt();
    final receiptNumber = await _receiptNumberFuture;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BSB AND SONS RESIDENTIALS',
                  style: pw.TextStyle(font: bold, fontSize: 20),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Receipt No: $receiptNumber',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  'Date: ${_dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Divider(height: 30),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Received from: ${tenant.name}',
                  style: pw.TextStyle(font: bold, fontSize: 14),
                ),
                pw.Text(
                  'House No: ${tenant.houseNumber}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Rent: UGX ${_currencyFormat.format(payment.rentPaid)}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Text(
                  'Water: UGX ${_currencyFormat.format(payment.waterBillPaid)}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.Divider(height: 30),
                pw.Text(
                  'Total: UGX ${_currencyFormat.format(totalPaid)}',
                  style: pw.TextStyle(font: bold, fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Thank you for your payment!',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
            ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Receipt_${tenant.name}_$receiptNumber.pdf',
    );
  }

  // ------------------------------------------------------------
  // APP BAR
  // ------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0D47A1), primaryBlue]),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Payment Receipt',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final totalPaid = (payment.rentPaid + payment.waterBillPaid).toInt();

    return FutureBuilder<int>(
      future: _receiptNumberFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _infoCard(
                      title: 'Total Paid',
                      value: 'UGX ${_currencyFormat.format(totalPaid)}',
                      highlight: true,
                    ),
                    const SizedBox(height: 16),
                    _infoCard(title: 'Tenant', value: tenant.name),
                    _infoCard(title: 'House No', value: tenant.houseNumber),
                    _infoCard(
                      title: 'Rent',
                      value: 'UGX ${_currencyFormat.format(payment.rentPaid)}',
                    ),
                    _infoCard(
                      title: 'Water',
                      value:
                          'UGX ${_currencyFormat.format(payment.waterBillPaid)}',
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton(
                          label: 'Home',
                          color: accentYellow,
                          textColor: Colors.black,
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (_) => false,
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _actionButton(
                          label: 'Download PDF',
                          color: primaryBlue,
                          textColor: Colors.white,
                          onTap: () => _downloadReceiptAsPdf(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _infoCard({
    required String title,
    required String value,
    bool highlight = false,
  }) {
    return Card(
      elevation: highlight ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 18 : 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? primaryBlue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
        minimumSize: const Size(150, 56),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
