import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.faqTitle),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.faqSearchHint,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          // FAQ content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: _buildFilteredFAQItems(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredFAQItems() {
    final faqItems = [
      // Getting Started & About Section
      _buildSectionHeader(
          AppLocalizations.of(context)!.faqSectionGettingStarted),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWhatIsClashKingProject,
        icon: Icons.info,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqWhatIsClashKingProjectAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!.faqViewOnGitHub,
                      icon: LucideIcons.github,
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () async {
                        launchUrl(Uri.parse('https://github.com/ClashKingInc'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqFeaturesGuide,
        icon: Icons.phone_android,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqFeaturesGuideDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.person,
                  title: AppLocalizations.of(context)!.faqFeaturesPlayerTitle,
                  description: AppLocalizations.of(context)!
                      .faqFeaturesPlayerDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.group,
                  title: AppLocalizations.of(context)!.faqFeaturesClanTitle,
                  description:
                      AppLocalizations.of(context)!.faqFeaturesClanDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.military_tech,
                  title: AppLocalizations.of(context)!.faqFeaturesWarTitle,
                  description:
                      AppLocalizations.of(context)!.faqFeaturesWarDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.trending_up,
                  title: AppLocalizations.of(context)!.faqFeaturesLegendsTitle,
                  description: AppLocalizations.of(context)!
                      .faqFeaturesLegendsDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.assessment,
                  title: AppLocalizations.of(context)!.faqFeaturesCwlTitle,
                  description:
                      AppLocalizations.of(context)!.faqFeaturesCwlDescription,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.faqAppDevelopmentNotice,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWhatCanBotDo,
        icon: Icons.smart_toy,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqWhatCanBotDoAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.track_changes,
                  title: AppLocalizations.of(context)!.faqBotFeatureTracking,
                  description: AppLocalizations.of(context)!.faqBotFeatureTrackingDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.military_tech,
                  title: AppLocalizations.of(context)!.faqBotFeatureWars,
                  description: AppLocalizations.of(context)!.faqBotFeatureWarsDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.notifications,
                  title: AppLocalizations.of(context)!.faqBotFeatureNotifications,
                  description: AppLocalizations.of(context)!.faqBotFeatureNotificationsDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.code,
                  title: AppLocalizations.of(context)!.faqBotFeatureCommands,
                  description: AppLocalizations.of(context)!.faqBotFeatureCommandsDesc,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!.faqInviteBotToServer,
                      icon: LucideIcons.bot,
                      color: Color(0xFF5865F2),
                      onPressed: () async {
                        launchUrl(Uri.parse(
                            'https://discord.com/api/oauth2/authorize?client_id=824653933347209227&permissions=8&scope=bot%20applications.commands'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqIsThisFromSupercell,
        icon: Icons.info,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqFanContentPolicy,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: "Supercell Fan Content Policy",
                      icon: Icons.policy,
                      color: Color(0xFF4CAF50),
                      onPressed: () async {
                        launchUrl(Uri.parse(
                            'https://supercell.com/en/fan-content-policy/'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      
      // Support & Contact Section (grouped)
      _buildSectionHeader(
          AppLocalizations.of(context)!.faqSectionSupportAndContact),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqSupportWork,
        icon: Icons.favorite,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqSupportWorkAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqWaysToSupport,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          context: context,
                          label:
                              AppLocalizations.of(context)!.faqUseCodeClashKing,
                          icon: Icons.gamepad,
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () async {
                            final languageCode = Localizations.localeOf(context)
                                .languageCode
                                .toLowerCase();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final url = Uri.https(
                                    'link.clashofclans.com', '/$languageCode', {
                                  'action': 'SupportCreator',
                                  'id': 'Clashking',
                                });
                                return OpenClashDialog(url: url);
                              },
                            );
                          },
                        ),
                        _buildActionButton(
                          context: context,
                          label: AppLocalizations.of(context)!
                              .faqSupportUsOnPatreon,
                          icon: Icons.coffee,
                          color: Theme.of(context).colorScheme.secondary,
                          onPressed: () async {
                            launchUrl(Uri.parse(
                                'https://www.patreon.com/clashking?utm_campaign=creatorshare_creator'));
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildActionButton(
                          context: context,
                          label: AppLocalizations.of(context)!.faqJoinDiscord,
                          icon: Icons.discord,
                          color: Color(0xFF5865F2),
                          onPressed: () async {
                            launchUrl(
                                Uri.parse('https://discord.gg/clashking'));
                          },
                        ),
                        _buildActionButton(
                          context: context,
                          label: AppLocalizations.of(context)!.faqRateTheApp,
                          icon: Icons.star,
                          color: Colors.orange,
                          onPressed: () async {
                            // TODO: Implement app rating logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .generalComingSoon),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqNeedHelp,
        icon: Icons.help,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqNeedHelpAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!.faqSendEmail,
                      icon: Icons.email,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () async {
                        final Uri params = Uri(
                          scheme: 'mailto',
                          path: 'devs@clashk.ing',
                          query: 'subject=App%20Inquiry',
                        );

                        try {
                          await launchUrl(params);
                        } catch (exception, stackTrace) {
                          Sentry.captureException(exception,
                              stackTrace: stackTrace);

                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Text(AppLocalizations.of(context)!
                                      .faqCannotOpenMailClient),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(AppLocalizations.of(context)!
                                          .generalOk),
                                    ),
                                  ],
                                );
                              },
                            );

                            FlutterClipboard.copy('devs@clashk.ing')
                                  .then((_) {
                                if (mounted) {
                                  showClipboardSnackbar(
                                    context,
                                    AppLocalizations.of(context)!
                                        .generalCopiedToClipboard,
                                  );
                                }
                              });
                          }
                        }
                      },
                    ),
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!.faqJoinDiscord,
                      icon: Icons.discord,
                      color: Color(0xFF5865F2),
                      onPressed: () async {
                        launchUrl(Uri.parse('https://discord.gg/clashking'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // Troubleshooting Section
      _buildSectionHeader(
          AppLocalizations.of(context)!.faqSectionTroubleshooting),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWhyNotAccurate,
        icon: Icons.warning,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: <TextSpan>[
                  TextSpan(
                    text: AppLocalizations.of(context)!.faqClanNotTracked,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: '\n'),
                  TextSpan(
                      text: AppLocalizations.of(context)!
                          .faqClanNotTrackedAnswer),
                  TextSpan(text: '\n\n'),
                  TextSpan(
                    text: AppLocalizations.of(context)!.faqTrackingDown,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: '\n'),
                  TextSpan(
                      text:
                          AppLocalizations.of(context)!.faqTrackingDownAnswer),
                  TextSpan(text: '\n\n'),
                  TextSpan(
                    text: AppLocalizations.of(context)!.faqApiLimitation,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: '\n'),
                  TextSpan(
                      text:
                          AppLocalizations.of(context)!.faqApiLimitationAnswer),
                ],
              ),
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTranslationIssue,
        icon: Icons.translate,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqTranslationIssueAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!
                          .translationHelpUsTranslate,
                      icon: Icons.language,
                      color: Color(0xFF2196F3),
                      onPressed: () async {
                        launchUrl(Uri.parse(
                            'https://crowdin.com/project/clashkingapp'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTroubleshootingDataTitle,
        icon: Icons.cloud_off,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .faqTroubleshootingDataDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingDataSolution1
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingDataSolution1),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingDataSolution2
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingDataSolution2),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingDataSolution3
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingDataSolution3),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTroubleshootingCrashTitle,
        icon: Icons.bug_report,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .faqTroubleshootingCrashDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingCrashSolution1
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingCrashSolution1),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingCrashSolution2
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingCrashSolution2),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingCrashSolution3
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingCrashSolution3),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingCrashSolution4
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingCrashSolution4),
                      ]
                    : [],
                ...AppLocalizations.of(context)!.faqContactSupport.isNotEmpty
                    ? [
                        _buildSolutionItem(
                            AppLocalizations.of(context)!.faqContactSupport),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTroubleshootingAccountTitle,
        icon: Icons.account_circle,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .faqTroubleshootingAccountDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingAccountSolution1
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingAccountSolution1),
                      ]
                    : [],
                ...AppLocalizations.of(context)!
                        .faqTroubleshootingAccountSolution2
                        .isNotEmpty
                    ? [
                        _buildSolutionItem(AppLocalizations.of(context)!
                            .faqTroubleshootingAccountSolution2),
                      ]
                    : [],
                ...AppLocalizations.of(context)!.faqContactSupport.isNotEmpty
                    ? [
                        _buildSolutionItem(
                            AppLocalizations.of(context)!.faqContactSupport),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),

    ];

    if (_searchQuery.isEmpty) {
      return faqItems;
    }

    return faqItems.where((item) {
      return true; // For now, showing all items when searching
    }).toList();
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required List<Widget> content,
    IconData? icon,
  }) {
    if (_searchQuery.isNotEmpty &&
        !question.toLowerCase().contains(_searchQuery)) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          children: content,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainer,
                Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionItem(String solution) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              solution,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
