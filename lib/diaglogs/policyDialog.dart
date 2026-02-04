import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logo_n_spinner/logo_n_spinner.dart';

import '../constants/Constant.dart';

class PolicyDialog extends StatelessWidget {
  PolicyDialog(
      {required Key key,
      required this.btnName,
      this.radius = 8,
      required this.mdFileName})
      : assert(mdFileName.contains('.md'),
            'The file must contain the .md extension'),
        super(key: key);

  final double radius;
  final String mdFileName;
  final String btnName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 150)).then((value) {
                return rootBundle
                    .loadString('TermsofConAndPrivacyPl/$mdFileName');
              }),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Markdown(
                    data: snapshot.data!,
                  );
                }
                return const Center(
                  child:
                  // CircularProgressIndicator(),
                  LogoandSpinner(
                    imageAssets:
                    'assets/asalicon.png',
                    reverse: true,
                    arcColor: primaryColor,
                    spinSpeed: Duration(
                        milliseconds: 500),
                  )
                );
              },
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: secondryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(radius),
                bottomRight: Radius.circular(radius),
              )),
            ),
            // onPressed: () => Navigator.of(context).pop(),
            onPressed: () {
              if (btnName == "I AGREE") {
                Navigator.of(context).pop();
              }else if(btnName == "Cancel"){
                Navigator.of(context).pop();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(radius),
                  bottomRight: Radius.circular(radius),
                ),
              ),
              alignment: Alignment.center,
              height: 50,
              width: double.infinity,
              child: Text(
                btnName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
