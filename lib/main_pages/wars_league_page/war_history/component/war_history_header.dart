import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WarHistoryHeader extends StatelessWidget {
  const WarHistoryHeader({
    super.key,
    required this.discordUser,
    required this.clanName,
    required this.clanTag
  });

  final List<String> discordUser;
  final String clanName;
  final String clanTag;

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
              child: CachedNetworkImage(
                imageUrl: "https://clashkingfiles.b-cdn.net/landscape/war-landscape.jpg",
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
              SizedBox(height: 20),
              SizedBox(
                height: 100,
                width: 100,
                child: CachedNetworkImage(imageUrl: "https://clashkingfiles.b-cdn.net/icons/Icon_HV_Clan_War.png"),
              ),
              Text(
                clanName,
                style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              Text(
                clanTag,
                style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          left: 10,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onPrimary, size: 32
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
