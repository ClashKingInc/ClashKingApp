import 'dart:ffi';

import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Your dashboard page implementation
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              // Padding right and left
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Adjust vertical alignment here
                children: <Widget>[
                  Image.asset('assets/icons/Crown.png',
                      width: 80,
                      height: 80), // Specify your desired width and height
                  SizedBox(width: 16), // Add space between the image and text
                  Expanded(
                    // Use Expanded to ensure text takes up the remaining space
                    child: Text(
                      'Use creator Code ClashKing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('What\'s up folks ?'),
            ),
          ),
          // Add more cards as needed
        ],
      ),
    );
  }
}
