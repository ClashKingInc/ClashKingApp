import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  CommunityScreen(
      {super.key});

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {

  Future<void> _refreshData() async {
    // Fetch the updated profile information
    
    setState(() {
      // Update the player stats with the newly fetched data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("data"),
            ],
          ),
        ),
      ),
    );
  }
}