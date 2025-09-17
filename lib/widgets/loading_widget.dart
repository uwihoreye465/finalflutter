import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../utils/constants.dart';

class LoadingWidget extends StatelessWidget {
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.color,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: color ?? AppColors.primaryColor,
      size: size,
    );
  }
}