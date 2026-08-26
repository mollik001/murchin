import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 15.0,
    this.textStyle,
    this.icon,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity, // Max width by default
      height: 45.h, // Fixed height
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (backgroundColor ?? AppColors.primary)
              : AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          // Reduced padding to fit text within 45.h height
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h, // Reduced vertical padding
          ),
        ),
        child: icon != null
            ? (text.trim().isEmpty
                ? Center(child: icon!)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon!,
                      SizedBox(width: 8.w),
                      Text(
                        text,
                        style: textStyle ??
                            AppTextStyles.bodySmall.copyWith(
                              fontSize: 14.sp, // Slightly smaller font
                              fontWeight: FontWeight.w600,
                              color: Colors.white
                            ),
                      ),
                    ],
                  ))
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: textStyle ??
                      AppTextStyles.bodySmall.copyWith(
                        fontSize: 14.sp, // Slightly smaller font
                        fontWeight: FontWeight.w600,
                        color: Colors.white
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}