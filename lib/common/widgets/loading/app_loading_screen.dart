import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late Animation<double> _textOpacityAnimation;

  List<String> get _loadingTexts => [
        AppLocalizations.of(context)!.loadingVillages,
        AppLocalizations.of(context)!.loadingClanData,
        AppLocalizations.of(context)!.loadingWarStats,
        AppLocalizations.of(context)!.loadingLegendsData,
        AppLocalizations.of(context)!.loadingCapitalRaids,
        AppLocalizations.of(context)!.loadingAlmostReady,
      ];

  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();

    // Rotation animation for the logo (disabled)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for the progress indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text fade animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    // _rotationController.repeat(); // Disabled rotation
    _pulseController.repeat(reverse: true);
    _textController.forward();

    // Cycle through loading texts
    _startTextCycle();
  }

  void _startTextCycle() {
    // Start with the first text immediately visible
    _textController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _cycleText();
      }
    });
  }

  void _cycleText() {
    if (!mounted) return;

    _textController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentTextIndex = _currentTextIndex + 1;
        });
        _textController.forward().then((_) {
          // Only continue cycling if we haven't reached the last text
          if (_currentTextIndex < _loadingTexts.length - 1) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _cycleText();
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Static Logo
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileWebImage(
                    imageUrl: Theme.of(context).brightness == Brightness.dark
                        ? ImageAssets.darkModeLogo
                        : ImageAssets.lightModeLogo),
              ),
            ),

            const SizedBox(height: 30),

            // App Text Logo
            SizedBox(
              height: 35,
              child: MobileWebImage(
                  imageUrl: Theme.of(context).brightness == Brightness.dark
                      ? ImageAssets.darkModeTextLogo
                      : ImageAssets.lightModeTextLogo,
                  fit: BoxFit.contain),
            ),

            const SizedBox(height: 200),

            // Animated Loading Text
            AnimatedBuilder(
              animation: _textOpacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Text(
                    _loadingTexts[_currentTextIndex],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Progress Steps Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isActive = index <= _currentTextIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
