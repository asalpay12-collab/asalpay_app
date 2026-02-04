import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

class CommonTextView extends StatefulWidget {
  final String hintxt;
  final IconData? icn;
  final TextEditingController? ctr;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>?  onChanged;
  const CommonTextView({
    super.key,
    required this.hintxt,
    this.icn,
    this.onChanged,
    this.validator,
    this.ctr,
  });

  @override
  _CommonTextViewState createState() => _CommonTextViewState();
}

class _CommonTextViewState extends State<CommonTextView> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // enabled: false,
      readOnly: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: widget.ctr,
      validator: widget.validator,

      style: const TextStyle(
        color: secondryColor,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: widget.hintxt,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: secondryColor,
            width: 1.5,
          ),
        ),
        prefixIcon: InkWell(
          // child: Icon(widget.icn, color: primaryColor.withOpacity(0.7)),
          child: Icon(widget.icn, color: secondryColor.withOpacity(0.7)),
        ),
        contentPadding: const EdgeInsets.only(top: 16),
      ),
    );
  }
}
