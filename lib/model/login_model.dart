// login_response.dart
class LoginResponse {
  final String secret;
  final bool success;
  final String message;

  LoginResponse({
    required this.secret,
    required this.success,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      secret: json['secret'] ?? '',
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}