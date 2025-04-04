import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class TranslationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpUsTranslate),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.thankYou,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.thankYouContent,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: CachedNetworkImage(
  
  errorWidget: (context, url, error) => Icon(Icons.error),
                    imageUrl:
                        "https://www.icegif.com/wp-content/uploads/2023/06/icegif-202.gif", // remplacez par votre URL d'image
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.helpUsTranslate,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.helpTranslateContent,
                  style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await launchUrl(Uri.parse(
                        "https://crowdin.com/project/clashkingapp/invite?h=87a407268713f1cb79724a2e0c00a5d52098842"));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  icon: Icon(Icons.language),
                  label: Text(
                    AppLocalizations.of(context)!.helpTranslateButton,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await launchUrl(Uri.parse("https://discord.gg/clashking"));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5865F2),
                  ),
                  icon: Icon(Icons.discord),
                  label: Text(
                    AppLocalizations.of(context)!.faqJoinDiscord,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.currentTranslators,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              SizedBox(height: 16),
              // Replace the following with actual translator names
              Text(
                "• Joelsuperstar \n• niklas312 \n• ColinSchmale \n• athype \n• Nemo_64\n• Dinki/Krakakus \n• SudetiZ \n• MRocha01 \n• GodOfGods \n• DeafToDeath \n• Wraxu \n• MixxStar \n• SamGo \n• AlejandroMoc ",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunchUrl(Uri(path: url))) {
      await launchUrl(Uri(path: url));
    } else {
      throw 'Could not launch $url';
    }
  }
}
