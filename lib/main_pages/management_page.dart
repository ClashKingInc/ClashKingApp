import 'package:flutter/material.dart';

class ManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      appBar: AppBar(
        title: Center(child: Text('Managment')),
      ),
      body: Center(
        child: Text('Welcome to the Managment Page!'),
      ),
    );
  }
}
