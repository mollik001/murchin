// lib/widgets/custom_appbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String imageAsset;
  final double imageWidth;
  final double imageHeight;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool centerTitle;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.imageAsset,
    this.imageWidth = 140.0,
    this.imageHeight = 38.0,
    this.backgroundColor = Colors.transparent,
    this.padding,
    this.centerTitle = true,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove back button
      centerTitle: centerTitle,
      title: Image.asset(
        imageAsset,
        width: imageWidth.w,
        height: imageHeight.h,
        fit: BoxFit.contain,
      ),
      actions: actions,
    );
  }
}