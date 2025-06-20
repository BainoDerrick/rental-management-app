import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  ReceiptScreen({required this.payment, required this.tenant});

  // Custom function to convert numbers to words
  String _numberToWords(int number) {
    if (number == 0) return 'Zero';

    const List<String> units = [
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
    const List<String> tens = [
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
    const List<String> thousands = ['', 'thousand', 'million', 'billion'];

    List<String> words = [];
    int thousandCounter = 0;

    while (number > 0) {
      int threeDigits = number % 1000;
      if (threeDigits > 0) {
        List<String> threeDigitWords = [];

        if (threeDigits >= 100) {
          threeDigitWords.add('${units[threeDigits ~/ 100]} hundred');
          threeDigits %= 100;
        }

        if (threeDigits > 0) {
          if (threeDigits < 20) {
            threeDigitWords.add(units[threeDigits]);
          } else {
            threeDigitWords.add(tens[threeDigits ~/ 10]);
            if (threeDigits % 10 > 0) {
              threeDigitWords.add(units[threeDigits % 10]);
            }
          }
        }

        if (thousandCounter > 0) {
          threeDigitWords.add(thousands[thousandCounter]);
        }
        words.insertAll(0, threeDigitWords);
      }
      number ~/= 1000;
      thousandCounter++;
    }

    if (words.isNotEmpty) {
      words[0] = words[0][0].toUpperCase() + words[0].substring(1);
    }

    return words.join(' ') + ' UGX';
  }

  // Function to get or generate the next receipt number
  Future<int> _getNextReceiptNumber() async {
    final prefs = await SharedPreferences.getInstance();
    int lastReceiptNumber =
        prefs.getInt('last_receipt_number') ??
        999; // Start from 999 to make the first 1000
    int nextReceiptNumber = lastReceiptNumber + 1;
    await prefs.setInt('last_receipt_number', nextReceiptNumber);
    return nextReceiptNumber;
  }

  // Function to generate PDF
  Future<void> _downloadReceiptAsPdf(BuildContext context) async {
    final pdf = pw.Document();
    final robotoFont = await PdfGoogleFonts.robotoRegular();
    final totalPaid = (payment.rentPaid + payment.waterBillPaid).toInt();
    final amountInWords = _numberToWords(totalPaid);
    final currentDate =
        DateTime.now(); // Today's date for the PDF (02:06 PM EAT, 19 Jun 2025)
    final receiptNumber = await _getNextReceiptNumber();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BSB AND SONS RESIDENTIALS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          font: robotoFont,
                        ),
                      ),
                      pw.Text(
                        'LOCATED SSEGUKU ALONG ENTEBBE ROAD TEL: 0782373727',
                        style: pw.TextStyle(fontSize: 10, font: robotoFont),
                      ),
                    ],
                  ),
                  pw.Text(
                    'RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      font: robotoFont,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NO.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      font: robotoFont,
                    ),
                  ),
                  pw.Text(
                    'DATE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      font: robotoFont,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      receiptNumber.toString(),
                      style: pw.TextStyle(fontSize: 12, font: robotoFont),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      _dateFormat.format(currentDate),
                      style: pw.TextStyle(fontSize: 12, font: robotoFont),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              _buildPdfDottedLineText(
                'Received with thanks from',
                tenant.name,
                robotoFont,
              ),
              pw.SizedBox(height: 8),
              _buildPdfDottedLineText(
                'The sum of shillings',
                amountInWords,
                robotoFont,
              ),
              pw.SizedBox(height: 8),
              _buildPdfDottedLineText(
                'Being payment of',
                'Rent: ${_currencyFormat.format(payment.rentPaid)} UGX\nWater: ${_currencyFormat.format(payment.waterBillPaid)} UGX',
                robotoFont,
              ),
              pw.SizedBox(height: 8),
              _buildPdfDottedLineText(
                'Amount in figures Shs.',
                '${_currencyFormat.format(totalPaid)} UGX',
                robotoFont,
              ),
              pw.SizedBox(height: 8),
              _buildPdfDottedLineText('Cash/Cheque No.', 'Cash', robotoFont),
              pw.SizedBox(height: 8),
              _buildPdfDottedLineText(
                'House No',
                tenant.houseNumber,
                robotoFont,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Your home, our haven, where memories are made',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: robotoFont,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Receipt_${tenant.name}_${receiptNumber}_${_dateFormat.format(currentDate)}.pdf',
    );
  }

  // Helper method for PDF dotted line text with bold labels
  pw.Widget _buildPdfDottedLineText(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold, // Bold styling for specified labels
            color: PdfColors.black,
            font: font,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.black,
                  font: font,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                '.' * 50,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey,
                  font: font,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPaid = (payment.rentPaid + payment.waterBillPaid).toInt();
    final amountInWords = _numberToWords(totalPaid);
    final currentDate =
        DateTime.now(); // Today's date for the UI (02:06 PM EAT, 19 Jun 2025)

    // Define theme colors
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return FutureBuilder<int>(
      future: _getNextReceiptNumber(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final receiptNumber = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Payment Receipt',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            backgroundColor: primaryBlue,
            elevation: 0,
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue, Colors.white, accentYellow],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BSB AND SONS RESIDENTIALS',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      'LOCATED SSEGUKU ALONG ENTEBBE ROAD TEL: 0782373727',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'RECEIPT',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NO.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      receiptNumber.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      _dateFormat.format(currentDate),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue, accentYellow],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDottedLineText(
                              'Received with thanks from',
                              tenant.name,
                              primaryBlue,
                            ),
                            const SizedBox(height: 16),
                            _buildDottedLineText(
                              'The sum of shillings',
                              amountInWords,
                              primaryBlue,
                            ),
                            const SizedBox(height: 16),
                            _buildDottedLineText(
                              'Being payment of',
                              'Rent: ${_currencyFormat.format(payment.rentPaid)} UGX\nWater: ${_currencyFormat.format(payment.waterBillPaid)} UGX',
                              primaryBlue,
                            ),
                            const SizedBox(height: 16),
                            _buildDottedLineText(
                              'Amount in figures Shs.',
                              '${_currencyFormat.format(totalPaid)} UGX',
                              primaryBlue,
                            ),
                            const SizedBox(height: 16),
                            _buildDottedLineText(
                              'Cash/Cheque No.',
                              'Cash',
                              primaryBlue,
                            ),
                            const SizedBox(height: 16),
                            _buildDottedLineText(
                              'House No',
                              tenant.houseNumber,
                              primaryBlue,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue, accentYellow],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Your home, our haven, where memories are made',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedButton(
                          context: context,
                          label: 'Back to Home',
                          color: accentYellow,
                          textColor: Colors.black87,
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildAnimatedButton(
                          context: context,
                          label: 'Download as PDF',
                          color: primaryBlue,
                          textColor: Colors.white,
                          onPressed: () => _downloadReceiptAsPdf(context),
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

  // Helper method to build animated buttons
  Widget _buildAnimatedButton({
    required BuildContext context,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onPressed,
          child: Container(
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for dotted line text with updated styling
  Widget _buildDottedLineText(String label, String value, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: accentColor,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '.' * 50,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  letterSpacing: 1,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.clip,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
