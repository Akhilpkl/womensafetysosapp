// lib/models/contact_model.dart
import 'dart:convert';

class Contact {
  final String id; // Unique ID for each contact
  final String name;
  final String phoneNumber;

  Contact({required this.id, required this.name, required this.phoneNumber});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
  );

  static String encode(List<Contact> contacts) => json.encode(
    contacts
        .map<Map<String, dynamic>>((contact) => contact.toJson())
        .toList(),
  );

  static List<Contact> decode(String contactsString) {
    if (contactsString.isEmpty) {
      return [];
    }
    return (json.decode(contactsString) as List<dynamic>)
        .map<Contact>((item) => Contact.fromJson(item))
        .toList();
  }
}
