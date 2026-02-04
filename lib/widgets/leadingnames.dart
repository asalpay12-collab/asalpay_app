
import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

class LeadingNames extends StatefulWidget {
  final String leadingName;
  const LeadingNames(
      {super.key,
        required this.leadingName});
  @override
  State<LeadingNames> createState() => _LeadingNamesState();
}
class _LeadingNamesState extends State<LeadingNames> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const SizedBox(
            width: double.infinity,
          ),
          Text(widget.leadingName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
           color:secondryColor,
          ),

          ),
        ],
      ),
    );
  }
}
