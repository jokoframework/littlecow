import 'package:littlecow/models/base_response.dart';
import 'package:littlecow/models/user_model.dart';

class UserResponse extends JokoBaseResponse {
  final User? user;
  final String userMessage;

  UserResponse({
    required super.success,
    super.errorCode,
    super.message,
    this.user,
    this.userMessage = '',
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      success: json['success'] ?? false,
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      userMessage: json['userMessage'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'user': user?.toJson(),
      'userMessage': userMessage,
    };
  }
}