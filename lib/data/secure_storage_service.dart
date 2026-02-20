import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:littlecow/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  
  
  static const String refreshTokenKey = 'REFRESH_TOKEN';
  static const String accessTokenKey = 'ACCESS_TOKEN';
  static const String accessTokenExpirationKey = 'ACCESS_TOKEN_EXPIRATION';
  static const String userDataKey = 'USER_DATA';
  static const String usernameKey = 'USERNAME'; 
  
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  
  
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: refreshTokenKey, value: token);
  }
  
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }
  
  
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: accessTokenKey, value: token);
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }
  
  Future<void> saveAccessTokenExpiration(int expirationTimestamp) async {
    await _storage.write(
        key: accessTokenExpirationKey, value: expirationTimestamp.toString());
  }
  
  Future<int?> getAccessTokenExpiration() async {
    final expirationStr = await _storage.read(key: accessTokenExpirationKey);
    if (expirationStr == null || expirationStr.isEmpty) {
      return null;
    }
    return int.tryParse(expirationStr);
  }
  
  Future<void> deleteAllTokens() async {
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: accessTokenExpirationKey);
    await deleteUserData(); 
    await deleteUsername(); 
  }
  
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }
  Future<bool> hasUserData() async {
    final userJson = await _storage.read(key: userDataKey);
    return userJson != null && userJson.isNotEmpty;
  }
  
  Future<void> saveUserData(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: userDataKey, value: userJson);
  }
  
  Future<User?> getUserData() async {
    final userJson = await _storage.read(key: userDataKey);
    if (userJson == null || userJson.isEmpty) {
      return null;
    }
    return User.fromJson(jsonDecode(userJson));
  }
  
  Future<void> deleteUserData() async {
    await _storage.delete(key: userDataKey);
  }
  
  Future<void> saveUsername(String username) async {
    await _storage.write(key: usernameKey, value: username);
  }
  
  Future<String?> getUsername() async {
    return await _storage.read(key: usernameKey);
  }
  
  Future<void> deleteUsername() async {
    await _storage.delete(key: usernameKey);
  }
}