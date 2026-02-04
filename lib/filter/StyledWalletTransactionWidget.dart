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

class StyledWalletTransactionWidget extends StatelessWidget {
  final WalletTransactionModel transaction;

  const StyledWalletTransactionWidget({
    super.key,
    required this.transaction,
  });



  
  void _showTransactionDetailsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Getting screen size
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
                '${transaction.amountFrom} to ${transaction.amountTo}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '${transaction.receiverName} (${transaction.senderName})',
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
                  columnSpacing: 30.0,
                  columns: const [
                    DataColumn(label: Expanded(child: SizedBox.shrink())), 
                    DataColumn(label: SizedBox.shrink()), 
                  ],
                  rows: [
                    DataRow(cells: [
                      const DataCell(Text('Transaction Date')),
                      DataCell(Text(transaction.date)),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Sender Account')),
                      DataCell(Text(transaction.walletAccountsIdFro ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Sender Name')),
                      DataCell(Text(transaction.senderName ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Amount From')),
                      DataCell(Text(transaction.amountFrom ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Amount To')),
                      DataCell(Text(transaction.amountTo ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Receiver Account')),
                      DataCell(Text(transaction.walletAccountsIdTo ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Receiver Name')),
                      DataCell(Text(transaction.receiverName ?? '')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('WalletID')),
                      DataCell(Text(transaction.walletTransferId ?? '')),
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


//from here


void _shareReceipt(BuildContext context) async {
  var status = await Permission.storage.request();
  if (status != PermissionStatus.granted) {
    return;
  }

  final pdf = pdfWidgets.Document();

  final ByteData fontData = await rootBundle.load("assets/OpenSans-Regular.ttf");
  final ByteData fontDataView = ByteData.view(fontData.buffer);

  // Convert Uint8List to ByteData
  final ByteData fontByteData = ByteData.view(fontDataView.buffer);
  final ttf = pdfWidgets.Font.ttf(fontByteData);

  final ByteData imageData = await rootBundle.load('assets/asalicon.png');

  // Define a custom page size 
  final PdfPageFormat halfPageFormat = PdfPageFormat.a4.copyWith(
    height: PdfPageFormat.a4.height / 1.6, 
  );

  pdf.addPage(
    pdfWidgets.Page(
      pageFormat: halfPageFormat,
      build: (pdfWidgets.Context context) {
        return pdfWidgets.Column(
          mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
          crossAxisAlignment: pdfWidgets.CrossAxisAlignment.center,
          children: [
            
            pdfWidgets.Image(pdfWidgets.MemoryImage(imageData.buffer.asUint8List()), width: 75, height: 75),
            pdfWidgets.SizedBox(height: 5), 
            pdfWidgets.Text(
              'Transfer is successful!',
              style: pdfWidgets.TextStyle(fontSize: 16, font: ttf),
            ),
            pdfWidgets.SizedBox(height: 5),
            pdfWidgets.Text(
              '${transaction.amountFrom} to ${transaction.amountTo}',
              style: pdfWidgets.TextStyle(fontSize: 14, font: ttf),
            ),
            pdfWidgets.SizedBox(height: 10),
            pdfWidgets.Text(
              '${transaction.receiverName} (${transaction.walletAccountsIdTo})',
              style: pdfWidgets.TextStyle(fontSize: 14, font: ttf),
            ),
            pdfWidgets.SizedBox(height: 10),
            pdfWidgets.Text(
              'Transaction Details',
              style: pdfWidgets.TextStyle(fontSize: 16, fontWeight: pdfWidgets.FontWeight.bold, font: ttf),
            ),
            pdfWidgets.SizedBox(height: 10),
            _buildTransactionTable(font: ttf), 
            pdfWidgets.SizedBox(height: 20), 
          ],
        );
      },
    ),
  );

  final pdfPath = await _savePdfToFile(pdf);
  if (pdfPath != null) {
    try {
      final file = File(pdfPath);
      final uri = Uri.file(pdfPath);

      print('PDF path: $pdfPath');
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: 'Transaction Receipt',
        subject: 'Transaction Receipt',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  } else {
    print('Error saving PDF');
  }
}

pdfWidgets.Widget _buildTransactionTable({required pdfWidgets.Font font}) {
  return pdfWidgets.Table(
    border: pdfWidgets.TableBorder.all(),
    children: [
      _buildTableRow('Transaction Date', transaction.date, font: font),
      _buildTableRow('Sender Account', transaction.walletAccountsIdFro ?? '', font: font),
      _buildTableRow('Sender Name', transaction.senderName ?? '', font: font),
      _buildTableRow('Amount From', transaction.amountFrom ?? '', font: font),
      _buildTableRow('Amount To', transaction.amountTo ?? '', font: font),
      _buildTableRow('Holder Account', transaction.walletAccountsIdTo ?? '', font: font),
      _buildTableRow('Holder Name', transaction.receiverName ?? '', font: font),
      //_buildTableRow('Provider Name', transaction.providerName ?? '', font: font),
    ],
  );
}

pdfWidgets.TableRow _buildTableRow(String label, String value, {required pdfWidgets.Font font}) {
  return pdfWidgets.TableRow(
    children: [
      pdfWidgets.Container(
        alignment: pdfWidgets.Alignment.centerLeft,
        padding: const pdfWidgets.EdgeInsets.all(5),
        child: pdfWidgets.Text(label, style: pdfWidgets.TextStyle(font: font)),
      ),
      pdfWidgets.Container(
        alignment: pdfWidgets.Alignment.centerLeft,
        padding: const pdfWidgets.EdgeInsets.all(5),
        child: pdfWidgets.Text(value, style: pdfWidgets.TextStyle(font: font)),
      ),
    ],
  );
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
  
  String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(transaction.date));

  return GestureDetector(
    onTap: () {
      _showTransactionDetailsModal(context);
    },
    child: Container(
      color: Colors.grey[200], 
      child: Card(
        color: Colors.white, 
        elevation: 0, 
        margin: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 13.0),
          child: Row(
            children: [
              
              if (transaction.image != null && transaction.image!.isNotEmpty)
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
                      child: Image.network(
                        '${ApiUrls.BASE_URL}${transaction.image}',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                        alignment: Alignment.topLeft,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10, left: 0),
                  child: Image.asset(
                    'assets/asalicon.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
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
                          transaction.receiverName ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction.amountFrom ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          transaction.amountTo ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5), 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        
                         Text(
                          transaction.senderName ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),

                      ],
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