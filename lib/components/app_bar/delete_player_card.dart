import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/components/app_bar/app_bar_functions.dart';

class DeletePlayerCard extends StatefulWidget {
  const DeletePlayerCard({super.key});

  @override
  DeletePlayerCardState createState() => DeletePlayerCardState();
}

class DeletePlayerCardState extends State<DeletePlayerCard> {
    final TextEditingController controller = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Add a TextField
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Enter player tag to delete',
        ),
      ),

      ElevatedButton(
        onPressed: () async {
          String token = await login();
          // Get the text entered by the user
          String playerTag = controller.text;
          deleteLink(playerTag, token);
          Navigator.of(context).pop();
          // Now you can use `playerTag`
        },
        child: Text('Delete player'),
      ),
    ]);
  }
}
