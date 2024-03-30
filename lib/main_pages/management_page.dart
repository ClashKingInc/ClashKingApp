import 'package:flutter/material.dart';

class ManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Center(child: Text('Managment')),
      ),
      body: Center(
        child: Text('Welcome to the Managment Page!'),
      ),
    );
  }
}
