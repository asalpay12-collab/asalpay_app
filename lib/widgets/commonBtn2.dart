import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

class CommonBtn extends StatefulWidget {
  final String txt;
  final VoidCallback onPressed;
  final double height;

  const CommonBtn({
    super.key,
    required this.txt,
    required this.onPressed,
    this.height = 75.0,
  });

  @override
  _CommonBtnState createState() => _CommonBtnState();
}

class _CommonBtnState extends State<CommonBtn> {
  @override
  Widget build(BuildContext context) {
    return InkWell(  // Wrap with InkWell for tap detection
      onTap: widget.onPressed,  // Use onPressed callback here
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(  // Use SizedBox to control height
        height: widget.height,  // Set height parameter here
        child: Card(
          elevation: 4,
          shadowColor: secondryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: secondryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Text(
                    widget.txt,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white),
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