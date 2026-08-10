import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
final User? user = FirebaseAuth.instance.currentUser;
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

Future<void> _showEditDialog() async {
TextEditingController controller = TextEditingController(
text: user?.displayName ?? "",
);

showDialog(
context: context,
builder: (context) {
return AlertDialog(
title: const Text("Edit Username"),
content: TextField(
controller: controller,
decoration: const InputDecoration(
hintText: "Enter new username",
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text("Cancel"),
),
ElevatedButton(
onPressed: () async {
await user?.updateDisplayName(controller.text);
await user?.reload();

setState(() {});

Navigator.pop(context);
},
child: const Text("Save"),
),
],
);
},
);
}

@override
Widget build(BuildContext context) {
final currentUser = FirebaseAuth.instance.currentUser;

return Scaffold(
appBar: AppBar(
title: const Text("Profile"),
centerTitle: true,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
children: [
const SizedBox(height: 20),

  GestureDetector(
    onTap: _pickImage,
    child: CircleAvatar(
      radius: 60,
      backgroundImage:
      _profileImage != null ? FileImage(_profileImage!) : null,
      child: _profileImage == null
          ? const Icon(Icons.person, size: 60)
          : null,
    ),
  ),
const SizedBox(height: 20),

Text(
currentUser?.displayName ?? "No Name",
style: const TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
currentUser?.email ?? "",
style: const TextStyle(fontSize: 16),
),

const SizedBox(height: 30),

ElevatedButton.icon(
onPressed: _showEditDialog,
icon: const Icon(Icons.edit),
label: const Text("Edit Username"),
),
  const SizedBox(height: 20),

  ElevatedButton.icon(
    onPressed: _showPasswordDialog,
    icon: const Icon(Icons.lock),
    label: const Text("Change Password"),
  ),

  const SizedBox(height: 20),

  ElevatedButton.icon(
    onPressed: _logout,
    icon: const Icon(Icons.logout),
    label: const Text("Logout"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
  ),

  const SizedBox(height: 20),

  ElevatedButton.icon(
    onPressed: _deleteAccount,
    icon: const Icon(Icons.delete),
    label: const Text("Delete Account"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade900,
      foregroundColor: Colors.white,
    ),
  ),
],
),
),
);
}

Future<void> _showPasswordDialog() async {
  TextEditingController currentPassword = TextEditingController();
  TextEditingController newPassword = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Change Password"),
      content: TextField(
        controller: confirmPassword ,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: "New Password",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            User user = FirebaseAuth.instance.currentUser!;

            AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: currentPassword.text,
            );

            await user.reauthenticateWithCredential(credential);

            await user.updatePassword(newPassword.text);
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Password Updated"),
              ),
            );
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

Future<void> _logout() async {
  bool? result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Logout"),
      content: const Text("Are you sure you want to logout?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("No"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (result == true) {
    await FirebaseAuth.instance.signOut();

    Navigator.pop(context);
  }
}

Future<void> _deleteAccount() async {
  bool? result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Account"),
      content: const Text(
        "Are you sure? This action cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (result == true) {
    await FirebaseAuth.instance.currentUser?.delete();

    Navigator.pop(context);
  }
}
}