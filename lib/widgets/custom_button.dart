import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final Widget? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w600,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        elevation: 2,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
    );
  }
}