import 'package:flutter/material.dart';

class GroupsHubScreen extends StatelessWidget {
  const GroupsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Groups Hub'),
      ),
      body: const Center(
        child: Text(
          'Groups Hub coming soon.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
