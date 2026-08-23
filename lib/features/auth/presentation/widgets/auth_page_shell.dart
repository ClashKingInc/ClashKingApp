import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shared responsive frame for product-owned authentication flows.
///
/// The shell keeps navigation, localization, and ClashKing image loading in
/// the app while composing the shared DevKit spacing and typography tokens.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.formKey,
    required this.child,
    this.title,
    this.description,
    this.maxWidth = 560,
    this.centerContent = false,
  });

  final GlobalKey<FormState> formKey;
  final Widget child;
  final String? title;
  final String? description;
  final double maxWidth;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final logoUrl = theme.brightness == Brightness.dark
        ? ImageAssets.darkModeLogo
        : ImageAssets.lightModeLogo;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              CKSpacing.lg,
              CKSpacing.sm,
              CKSpacing.lg,
              CKSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: viewport.maxHeight > CKSpacing.xxl
                      ? viewport.maxHeight - CKSpacing.xxl
                      : 0,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: centerContent
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        image: true,
                        label: l10n.appTitle,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 80,
                            child: MobileWebImage(
                              errorWidget: (context, url, error) => Icon(
                                Icons.shield_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              imageUrl: logoUrl,
                            ),
                          ),
                        ),
                      ),
                      if (title != null) ...[
                        const SizedBox(height: CKSpacing.xl),
                        Text(
                          title!,
                          style: CKTypography.of(
                            context,
                            CKTextRole.screenTitle,
                          ).copyWith(color: colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (description != null) ...[
                        const SizedBox(height: CKSpacing.sm),
                        Text(
                          description!,
                          style: CKTypography.of(
                            context,
                            CKTextRole.body,
                          ).copyWith(color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (title != null || description != null)
                        const SizedBox(height: CKSpacing.xl),
                      child,
                      const SizedBox(height: CKSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
