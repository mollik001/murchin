import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/shared_preference_helper.dart';
import 'package:murchin/features/navbar/navbar_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  RxBool isLoading = false.obs;
  RxBool loginSuccess = false.obs;

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      loginSuccess.value = false;

      /// Force account picker
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ Google Sign In Cancelled");
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return;

      final firebaseIdToken = await user.getIdToken();

      final url = Uri.parse(
        'https://5108-2401-f40-1503-7-b817-4727-d299-219d.ngrok-free.app/api/accounts/google/auth/',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'credential': firebaseIdToken,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        /// ✅ SAVE USING HELPER (CORRECT KEYS)
        await SharedPreferencesHelper.saveAccessToken(data['token'] ?? '');
        await SharedPreferencesHelper.saveRefreshToken(data['refresh_token'] ?? '');

        if (data['user'] != null) {
          await SharedPreferencesHelper.saveUserEmail(data['user']['email'] ?? '');
          await SharedPreferencesHelper.saveUserName(data['user']['first_name'] ?? '');
          await SharedPreferencesHelper.saveUserId(data['user']['id'].toString());
        }

        await SharedPreferencesHelper.saveUserPhoto(user.photoURL ?? '');

        loginSuccess.value = true;

        Get.offAll(() => CustomNavbar());

        print("✅ Login + Save Success");
      } else {
        print("❌ Backend Login Failed");
      }
    } catch (e) {
      print("❌ Google Sign In Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
