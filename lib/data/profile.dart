import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_proxy.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.avatarIndex,
    required this.avatarBase64,
    this.phoneNumber,
    this.isLoggedIn = false,
  });

  final String name;
  final int avatarIndex;
  final String? avatarBase64;
  final String? phoneNumber;
  final bool isLoggedIn;

  UserProfile copyWith({
    String? name,
    int? avatarIndex,
    String? avatarBase64,
    String? phoneNumber,
    bool? isLoggedIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  static UserProfile defaultProfile() {
    return const UserProfile(name: '星知小探险家', avatarIndex: 0, avatarBase64: null, isLoggedIn: false);
  }
}

const avatarColors = [
  Color(0xFFFFD166),
  Color(0xFFBFD7FF),
  Color(0xFFB8F1E0),
  Color(0xFFFFC857),
  Color(0xFFF4A261),
  Color(0xFF9BDEAC),
];

const avatarIcons = [
  Icons.star_rounded,
  Icons.explore_rounded,
  Icons.lightbulb_rounded,
  Icons.sports_basketball_rounded,
  Icons.pets_rounded,
  Icons.rocket_launch_rounded,
];

Widget buildAvatar(int index, {double size = 36, String? base64Image}) {
  if (base64Image != null && base64Image.isNotEmpty) {
    final bytes = base64Decode(base64Image);
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
    );
  }
  final safeIndex = index % avatarColors.length;
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: avatarColors[safeIndex],
    child: Icon(avatarIcons[safeIndex], color: Colors.white, size: size * 0.55),
  );
}

class ProfileStore {
  static const _nameKey = 'profile_name';
  static const _avatarKey = 'profile_avatar';
  static const _avatarImageKey = 'profile_avatar_image';
  static const _phoneKey = 'profile_phone';
  static const _isLoggedInKey = 'profile_is_logged_in';
  static const _tokenKey = 'profile_auth_token';

  static final ValueNotifier<UserProfile> profile =
      ValueNotifier<UserProfile>(UserProfile.defaultProfile());

  static String? _authToken;
  static String? get authToken => _authToken;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey);
      final avatarIndex = prefs.getInt(_avatarKey);
      final avatarImage = prefs.getString(_avatarImageKey);
      final phone = prefs.getString(_phoneKey);
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      _authToken = prefs.getString(_tokenKey);
      profile.value = profile.value.copyWith(
        name: name,
        avatarIndex: avatarIndex,
        avatarBase64: avatarImage,
        phoneNumber: phone,
        isLoggedIn: isLoggedIn,
      );
      if (_authToken != null && _authToken!.isNotEmpty) {
        await _fetchUserMe();
      }
    } on MissingPluginException {
      profile.value = UserProfile.defaultProfile();
    }
  }

  static Future<void> _fetchUserMe() async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 401) {
        _authToken = null;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
        } catch (_) {}
        profile.value = profile.value.copyWith(isLoggedIn: false);
        return;
      }
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (data == null) return;
      final next = profile.value.copyWith(
        phoneNumber: data['phoneNumber'] as String?,
        name: data['name'] as String? ?? profile.value.name,
        avatarIndex: (data['avatarIndex'] as num?)?.toInt() ?? profile.value.avatarIndex,
        avatarBase64: data['avatarBase64'] as String?,
        isLoggedIn: true,
      );
      profile.value = next;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_nameKey, next.name);
        await prefs.setInt(_avatarKey, next.avatarIndex);
        if (next.avatarBase64 == null) {
          await prefs.remove(_avatarImageKey);
        } else {
          await prefs.setString(_avatarImageKey, next.avatarBase64!);
        }
        if (next.phoneNumber == null) {
          await prefs.remove(_phoneKey);
        } else {
          await prefs.setString(_phoneKey, next.phoneNumber!);
        }
        await prefs.setBool(_isLoggedInKey, true);
      } catch (_) {}
    } catch (_) {}
  }

  static Future<void> update(UserProfile next) async {
    profile.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, next.name);
      await prefs.setInt(_avatarKey, next.avatarIndex);
      if (next.avatarBase64 == null) {
        await prefs.remove(_avatarImageKey);
      } else {
        await prefs.setString(_avatarImageKey, next.avatarBase64!);
      }
      if (next.phoneNumber == null) {
        await prefs.remove(_phoneKey);
      } else {
        await prefs.setString(_phoneKey, next.phoneNumber!);
      }
      await prefs.setBool(_isLoggedInKey, next.isLoggedIn);
    } on MissingPluginException {}
    final token = _authToken;
    if (token != null && token.isNotEmpty && next.isLoggedIn) {
      _patchUserMe(next);
    }
  }

  static Future<void> _patchUserMe(UserProfile next) async {
    final token = _authToken;
    if (token == null || token.isEmpty) return;
    final baseUrl = AiProxyStore.url.value.replaceAll(RegExp(r'/$'), '');
    try {
      final body = <String, dynamic>{
        'name': next.name,
        'avatarIndex': next.avatarIndex,
        'avatarBase64': next.avatarBase64,
        'phoneNumber': next.phoneNumber,
      };
      final res = await http.patch(
        Uri.parse('$baseUrl/user/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (res.statusCode == 401) {
        _authToken = null;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
        } catch (_) {}
        profile.value = profile.value.copyWith(isLoggedIn: false);
      }
    } catch (_) {}
  }

  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } on MissingPluginException {}
  }

  static Future<void> logout() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } on MissingPluginException {}
    final next = profile.value.copyWith(isLoggedIn: false);
    await update(next);
  }
}
