// lib/features/profile/controllers/profile_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';
import 'package:murchin/features/auth/signin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Observable variables
  RxBool isLoading = false.obs;
  RxString name = ''.obs;
  RxString email = ''.obs;
  RxString photoUrl = ''.obs;
  Rx<File?> profileImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      name.value = await SharedPreferencesHelper.getUserName() ?? '';
      email.value = await SharedPreferencesHelper.getUserEmail() ?? '';
      photoUrl.value = await SharedPreferencesHelper.getUserPhoto() ?? '';
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Update profile image locally
  void updateProfileImage(File image) {
    profileImage.value = image;
    // In a real app, you would upload this to your server here
    // and then update the photoUrl with the new URL
  }

  // Update user profile
  Future<bool> updateProfile({
    String? newName,
    File? newImage,
  }) async {
    try {
      isLoading.value = true;

      if (newName != null && newName.isNotEmpty) {
        await SharedPreferencesHelper.saveUserName(newName);
        name.value = newName;
      }

      if (newImage != null) {
        // TODO: Upload image to your server and get URL
        // For now, just update local state
        profileImage.value = newImage;
        
        // In real app, after upload you would:
        // String uploadedUrl = await uploadImageToServer(newImage);
        // await SharedPreferencesHelper.saveUserPhoto(uploadedUrl);
        // photoUrl.value = uploadedUrl;
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Clear tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('refresh_token');

      // Clear last visited section
      await SharedPreferencesHelper.clearLastVisitedSection();

      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear observable values
      name.value = '';
      email.value = '';
      photoUrl.value = '';
      profileImage.value = null;

      print('✅ User logged out successfully');
      
      // Navigate to sign in screen and clear all previous routes
      Get.offAll(() => SignInPage());
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;

      // Get user ID from SharedPreferences
      String? userId = await SharedPreferencesHelper.getUserId();
      
      // If user ID not found, try to extract it from the token
      if (userId == null || userId.isEmpty) {
        print('⚠️ User ID not found in SharedPreferences, trying to extract from token...');
        final token = await SharedPreferencesHelper.getAccessToken();
        if (token != null && token.isNotEmpty) {
          // JWT token format: header.payload.signature
          // Payload contains user_id
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              // Decode payload (base64url)
              String payload = parts[1];
              // Add padding if needed
              String normalized = base64Url.normalize(payload);
              String decoded = utf8.decode(base64Url.decode(normalized));
              Map<String, dynamic> payloadData = jsonDecode(decoded);
              userId = payloadData['user_id']?.toString();
              print('✅ Extracted user ID from token: $userId');
            }
          } catch (e) {
            print('⚠️ Failed to extract user ID from token: $e');
          }
        }
      }
      
      if (userId == null || userId.isEmpty) {
        print('❌ User ID not found');
        Get.snackbar(
          'Error',
          'User ID not found. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      print('=====================');
      print('🗑️ DELETE ACCOUNT API');
      print('=====================');
      print('User ID: $userId');
      
      // Get access token
      final token = await SharedPreferencesHelper.getAccessToken();
      print('Token: ${token?.substring(0, 20)}...');
      
      // Build the URL
      final url = '${Urls.baseUrl}/api/accounts/userdelete/$userId/';
      print('URL: $url');
      print('Method: POST');
      print('Headers: Authorization: Bearer $token');
      print('=====================');

      // Call backend API to delete user account
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🗑️ Delete Account Response Status: ${response.statusCode}');
      print('🗑️ Delete Account Response Body: ${response.body}');
      print('=====================');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Account deleted successfully on server');

        // Clear all SharedPreferences data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('🗑️ Cleared SharedPreferences');

        // Try to delete Firebase user (may fail if not recently authenticated)
        final user = _auth.currentUser;
        if (user != null) {
          try {
            await user.delete();
            print('🗑️ Deleted Firebase user');
          } catch (firebaseError) {
            print('⚠️ Firebase delete failed (requires recent login): $firebaseError');
            print('⚠️ Signing out from Firebase instead');
          }
        }

        // Sign out from Firebase
        await _auth.signOut();
        print('🗑️ Signed out from Firebase');

        // Sign out from Google
        await _googleSignIn.signOut();
        print('🗑️ Signed out from Google');

        // Clear observable values
        name.value = '';
        email.value = '';
        photoUrl.value = '';
        profileImage.value = null;

        print('✅ Account deleted successfully');

        // Navigate to sign in screen and clear all previous routes
        Get.offAll(() => SignInPage());
      } else {
        print('❌ Failed to delete account: ${response.statusCode}');
        Get.snackbar(
          'Error',
          'Failed to delete account. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ Delete account error: $e');
      Get.snackbar(
        'Error',
        'Failed to delete account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await loadUserData();
  }
}