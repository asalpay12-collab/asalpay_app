import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AllformFields extends StatefulWidget {
  final String hintxt;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final IconData? icn;
  final TextEditingController ctr; // Made this required and non-nullable
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FormFieldSetter<String>? onsave;
  final FormFieldValidator<String>? validator;
  final Function()? onTap;

  const AllformFields({
    super.key,
    required this.hintxt,
    required this.ctr, // Use required for named parameters
    this.icn,
    this.textInputAction,
    this.focusNode,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.onsave,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.onTap,
    this.onEditingComplete,
  });

  @override
  State<AllformFields> createState() => _AllformFieldsState();
}

class _AllformFieldsState extends State<AllformFields> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: widget.keyboardType,
      controller: widget.ctr,
      onSaved: widget.onsave,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
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
          onTap: widget.onTap,
          child: Icon(widget.icn, color: primaryColor),
        ),
        hintText: widget.hintxt,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyLarge!
            .copyWith(color: Colors.black45),
        contentPadding: const EdgeInsets.only(top: 16),
      ),
    );
  }
}