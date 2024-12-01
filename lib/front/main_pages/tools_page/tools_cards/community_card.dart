import 'package:clashkingapp/components/beta_label.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/front/main_pages/tools_page/community_tools/community_tools_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final logoUrl = isDarkMode
        ? "https://assets.clashk.ing/logos/crown-arrow-dark-bg/ClashKing-1.png"
        : "https://assets.clashk.ing/logos/crown-arrow-white-bg/ClashKing-2.png";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(),
          ),
        );
      },
      child: Stack(
        children: <Widget>[
          DefaultTextStyle(
            style: Theme.of(context).textTheme.labelLarge ?? TextStyle(),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: [
                        CachedNetworkImage(
                          height: 70,
                          width: 70,
                          imageUrl: logoUrl,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)?.community ?? 'Community',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          BetaLabel(),
        ],
      ),
    );
  }
}