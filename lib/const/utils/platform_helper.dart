import 'dart:io';

class PlatformHelper {
  /// Whether authentication (login/sign up) should be enforced.
  /// On Android: true (keeps existing authentication flow).
  /// On iOS: false (App Store guideline compliance, no sign-in gate).
  static bool get isAuthEnabled => Platform.isAndroid;

  /// Whether user bookmark/save system should be active in UI.
  /// On Android: true (keeps saved events & bookmark icons).
  /// On iOS: false (removes bookmark icon and saved screen).
  static bool get isBookmarkEnabled => Platform.isAndroid;

  /// Whether profile management tab should be active.
  /// On Android: true (keeps profile tab & settings).
  /// On iOS: false (removes profile tab from bottom bar).
  static bool get isProfileEnabled => Platform.isAndroid;
}

