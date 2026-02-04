import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';
class AppLargeButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final String text;
  final Function()? onTap;
  final bool? isBorder;
  const AppLargeButton({
    this.backgroundColor = Colors.black,
    this.textColor,
    this.onTap,
    this.isBorder =false,
    required this.text,
    super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 30,right: 30),
        height: 60,
        width: MediaQuery.of(context).size.width-60,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: secondryColor.withOpacity(0.5),
          ),
        ),
        child: Center(
          child: Text(
            text,style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          ),
        ),
      ),
    );
  }
}
