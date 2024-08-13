import 'package:clashkingapp/components/beta_label.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/main_pages/tools_page/community_tools/community_tools_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final logoUrl = isDarkMode
        ? "https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png"
        : "https://clashkingfiles.b-cdn.net/logos/crown-arrow-white-bg/ClashKing-2.png";

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          height: 70,
                          width: 70,
                          imageUrl: logoUrl,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Test',
                                style: Theme.of(context).textTheme.labelLarge,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ],
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