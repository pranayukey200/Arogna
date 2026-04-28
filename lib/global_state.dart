import 'package:flutter/material.dart';

class UserData {
  String name;
  String bloodGroup;
  List<String> allergies;
  List<String> conditions;
  String emergencyContact;
  String role;

  UserData({
    this.name = '',
    this.bloodGroup = '',
    this.allergies = const [],
    this.conditions = const [],
    this.emergencyContact = '',
    this.role = 'citizen',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'conditions': conditions,
      'emergencyContact': emergencyContact,
      'role': role,
    };
  }
}

UserData currentUser = UserData();
