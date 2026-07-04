// lib/features/profile/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:murcin/const/service/shared_preference_helper.dart';
import 'package:murcin/const/theme/app_color.dart';
import 'package:murcin/const/theme/app_theme.dart';
import 'package:murcin/const/widgets/custom_appbar.dart';
import 'package:murcin/const/widgets/custom_button.dart';
import 'package:murcin/features/auth/signin_screen.dart';
import 'package:murcin/features/market/navbar/market_navbar_screen.dart';
import 'package:murcin/features/profile/controllers/profile_controller.dart';
import 'package:murcin/features/profile/screens/terms_screen.dart';
import 'package:murcin/features/selection/selection_screen.dart';
import 'package:murcin/features/sports/navbar/sports_navbar_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Track popup visibility
  bool _showPopup = false;
  final GlobalKey _threeDotsKey = GlobalKey();
  final ImagePicker _picker = ImagePicker(); // Declare at class level

  // Edit profile variables
  String _name = '';
  String _email = '';
  File? _selectedProfileImage; // Store selected image at class level
  String? _profileImageUrl; // Store profile image URL from SharedPreferences

  // COMMENTED OUT - Toggle between Sportsbook and Market
  // bool _isSportsbookMode = true;

  final ProfileController _profileController = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadModePreference(); // COMMENTED OUT
  }

  // COMMENTED OUT - Mode preference loading
  // Future<void> _loadModePreference() async {
  //   // First check lastVisitedSection (set during selection)
  //   String? lastSection = await SharedPreferencesHelper.getLastVisitedSection();

  //   bool isSportsbook;
  //   if (lastSection != null) {
  //     // Use lastVisitedSection to determine mode
  //     isSportsbook = lastSection == 'sports';
  //   } else {
  //     // Fall back to sportsbookMode preference
  //     bool? mode = await SharedPreferencesHelper.getSportsbookMode();
  //     isSportsbook = mode ?? true;
  //   }

  //   setState(() {
  //     _isSportsbookMode = isSportsbook;
  //   });
  // }

  // COMMENTED OUT - Toggle mode function
  // Future<void> _toggleMode(bool value) async {
  //   setState(() {
  //     _isSportsbookMode = value;
  //   });
  //   await SharedPreferencesHelper.saveSportsbookMode(value);

  //   // Also save last visited section
  //   await SharedPreferencesHelper.saveLastVisitedSection(value ? 'sports' : 'market');

  //   // Navigate to the other screen based on mode
  //   if (value) {
  //     Get.offAll(() => SportsNavbarScreen());
  //   } else {
  //     Get.offAll(() => MarketNavbarScreen());
  //   }
  // }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    String? name = await SharedPreferencesHelper.getUserName();
    String? email = await SharedPreferencesHelper.getUserEmail();
    String? photoUrl = await SharedPreferencesHelper.getUserPhoto();
    
    setState(() {
      _name = name ?? 'User';
      _email = email ?? 'user@example.com';
      _profileImageUrl = photoUrl;
    });
  }

  // Function to show three dots popup
  void _showThreeDotsPopup() {
    final RenderBox renderBox = _threeDotsKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 160.w, // Adjust horizontal position
        offset.dy + 40.h, // Position below three dots
        offset.dx,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
          width: 1.w,
        ),
      ),
      color: Colors.white.withOpacity(0.95), // Transparent background
      items: [
        // Commented out Edit option
        // PopupMenuItem(
        //   height: 40.h,
        //   value: 'edit',
        //   child: Row(
        //     children: [
        //       Image.asset(
        //         'assets/icons/edit.png', // Edit icon asset
        //         width: 20.w,
        //         height: 20.h,
        //         fit: BoxFit.contain,
        //       ),
        //       SizedBox(width: 12.w),
        //       Text(
        //         'Edit',
        //         style: AppTextStyles.bodyMedium?.copyWith(
        //           color: Colors.black,
        //           fontWeight: FontWeight.w600,
        //           fontSize: 14.sp,
        //         ),

        //       ),
        //     ],
        //   ),
        // ),
        PopupMenuItem(
          height: 40.h,
          value: 'delete',
          child: Row(
            children: [
              Image.asset(
                'assets/icons/delete.png', // Delete icon asset
                width: 20.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12.w),
              Text(
                'Delete account',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handlePopupSelection(value);
      }
    });
  }

  // Handle popup selection
  void _handlePopupSelection(String value) {
    if (value == 'edit') {
      // Show edit profile popup
      _showEditProfileDialog();
    } else if (value == 'delete') {
      // Show delete account warning
      _showDeleteAccountDialog();
    }
  }

  void _showEditProfileDialog() {
  TextEditingController nameController = TextEditingController(text: _name);
  File? _tempSelectedImage = _selectedProfileImage; // Use temp variable for dialog
  
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              constraints: BoxConstraints(
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Edit Profile',
                            style: AppTextStyles.headlineMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20.w,
                              color: AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          // Circular Profile Picture
                          GestureDetector(
                            onTap: () async {
                              // Show options to pick image
                              await _showImagePickerOptions(context, (File? image) {
                                if (image != null) {
                                  setDialogState(() {
                                    _tempSelectedImage = image;
                                  });
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 100.w,
                                  height: 100.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _tempSelectedImage != null
                                        ? Image.file(
                                            _tempSelectedImage!,
                                            fit: BoxFit.cover,
                                            width: 100.w,
                                            height: 100.w,
                                          )
                                        : _profileImageUrl != null
                                            ? Image.network(
                                                _profileImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/dp.png',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                'assets/images/dp.png',
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                ),
                                // Edit Icon overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.w,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16.w,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          GestureDetector(
                            onTap: () async {
                              // Handle image change
                              await _showImagePickerOptions(context, (File? image) {
                                if (image != null) {
                                  setDialogState(() {
                                    _tempSelectedImage = image;
                                  });
                                }
                              });
                            },
                            child: Text(
                              'Change photo',
                              style: AppTextStyles.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Name Input Field
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Name',
                        style: AppTextStyles.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
                          width: 1.w,
                        ),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: AppTextStyles.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          border: InputBorder.none,
                          hintText: 'Enter your name',
                          hintStyle: AppTextStyles.bodyMedium?.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        // Update profile information
                        if (nameController.text.trim().isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please enter your name',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        
                        // Save to SharedPreferences
                        await SharedPreferencesHelper.saveUserName(nameController.text.trim());
                        
                        // Update profile image if changed
                        if (_tempSelectedImage != null) {
                          // In a real app, you'd upload this to your server
                          // For now, we'll just update the local state
                         // _profileController.updateProfileImage(_tempSelectedImage!);
                        }
                        
                        // Update the main state
                        setState(() {
                          _name = nameController.text.trim();
                          _selectedProfileImage = _tempSelectedImage;
                        });
                        
                        Navigator.of(context).pop();
                        
                        Get.snackbar(
                          'Profile Updated',
                          'Your profile has been updated successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primary.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      },
                      backgroundColor: AppColors.primary,
                      borderRadius: 12.r,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  
  // Function to show image picker options
  Future<void> _showImagePickerOptions(BuildContext context, Function(File?) onImageSelected) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Choose Profile Photo',
                style: AppTextStyles.headlineSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera Option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (image != null) {
                          onImageSelected(File(image.path));
                        }
                      } catch (e) {
                        print('Error picking image: $e');
                        Get.snackbar(
                          'Error',
                          'Failed to pick image. Please check permissions.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 30.w,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Camera',
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Gallery Option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (image != null) {
                          onImageSelected(File(image.path));
                        }
                      } catch (e) {
                        print('Error picking image: $e');
                        Get.snackbar(
                          'Error',
                          'Failed to pick image. Please check permissions.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            size: 30.w,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Gallery',
                          style: AppTextStyles.bodyMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to show delete account warning dialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: Container(
            constraints: BoxConstraints(minWidth: 280.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 32.w,
                    color: const Color(0xFFF44336),
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Title
                Text(
                  'Delete Account?',
                  style: AppTextStyles.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Message
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: AppTextStyles.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24.h),
                
                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Delete Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Close the dialog first before deleting account
                          Navigator.of(context).pop();
                          // Call delete account API
                          await _profileController.deleteAccount();
                        },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Delete',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to show logout warning dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: Container(
            constraints: BoxConstraints(minWidth: 280.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 32.w,
                    color: AppColors.primary,
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Title
                Text(
                  'Logout?',
                  style: AppTextStyles.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Message
                Text(
                  'Are you sure you want to logout from your account?',
                  style: AppTextStyles.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24.h),
                
                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Logout Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Handle logout logic here
                          await _profileController.logout();
                          Navigator.of(context).pop();
                          Get.offAll(() => SignInPage());
                          Get.snackbar(
                            'Logged out',
                            'You have been successfully logged out',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary.withOpacity(0.9),
                            colorText: Colors.white,
                          );
                        },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Logout',
                              style: AppTextStyles.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(imageAsset: 'assets/images/name_2.png'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              
              // Title
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile',
                  style: AppTextStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              
              SizedBox(height: 14.h),
              
              // Profile Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    // Circular DP
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _selectedProfileImage != null
                            ? Image.file(
                                _selectedProfileImage!,
                                fit: BoxFit.cover,
                                width: 60.w,
                                height: 60.w,
                              )
                            : _profileImageUrl != null
                                ? Image.network(
                                    _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/dp.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/dp.png',
                                    fit: BoxFit.cover,
                                  ),
                      ),
                    ),
                    
                    SizedBox(width: 4.w),
                    
                    // Name and Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bold Name
                          Text(
                            _name,
                            style: AppTextStyles.headlineSmall?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                          
                          SizedBox(height: 4.h),
                          
                          // Grey Email
                          Text(
                            _email,
                            style: AppTextStyles.bodyMedium?.copyWith(
                              color: const Color(0xff848484),
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Three dots at far right - with key for positioning
                    GestureDetector(
                      key: _threeDotsKey,
                      onTap: _showThreeDotsPopup,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.more_horiz,
                          size: 24.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),

              // COMMENTED OUT - Mode Toggle (Sportsbook vs Market)
              // Container(
              //   width: double.infinity,
              //   padding: EdgeInsets.all(16.w),
              //   decoration: BoxDecoration(
              //     color: Colors.transparent,
              //     borderRadius: BorderRadius.circular(12.r),
              //     border: Border.all(
              //       color: AppColors.gray300 ?? const Color(0xFFE6E6E6),
              //       width: 1.w,
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       // Prediction Market Label
              //       Expanded(
              //         child: GestureDetector(
              //           onTap: () => _toggleMode(false),
              //           child: Container(
              //             padding: EdgeInsets.symmetric(vertical: 10.h),
              //             decoration: BoxDecoration(
              //               color: !_isSportsbookMode ? AppColors.primary : Colors.transparent,
              //               borderRadius: BorderRadius.circular(8.r),
              //             ),
              //             child: Center(
              //               child: Text(
              //                 'Prediction Market',
              //                 style: AppTextStyles.bodyMedium?.copyWith(
              //                   color: !_isSportsbookMode ? Colors.white : AppColors.gray600,
              //                   fontWeight: FontWeight.w600,
              //                   fontSize: 14.sp,
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),

              //       // Sportsbook Label
              //       Expanded(
              //         child: GestureDetector(
              //           onTap: () => _toggleMode(true),
              //           child: Container(
              //             padding: EdgeInsets.symmetric(vertical: 10.h),
              //             decoration: BoxDecoration(
              //               color: _isSportsbookMode ? AppColors.primary : Colors.transparent,
              //               borderRadius: BorderRadius.circular(8.r),
              //             ),
              //             child: Center(
              //               child: Text(
              //                 'Sportsbook',
              //                 style: AppTextStyles.bodyMedium?.copyWith(
              //                   color: _isSportsbookMode ? Colors.white : AppColors.gray600,
              //                   fontWeight: FontWeight.w600,
              //                   fontSize: 14.sp,
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              SizedBox(height: 32.h),

              // Terms and Privacy Policy Option
              GestureDetector(
                onTap: () {
                  // Navigate to terms and privacy policy screen
                  print('Terms and Privacy Policy tapped');
                  Get.to(() => const TermsPrivacyScreen());
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    children: [
                      // Prefix Icon
                      Image.asset(
                        'assets/icons/terms.png',
                        width: 20.w,
                        height: 20.h,
                        fit: BoxFit.contain,
                      ),
                      
                      SizedBox(width: 16.w),
                      
                      // Title
                      Expanded(
                        child: Text(
                          'Terms and Privacy Policy',
                          style: AppTextStyles.bodyLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      
                      // iOS right arrow
                      Icon(
                        Icons.chevron_right,
                        size: 26.w,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Divider
              Divider(
                color: AppColors.gray200 ?? const Color(0xFFEEEEEE),
                height: 1.h,
                thickness: 1.w,
              ),
              
              // Logout Option
              GestureDetector(
                onTap: () {
                  // Show logout warning dialog
                  _showLogoutDialog(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    children: [
                      // Prefix Logout Icon
                      Image.asset(
                        'assets/icons/logout.png',
                        width: 20.w,
                        height: 20.h,
                        fit: BoxFit.contain,
                      ),
                      
                      SizedBox(width: 16.w),
                      
                      // Title
                      Expanded(
                        child: Text(
                          'Log out',
                          style: AppTextStyles.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}