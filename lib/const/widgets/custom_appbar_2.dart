// lib/widgets/transparent_appbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppbar2 extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color titleColor;
  final TextStyle? titleStyle;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final double? toolbarHeight;

  const CustomAppbar2({
    Key? key,
    required this.title,
    this.titleColor = Colors.black,
    this.titleStyle,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.toolbarHeight,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
      ),
      leading: leading ?? _buildIOSBackButton(context),
      actions: actions,
    );
  }

  // iOS-style back button (arrow without container)
  Widget _buildIOSBackButton(BuildContext context) {
    return IconButton(
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.arrow_back_ios,
        size: 20.w,
        color: Colors.black,
      ),
      padding: EdgeInsets.only(left: 16.w),
      constraints: const BoxConstraints(),
      splashRadius: 20.w,
    );
  }
}