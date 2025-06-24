import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/auth/presentation/startup_widget.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MobileWebImage(
              imageUrl: ImageAssets.sleepingApprenticeBuilder, width: 250),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.maintenanceTitle,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(AppLocalizations.of(context)!.maintenanceDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 40),
          TextButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => StartupWidget()),
                  ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.refresh, size: 20),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.generalTryAgain,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
              ])),
        ],
      ),
    );
  }
}
