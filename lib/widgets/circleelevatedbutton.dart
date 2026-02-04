import 'package:asalpay/constants/Constant.dart';
import 'package:flutter/material.dart';

class CircleElevatedButton extends StatefulWidget {
  final AssetImage icn;
  final VoidCallback onPressed;
  final String txt;
  const CircleElevatedButton({
    super.key,
    required this.icn,
    required this.onPressed,
    required this.txt,
  });
  @override
  State<CircleElevatedButton> createState() => _CircleElevatedButtonState();
}
class _CircleElevatedButtonState extends State<CircleElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: widget.onPressed,
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(const CircleBorder()),
                  padding: WidgetStateProperty.all(const EdgeInsets.all(20)),
                  backgroundColor: WidgetStateProperty.all(primaryColor),
                  // <-- Button color
                  overlayColor:
                      WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return secondryColor;
                    return null; // <-- Splash color
                    }
                    return null;
                  }),
                ), //accessing onpress
                child: Image(image: widget.icn, color: Colors.white , width: 45),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: Text(
                  widget.txt,
                  style: const TextStyle(
                    fontSize: 15,
                    color: secondryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
