import 'package:flutter/material.dart';
import 'package:clashkingapp/api/player_account_info.dart';

class LegendScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  LegendScreen({Key? key, required this.playerStats}) : super(key: key);

  @override
  LegendScreenState createState() => LegendScreenState();
}

class LegendScreenState extends State<LegendScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}
