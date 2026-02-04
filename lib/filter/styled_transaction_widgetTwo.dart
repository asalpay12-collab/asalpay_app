import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:asalpay/providers/HomeSliderandTransaction.dart';
import '../services/api_urls.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
//import 'package:share/share.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; 
import 'dart:io'; 
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class StyledTransactionWidgetTwo extends StatefulWidget {
  final HomeTransactionModelRemittance transaction;

  const StyledTransactionWidgetTwo({
    super.key,
    required this.transaction,
  });

  @override
  _StyledTransactionWidgetTwoState createState() => _StyledTransactionWidgetTwoState();
}

class _StyledTransactionWidgetTwoState extends State<StyledTransactionWidgetTwo> {
  bool _isDescriptionVisible = false;

  void _toggleDescriptionVisibility() {
    setState(() {
      _isDescriptionVisible = !_isDescriptionVisible;
    });
  }
  
  
void _showTransactionDetailsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);

      return Center(
        child: Container(
          width: mediaQuery.size.width * 0.9,
          height: mediaQuery.size.height * 0.9,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Image.asset(
                'assets/asalicon.png',
                width: 75,
                height: 75,
              ),
              const SizedBox(height: 2),
              const Text(
                'Transfer is successful!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.transaction.amountFro} to ${widget.transaction.amountTo}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.transaction.holderName} (${widget.transaction.holderAccount})',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 1),
              ElevatedButton(
                onPressed: () {
                  _shareReceipt(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 1), 
                  child: Text('Share Receipt'),
                ),
              ),
              const SizedBox(height: 1), 
              Padding(
                padding: const EdgeInsets.only(top: 1), 
                child: DataTable(
                  columnSpacing: 12.0,
                  columns: const [
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                  ],
                  rows: [
                    DataRow(cells: [
                      const DataCell(Text('Transaction Date')),
                      DataCell(Text(
                        DateFormat('yyyy-MM-dd \t hh-mm-ss-a').format(DateTime.parse(widget.transaction.date).add(const Duration(hours: 3))),
                      )),

                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Sender Account')),
                      DataCell(Text(widget.transaction.senderAccount ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Sender Name')),
                      DataCell(Text(widget.transaction.senderName ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Amount From')),
                      DataCell(Text(widget.transaction.amountFro ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Amount To')),
                      DataCell(Text(widget.transaction.amountTo ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Holder Account')),
                      DataCell(Text(widget.transaction.holderAccount ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Holder Name')),
                      DataCell(Text(widget.transaction.holderName ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Provider Name')),
                      DataCell(Text(widget.transaction.providerName ?? '')),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


pdfWidgets.Widget _buildTransactionTable({required pdfWidgets.Font font}) {
  return pdfWidgets.Container(
    padding: const pdfWidgets.EdgeInsets.only(left: 60, top: 30),
    child: pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
       // pdfWidgets.Text('Transaction Details:', style: pdfWidgets.TextStyle(font: font, fontSize: 20, fontWeight: pdfWidgets.FontWeight.bold)),
       
      // _buildTransactionRow('Transaction Date', widget.transaction.date, font),

        _buildTransactionRow('Transaction Date', DateFormat('yyyy-MM-dd \t hh-mm-ss-a').format(DateTime.parse(widget.transaction.date).add(const Duration(hours: 3))), 
  font),
        _buildTransactionRow('Sender Account', widget.transaction.senderAccount ?? '', font),
        _buildTransactionRow('Sender Name', widget.transaction.senderName ?? '', font),
        _buildTransactionRow('Amount From', widget.transaction.amountFro ?? '', font),
        _buildTransactionRow('Amount To', widget.transaction.amountTo ?? '', font),
        _buildTransactionRow('Holder Account', widget.transaction.holderAccount ?? '', font),
        _buildTransactionRow('Holder Name', widget.transaction.holderName ?? '', font),
        _buildTransactionRow('Provider Name', widget.transaction.providerName ?? '', font),
      ],
    ),
  );
}

pdfWidgets.Widget _buildTransactionRow(String label, String value, pdfWidgets.Font font) {
  return pdfWidgets.Row(
    mainAxisAlignment: pdfWidgets.MainAxisAlignment.start,
    children: [
      pdfWidgets.Expanded(
        flex: 1,
        child: pdfWidgets.Text('$label:', style: pdfWidgets.TextStyle(font: font, fontSize: 16, fontWeight: pdfWidgets.FontWeight.bold, color: PdfColors.black,)),
      ),
      pdfWidgets.Expanded(
        flex: 2,
        child: pdfWidgets.Text(value, style: pdfWidgets.TextStyle(font: font, fontSize: 18, color: PdfColors.grey600, fontWeight: pdfWidgets.FontWeight.bold )),
      ),
    ],
  );
}



void _shareReceipt(BuildContext context) async {
  var status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    return;
  }

  final pdf = pdfWidgets.Document();

  final Uint8List backgroundImage = (await rootBundle.load('assets/paymentbackground2.png')).buffer.asUint8List();
  final Uint8List logoImage = (await rootBundle.load('assets/asalpaylogo2.png')).buffer.asUint8List();
  final ByteData fontData = await rootBundle.load("assets/OpenSans-Regular.ttf");
  final ttf = pdfWidgets.Font.ttf(fontData);

  pdf.addPage(
    pdfWidgets.Page(
      build: (pdfWidgets.Context context) {
        return pdfWidgets.Container(
          decoration: pdfWidgets.BoxDecoration(
            image: pdfWidgets.DecorationImage(
              image: pdfWidgets.MemoryImage(backgroundImage),
              fit: pdfWidgets.BoxFit.cover,
            ),
          ),
          child: pdfWidgets.Column(
            mainAxisAlignment: pdfWidgets.MainAxisAlignment.start,
            crossAxisAlignment: pdfWidgets.CrossAxisAlignment.center,
            children: [
              pdfWidgets.SizedBox(height: 20),
              pdfWidgets.Container(
                width: 135,
                height: 150,
                child: pdfWidgets.Image(pdfWidgets.MemoryImage(logoImage)),
              ),
              pdfWidgets.SizedBox(height: 10),
              pdfWidgets.Text(
                'Transfer is successful!',
                style: pdfWidgets.TextStyle(
                  font: ttf,
                  fontSize: 30,
                  fontWeight: pdfWidgets.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF02DF7E)
                ),
              ),
              pdfWidgets.Text(
                'Money transfer made easy',
                style: pdfWidgets.TextStyle(
                  font: ttf,
                  fontSize: 20,
                  fontWeight: pdfWidgets.FontWeight.bold,
                  color: PdfColor.fromHex('#808080')
                ),
              ),
              pdfWidgets.SizedBox(height: 20),
              pdfWidgets.Text(
                'Transaction Details:',
                style: pdfWidgets.TextStyle(
                  font: ttf,
                  fontSize: 20,
                  fontWeight: pdfWidgets.FontWeight.bold
                ),
              ),
              pdfWidgets.SizedBox(height: 10),
              _buildTransactionTable(font: ttf),
              pdfWidgets.SizedBox(height: 20),
              pdfWidgets.Text(
                'Thank you for choosing our platform',
                style: pdfWidgets.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  fontWeight: pdfWidgets.FontWeight.bold
                ),
              ),
              pdfWidgets.SizedBox(height: 5),
         
            ],
          ),
        );
      },
    ),
  );

  final pdfPath = await _savePdfToFile(pdf);
  if (pdfPath != null) {
    try {
      await Share.shareXFiles([XFile(pdfPath)], text: 'Transaction Receipt', subject: 'Transaction Receipt');
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  } else {
    print('Error saving PDF');
  }
}

Future<String?> _savePdfToFile(pdfWidgets.Document pdf) async {
  try {
    final List<Directory>? directories = await getExternalCacheDirectories();
    if (directories != null && directories.isNotEmpty) {
      final Directory cacheDir = directories.first;
      final uniqueFilename = 'transaction_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfPath = '${cacheDir.path}/$uniqueFilename';
      final File pdfFile = File(pdfPath);

      print('Saving PDF to: $pdfPath');
      await pdfFile.writeAsBytes(await pdf.save());
      print('PDF saved successfully.');
      return pdfPath;
    } else {
      print('Error: Cache directory not found.');
      return null;
    }
  } catch (e) {
    print('Error saving PDF: $e');
    return null;
  }
}



  @override
  Widget build(BuildContext context) {
  print('Sender Name in styledTransactions: ${widget.transaction.senderName}');
  print('Amount Fro: ${widget.transaction.amountFro}');
  print('Amount To: ${widget.transaction.amountTo}');
  

  bool isPositive = widget.transaction.tag.startsWith('in');
  Color textColor = isPositive ? const Color.fromARGB(255, 1, 185, 8) : const Color.fromARGB(255, 247, 2, 2);
  Color secondaryTextColor = const Color(0xFF401A66);

  // Format the date
  String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.transaction.date));

  return GestureDetector(
    //onTap: _toggleDescriptionVisibility,

    onTap: () {
      _showTransactionDetailsModal(context); 
    },

  child: Container(
      color: Colors.grey,
    child: Card(
     // color: secondryColor,  //secondry color
     surfaceTintColor: Colors.white,
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 13.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.transaction.image != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, left: 0),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(42),
                        child: (widget.transaction.image != null && widget.transaction.image!.isNotEmpty)
                        ? Image.network(
                            '${ApiUrls.BASE_URL}${widget.transaction.image}',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                          )
                        : Image.asset(
                            'assets/asalicon.png',
                            width: 42,
                            height: 42,
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                          ),


                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.transaction.holderName ?? '', 
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          Text(
                            widget.transaction.amountFro ?? '', 
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.transaction.providerName ?? '', 
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          Text(
                            widget.transaction.holderAccount ?? '', 
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(
              visible: _isDescriptionVisible,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16),
                      children: [
                        TextSpan(
                          text: '${widget.transaction.description} ',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 246, 242, 22),
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: widget.transaction.amount,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
  );
}
}
