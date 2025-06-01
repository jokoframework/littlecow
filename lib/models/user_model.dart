import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final String? email; 
  final String? id;
  final String? role;
  final String? lastName;
  final DateTime? lastAccessDate;

  const User({
    required this.name,
    this.email,
    this.id,
    this.role,
    this.lastName,
    this.lastAccessDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    if (json['username'] != null && json['name'] == null) {
      return User(
        name: json['username'], 
        email: json['username'], 
        id: json['id']?.toString(),
        role: json['role'],
        lastName: json['lastName'],
        lastAccessDate: json['lastAccessDate'] != null 
            ? DateTime.tryParse(json['lastAccessDate'])
            : null,
      );
    }
    
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? json['username'], 
      id: json['id']?.toString(),
      role: json['role'],
      lastName: json['lastName'],
      lastAccessDate: json['lastAccessDate'] != null 
          ? DateTime.tryParse(json['lastAccessDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'id': id,
      'role': role,
      'lastName': lastName,
      'lastAccessDate': lastAccessDate?.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? email,
    String? id,
    String? role,
    String? lastName,
    DateTime? lastAccessDate,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      id: id ?? this.id,
      role: role ?? this.role,
      lastName: lastName ?? this.lastName,
      lastAccessDate: lastAccessDate ?? this.lastAccessDate,
    );
  }

  @override
  List<Object?> get props => [name, email, id, role, lastName, lastAccessDate];
}