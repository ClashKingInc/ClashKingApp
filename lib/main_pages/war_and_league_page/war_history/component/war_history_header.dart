import 'dart:ui';
import 'package:flutter/material.dart';

class WarHistoryHeader extends StatelessWidget {
  const WarHistoryHeader({
    super.key,
    required this.discordUser,
  });

  final List<String> discordUser;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 200,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
              child: Image.network(
                "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "War History",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
              Text(
                "Clan Tag",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}