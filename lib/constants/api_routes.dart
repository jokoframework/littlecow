import 'package:flutter_dotenv/flutter_dotenv.dart';
class ApiRoutes {
  /// URL base de la API
  static String baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.example.com';
  
  // Endpoints de autenticación
  static final String login = '$baseUrl/login';
  static final String logout = '$baseUrl/logout';
  static final String refreshToken = '$baseUrl/token/refresh';
  static final String userAccess = '$baseUrl/token/user-access';
  static final String tokenInfo = '$baseUrl/token/info';
  
  // Endpoints para posts
  static final String posts = '$baseUrl/secure/posts';
  static String getPostById(String postId) => '$posts/$postId';
  
  // Endpoints para notificaciones
  static const String userFakeId = '1';
  static final String notifications = '$baseUrl/secure/notifications';
  static String getUserNotifications(String userId) => '$notifications/user/$userFakeId';
  static String markNotificationAsRead(String notificationId) => '$notifications/user/$userFakeId/read/$notificationId';
  
  /// Método para obtener el encabezado de autenticación
  static Map<String, String> getAuthHeader(String token) {
    return {'X-JOKO-AUTH': token};
  }
  
  /// Método para obtener encabezados comunes
  static Map<String, String> getCommonHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers.addAll(getAuthHeader(token));
    }
    
    return headers;
  }
}