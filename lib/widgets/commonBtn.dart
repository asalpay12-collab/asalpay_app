import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

class CommonBtn extends StatelessWidget {
  final String txt;

  const CommonBtn({
    super.key,
    required this.txt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: secondryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: secondryColor,
        ),
        // Expands to parent constraints (e.g., height from SizedBox)
        child: Center(
          child: Text(
            txt,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
