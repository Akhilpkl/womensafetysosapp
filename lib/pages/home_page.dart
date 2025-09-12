import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert'; // Import dart:convert for JSON
import 'dart:math'; // For generating unique IDs, if you switch to Contact objects

// You should have this file: lib/models/contact_model.dart
// If not, create it as shown in previous answers.
// For now, I'll put a simplified Contact class here for direct use,
// but it's better to have it in a separate file (e.g., lib/models/contact_model.dart)

// --- Simple Contact Model (Ideally in a separate file) ---
class Contact {
  final String id;
  final String name; // You might want to add a name field later
  final String phoneNumber;

  Contact({required this.id, this.name = "", required this.phoneNumber});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    name: json['name'] as String? ?? '', // Handle if name is missing
    phoneNumber: json['phoneNumber'] as String,
  );
}
// --- End of Simple Contact Model ---


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<String> sosHistory = [];
  // List<String> trustedContacts = []; // We will replace this with List<Contact>
  List<Contact> trustedContactsObjects = []; // Stores Contact objects
  String sosMessage = "I am in danger! Please help. My location: ";
  final Telephony telephony = Telephony.instance;

  static const String _contactsKey = 'trusted_contacts_list'; // Key for shared_preferences

  @override
  void initState() {
    super.initState();
    _loadContactsFromStorage(); // Load contacts when the page initializes
    // You might want to move sosHistory loading here if you plan to persist it too
  }

  // --- Utility to generate a unique ID ---
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // --- Load contacts from SharedPreferences ---
  Future<void> _loadContactsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsString = prefs.getString(_contactsKey);
    if (contactsString != null && contactsString.isNotEmpty) {
      final List<dynamic> decodedList = jsonDecode(contactsString);
      setState(() {
        trustedContactsObjects = decodedList.map((item) => Contact.fromJson(item as Map<String, dynamic>)).toList();
      });
    } else {
      setState(() {
        trustedContactsObjects = []; // Initialize as empty if nothing is stored
      });
    }
    // Also load sosHistory if you persist it
    // For now, sosHistory remains in-memory:
    // setState(() {
    //   sosHistory = [];
    // });
  }

  // --- Save contacts to SharedPreferences ---
  Future<void> _saveContactsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(trustedContactsObjects.map((contact) => contact.toJson()).toList());
    await prefs.setString(_contactsKey, encodedData);
  }


  Future<void> sendSOS() async {
    if (trustedContactsObjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No trusted contacts to send SOS. Please add contacts first.")),
      );
      return;
    }
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied! Cannot send SOS.")),
          );
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled. Please enable GPS.")),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
          forceAndroidLocationManager: true);

      if (position.accuracy > 100) {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && lastPosition.accuracy < position.accuracy) {
          position = lastPosition;
        }
      }

      String locationUrl = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String finalMessage = "$sosMessage $locationUrl";

      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted != null && permissionsGranted) {
        for (Contact contactObject in trustedContactsObjects) { // Iterate over Contact objects
          telephony.sendSms(to: contactObject.phoneNumber, message: finalMessage);
        }

        String timestamp = DateTime.now().toString();
        setState(() {
          sosHistory.add("🚨 SOS sent at $timestamp to ${trustedContactsObjects.length} contact(s)");
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS Sent with Location!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SMS permission denied!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending SOS: $e")),
      );
    }
  }

  void _showAddEditContactDialog({Contact? existingContact}) {
    TextEditingController nameController = TextEditingController(text: existingContact?.name ?? "");
    TextEditingController phoneController = TextEditingController(text: existingContact?.phoneNumber ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingContact == null ? "Add Contact" : "Edit Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Enter contact name (optional)"),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: "Enter phone number *"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final String name = nameController.text.trim();
              final String phone = phoneController.text.trim();

              if (phone.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Phone number cannot be empty.")),
                );
                return;
              }

              setState(() {
                if (existingContact == null) { // Add new contact
                  trustedContactsObjects.add(Contact(
                    id: _generateUniqueId(), // Generate a unique ID
                    name: name,
                    phoneNumber: phone,
                  ));
                } else { // Edit existing contact
                  int index = trustedContactsObjects.indexWhere((c) => c.id == existingContact.id);
                  if (index != -1) {
                    trustedContactsObjects[index] = Contact(
                      id: existingContact.id,
                      name: name,
                      phoneNumber: phone,
                    );
                  }
                }
                _saveContactsToStorage(); // Save after adding/editing
              });
              Navigator.pop(ctx);
            },
            child: Text(existingContact == null ? "Save" : "Update"),
          ),
        ],
      ),
    );
  }

  void _deleteContact(String contactId) {
    // Optional: Show a confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this contact?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          trustedContactsObjects.removeWhere((c) => c.id == contactId);
          _saveContactsToStorage(); // Save after deleting
        });
      }
    });
  }


  void logout() async {
    await FirebaseAuth.instance.signOut();
    // The StreamBuilder in main.dart should automatically navigate to LoginPage
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      // Home Tab
      Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: sendSOS,
          child: const Text("🚨 SEND SOS", style: TextStyle(fontSize: 22, color: Colors.white)),
        ),
      ),

      // Contacts Tab
      trustedContactsObjects.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No trusted contacts yet.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Contact'),
              onPressed: () => _showAddEditContactDialog(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            )
          ],
        ),
      )
          : ListView.builder(
        itemCount: trustedContactsObjects.length,
        itemBuilder: (context, index) {
          final contact = trustedContactsObjects[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pinkAccent,
                child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : contact.phoneNumber[0],
                    style: const TextStyle(color: Colors.white)
                ),
              ),
              title: Text(contact.name.isNotEmpty ? contact.name : "Unnamed Contact"),
              subtitle: Text(contact.phoneNumber),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAddEditContactDialog(existingContact: contact),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(contact.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // History Tab
      sosHistory.isEmpty
          ? const Center(child: Text("No SOS history yet.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        itemCount: sosHistory.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(sosHistory[index]));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Women Safety App", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white), // Makes logout icon white
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: tabs[currentIndex],
      floatingActionButton: currentIndex == 1 // Show FAB only on Contacts tab
          ? FloatingActionButton(
        onPressed: () => _showAddEditContactDialog(),
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Contact',
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.pink,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "Contacts"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}
