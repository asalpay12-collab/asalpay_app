import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextfromField extends StatefulWidget {
  final String txt;
  // final String labeltex;
  final IconData icn;
  final TextEditingController? ctr;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function()? onTap;
  final String? Function(String?)? onsave;

  const CommonTextfromField({
    super.key,
    required this.txt,
    // required this.labeltex,
    required this.icn,
    this.ctr,
    this.inputFormatters,
    this.validator,
    this.keyboardType,
    this.onsave,
    this.onTap,
    this.maxLines,
    this.maxLength,
  });

  @override
  _CommonTextfromFieldState createState() => _CommonTextfromFieldState();
}

class _CommonTextfromFieldState extends State<CommonTextfromField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: secondryColor.withOpacity(0.1),
        // color: Colors.grey[200],
      ),

      child: TextFormField(
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onSaved: widget.onsave,
        autovalidateMode: AutovalidateMode.always,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(fontSize: 16),
        controller: widget.ctr,
        decoration: InputDecoration(
          prefixIcon: InkWell(
            onTap: widget.onTap,
            child: Icon(
              widget.icn,
              // color: secondryColor,
              color: primaryColor,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 16),
          hintText: widget.txt,
          // labelText: widget.labeltex,
          hintStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.black45),
        ),
      ),
    );
  }
}
