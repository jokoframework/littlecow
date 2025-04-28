import 'package:littlecow/model/user_model.dart';
class AccessToken {
  final String accessToken;
  final int expiresIn;
  final User user;

  AccessToken({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  }); 
  /*
  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return AccessTokenResponse(
      accessToken: json['access_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
    );
  }*/
}