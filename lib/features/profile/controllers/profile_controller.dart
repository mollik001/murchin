// lib/features/profile/controllers/profile_controller.dart
import 'dart:io';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:murchin/const/service/shared_preference_helper.dart';

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
      
      // Clear all SharedPreferences data
     // await SharedPreferencesHelper.clearAll();
      
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
      
      // TODO: Call your backend API to delete user account
      // await http.delete(
      //   Uri.parse('${Urls.baseUrl}/api/accounts/delete/'),
      //   headers: {
      //     'Authorization': 'Bearer ${await SharedPreferencesHelper.getAccessToken()}',
      //   },
      // );
      
      // Clear all SharedPreferences data
      //await SharedPreferencesHelper.clearAll();
      
      // Delete Firebase user
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Clear observable values
      name.value = '';
      email.value = '';
      photoUrl.value = '';
      profileImage.value = null;
      
      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Delete account error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await loadUserData();
  }
}