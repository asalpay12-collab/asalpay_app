import 'dart:io';
import 'dart:typed_data';

import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../providers/HomeSliderandTransaction.dart';
import 'Button.dart';
import 'Button2.dart';

/// Helper method to load a TTF font from assets for use in the PDF.
Future<pw.Font> fontFromAssetBundle(String path) async {
  final data = await rootBundle.load(path);
  return pw.Font.ttf(data);
}

class PaymentPage extends StatefulWidget {
  final String senderName;
  final String ReceiverName;
  final String senderAccount;
  final String ReceiverAccount;
  final String ReceiverLabel;
  final String? ReceiverLabelRec;
  final String ReceiverAmount;
  final String senderAmount;
  final String? AccountNumber;

  // New parameters
  final String? sourceOfFunds;
  final String? purposeOfTransfer;

  const PaymentPage(
    this.ReceiverAccount,
    this.ReceiverLabel, {
    super.key,
    required this.senderName,
    required this.ReceiverName,
    required this.senderAccount,
    required this.ReceiverAmount,
    required this.senderAmount,
    this.AccountNumber,
    this.ReceiverLabelRec,
    this.sourceOfFunds,
    this.purposeOfTransfer,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String formattedDateTime =
      DateFormat('yyyy-MM-dd \t  hh-mm-ss-a').format(DateTime.now());

  String formattedDateTime1 =
      DateFormat('yyyy-MM-dd \t  hh-mm-ss-a').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    double h = mediaQuery.size.height;
    double w = mediaQuery.size.width;

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            padding: EdgeInsets.only(
              top: constraints.maxWidth * 0.01 * 16,
              left: constraints.maxWidth * 0.01 * 4,
              right: constraints.maxWidth * 0.01 * 4,
            ),
            height: h,
            width: w,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage('assets/paymentbackground2.png'),
              ),
            ),
            child: Column(
              children: [
                // Logo circle
                Container(
                  width: constraints.maxWidth * 0.25,
                  height: constraints.maxWidth * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.7),
                      width: 3,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    backgroundImage: ExactAssetImage('assets/asalicon.png'),
                  ),
                ),
                Text(
                  "Success!",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.065,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  "Money transfer made easy",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.048,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  "Date:$formattedDateTime1",
                  style: TextStyle(
                    fontSize: constraints.maxWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: constraints.maxWidth * 0.04),
                // Transaction container
                Container(
                  height: constraints.maxWidth * 0.50,
                  width: constraints.maxWidth * 0.90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 2,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sender
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              left: constraints.maxWidth * 0.01 * 2,
                              top: constraints.maxWidth * 0.01 * 3,
                              bottom: constraints.maxWidth * 0.01 * 2,
                            ),
                            width: constraints.maxWidth * 0.060,
                            height: constraints.maxWidth * 0.060 * 1.6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: primaryColor,
                            ),
                            child: Icon(
                              Icons.done,
                              size: constraints.maxWidth * 0.063,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: constraints.maxWidth * 0.01),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.senderName,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                              SizedBox(height: constraints.maxWidth * 0.01),
                              Text(
                                "${widget.ReceiverLabel}: ${widget.senderAccount}",
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Amount: ${widget.senderAmount}",
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                      Divider(
                        thickness: 2,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      // Receiver
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              left: constraints.maxWidth * 0.01 * 2,
                              top: constraints.maxWidth * 0.01 * 3,
                              bottom: constraints.maxWidth * 0.01 * 2,
                            ),
                            width: constraints.maxWidth * 0.060,
                            height: constraints.maxWidth * 0.060 * 1.6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: primaryColor,
                            ),
                            child: Icon(
                              Icons.done,
                              size: constraints.maxWidth * 0.063,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: constraints.maxWidth * 0.01),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ReceiverName,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                              SizedBox(height: constraints.maxWidth * 0.01),
                              Text(
                                "${widget.ReceiverLabelRec}: ${widget.AccountNumber?.isNotEmpty == true ? widget.AccountNumber : widget.ReceiverAccount}",
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Amount: ${widget.ReceiverAmount}",
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: secondryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: constraints.maxWidth * 0.06),
                // Total
                Column(
                  children: [
                    Text(
                      "Total Amount You Sent",
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.050,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.ReceiverAmount,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.055,
                        color: secondryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mediaQuery.size.height * 0.06),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        printOrSaveAsPdf1();
                      },
                      child: const AppButton(
                        icon: Icons.share_sharp,
                        text: "Share!",
                      ),
                    ),
                    SizedBox(width: constraints.maxWidth * 0.25),
                    InkWell(
                      onTap: () {
                        printOrSaveAsPdf1();
                      },
                      child: const AppButton(
                        icon: Icons.print_sharp,
                        text: "Print!",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: constraints.maxWidth * 0.01 * 5),
                AppLargeButton(
                  text: "Done",
                  backgroundColor: Colors.white,
                  textColor: Colors.black,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> printOrSaveAsPdf1() async {
    // 1) Load your custom fonts for PDF
    final fontRegular = await fontFromAssetBundle('assets/OpenSans-Regular.ttf');
    final fontBold = await fontFromAssetBundle('assets/OpenSans-Bold.ttf');

    // 2) Create the PDF with embedded fonts
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    // 3) Load images from assets
    final Uint8List backgroundImage =
        (await rootBundle.load('assets/paymentbackground2.png'))
            .buffer
            .asUint8List();
    final Uint8List successImage1 =
        (await rootBundle.load('assets/asalpaylogo2.png'))
            .buffer
            .asUint8List();

    // 4) Build the PDF page with your existing code
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              image: pw.DecorationImage(
                image: pw.MemoryImage(backgroundImage),
                fit: pw.BoxFit.cover,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  width: 135,
                  height: 150,
                  child: pw.Image(pw.MemoryImage(successImage1)),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Success!',
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF02DF7E),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Money transfer made easy',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey,
                  ),
                ),
                // A bit of spacing
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(left: 80)),
                    pw.Text(
                      'Transaction Details:',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(left: 80)),
                    pw.Text(
                      'Date: $formattedDateTime',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  height: 2,
                  width: 320,
                  color: const PdfColor.fromInt(0xFF02DF7E),
                ),
                // Sender
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(left: 80, top: 30)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 10),
                        // Sender Name
                        pw.Row(
                          children: [
                            pw.Text(
                              "Sender Name:  ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.senderName,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 20),
                        // Sender Account
                        pw.Row(
                          children: [
                            pw.Text(
                              "Sender Account:  ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.senderAccount,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 20),
                        // Sent Amount
                        pw.Row(
                          children: [
                            pw.Text(
                              "Sent Amount: ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.senderAmount,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Optional fields
                        if (widget.sourceOfFunds != null && widget.sourceOfFunds!.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Text(
                                "Source of Funds: ",
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                widget.sourceOfFunds!,
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  color: PdfColors.grey,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        if (widget.purposeOfTransfer != null && widget.purposeOfTransfer!.isNotEmpty)
                          pw.Row(
                            children: [
                              pw.Text(
                                "Purpose of Transfer: ",
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                widget.purposeOfTransfer!,
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  color: PdfColors.grey,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  height: 2,
                  width: 320,
                  color: const PdfColor.fromInt(0xFF02DF7E),
                ),
                // Receiver
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.only(left: 80, top: 30)),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 10),
                        // Receiver Name
                        pw.Row(
                          children: [
                            pw.Text(
                              "Receiver Name:  ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.ReceiverName,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 20),
                        // Receiver Account
                        pw.Row(
                          children: [
                            pw.Text(
                              "Receiver Account:  ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.ReceiverAccount,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 20),
                        // Receiver Amount
                        pw.Row(
                          children: [
                            pw.Text(
                              "Receiver Amount: ",
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              widget.ReceiverAmount,
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.grey,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  height: 2,
                  width: 320,
                  color: const PdfColor.fromInt(0xFF02DF7E),
                ),
                pw.Text(
                  'Thank you for choosing our platform',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Total Amount You Sent',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  widget.ReceiverAmount,
                  style: pw.TextStyle(
                    fontSize: 25,
                    color: const PdfColor.fromInt(0xFF005653),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 5) Save PDF in memory
    final pdfBytes = await pdf.save();

    // 6) Rasterize the PDF's first page (to PNG or JPG)
    final Stream<PdfRaster> pageStream = Printing.raster(
      pdfBytes,
      pages: [0], // just the first page
      dpi: 144,   // resolution
    );

    final List<PdfRaster> pages = [];
    await for (final page in pageStream) {
      pages.add(page);
    }

    if (pages.isNotEmpty) {
      final PdfRaster firstPage = pages.first;

      // 7) Convert to a PNG or JPG
      final Uint8List imageBytes = await firstPage.toPng(); 
      // or: final Uint8List imageBytes = await firstPage.toJpg();

      // 8) Write the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/payment_details_$formattedDateTime.jpg';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // 9) Share the JPG
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Payment details (JPG)',
        subject: 'Payment details',
      );
    }
  }
}