import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animationController.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.faqTitle),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            CKSpacing.lg,
            CKSpacing.sm - 2,
            CKSpacing.lg,
            CKSpacing.xl + CKSpacing.xs,
          ),
          children: [_buildSearchPanel(), ..._buildFilteredFAQItems()],
        ),
      ),
    );
  }

  Widget _buildSearchPanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: CKSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(CKRadius.card),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: CKOpacity.border,
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: CKControlDensity.standard.minimumHeight,
          ),
          child: TextField(
            controller: _searchController,
            scrollPadding: EdgeInsets.zero,
            textInputAction: TextInputAction.search,
            style: CKTypography.of(
              context,
              CKTextRole.body,
            ).copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.faqSearchHint,
              hintStyle: CKTypography.of(
                context,
                CKTextRole.body,
              ).copyWith(color: colorScheme.onSurfaceVariant),
              isDense: true,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: CKControlDensity.standard.minimumHeight - 4,
                minHeight: CKControlDensity.standard.minimumHeight,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: AppLocalizations.of(context)!.searchClear,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: CKSpacing.lg,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredFAQItems() {
    final faqItems = [
      // Getting Started & About Section
      _buildSectionHeader(
        AppLocalizations.of(context)!.faqSectionGettingStarted,
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWhatIsClashKingProject,
        searchKeywords: [
          AppLocalizations.of(context)!.faqWhatIsClashKingProjectAnswer,
        ],
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
                      icon: LucideIcons.externalLink,
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
        searchKeywords: [
          AppLocalizations.of(context)!.faqFeaturesGuideDescription,
          AppLocalizations.of(context)!.faqFeaturesPlayerTitle,
          AppLocalizations.of(context)!.faqFeaturesPlayerDescription,
          AppLocalizations.of(context)!.faqFeaturesClanTitle,
          AppLocalizations.of(context)!.faqFeaturesClanDescription,
          AppLocalizations.of(context)!.faqFeaturesWarTitle,
          AppLocalizations.of(context)!.faqFeaturesWarDescription,
          AppLocalizations.of(context)!.faqFeaturesLegendsTitle,
          AppLocalizations.of(context)!.faqFeaturesLegendsDescription,
          AppLocalizations.of(context)!.faqFeaturesCwlTitle,
          AppLocalizations.of(context)!.faqFeaturesCwlDescription,
          AppLocalizations.of(context)!.faqFeaturesTodoTitle,
          AppLocalizations.of(context)!.faqFeaturesTodoDescription,
          AppLocalizations.of(context)!.faqFeaturesUpgradeTrackerTitle,
          AppLocalizations.of(context)!.faqFeaturesUpgradeTrackerDescription,
          AppLocalizations.of(context)!.faqFeaturesNotificationsTitle,
          AppLocalizations.of(context)!.faqFeaturesNotificationsDescription,
          AppLocalizations.of(context)!.faqFeaturesWidgetsTitle,
          AppLocalizations.of(context)!.faqFeaturesWidgetsDescription,
        ],
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
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesPlayerDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.group,
                  title: AppLocalizations.of(context)!.faqFeaturesClanTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesClanDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.military_tech,
                  title: AppLocalizations.of(context)!.faqFeaturesWarTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesWarDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.trending_up,
                  title: AppLocalizations.of(context)!.faqFeaturesLegendsTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesLegendsDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.assessment,
                  title: AppLocalizations.of(context)!.faqFeaturesCwlTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesCwlDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.checklist_rounded,
                  title: AppLocalizations.of(context)!.faqFeaturesTodoTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesTodoDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.construction_rounded,
                  title: AppLocalizations.of(
                    context,
                  )!.faqFeaturesUpgradeTrackerTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesUpgradeTrackerDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  title: AppLocalizations.of(
                    context,
                  )!.faqFeaturesNotificationsTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesNotificationsDescription,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.widgets_rounded,
                  title: AppLocalizations.of(context)!.faqFeaturesWidgetsTitle,
                  description: AppLocalizations.of(
                    context,
                  )!.faqFeaturesWidgetsDescription,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.38),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.faqAppDevelopmentNotice,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
        searchKeywords: [
          AppLocalizations.of(context)!.faqWhatCanBotDoAnswer,
          AppLocalizations.of(context)!.faqBotFeatureTracking,
          AppLocalizations.of(context)!.faqBotFeatureTrackingDesc,
          AppLocalizations.of(context)!.faqBotFeatureWars,
          AppLocalizations.of(context)!.faqBotFeatureWarsDesc,
          AppLocalizations.of(context)!.faqBotFeatureNotifications,
          AppLocalizations.of(context)!.faqBotFeatureNotificationsDesc,
          AppLocalizations.of(context)!.faqBotFeatureCommands,
          AppLocalizations.of(context)!.faqBotFeatureCommandsDesc,
        ],
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
                  description: AppLocalizations.of(
                    context,
                  )!.faqBotFeatureTrackingDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.military_tech,
                  title: AppLocalizations.of(context)!.faqBotFeatureWars,
                  description: AppLocalizations.of(
                    context,
                  )!.faqBotFeatureWarsDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.notifications,
                  title: AppLocalizations.of(
                    context,
                  )!.faqBotFeatureNotifications,
                  description: AppLocalizations.of(
                    context,
                  )!.faqBotFeatureNotificationsDesc,
                ),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.code,
                  title: AppLocalizations.of(context)!.faqBotFeatureCommands,
                  description: AppLocalizations.of(
                    context,
                  )!.faqBotFeatureCommandsDesc,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton(
                      context: context,
                      label: AppLocalizations.of(context)!.faqInviteBotToServer,
                      icon: LucideIcons.bot,
                      onPressed: () async {
                        launchUrl(
                          Uri.parse(
                            'https://discord.com/api/oauth2/authorize?client_id=824653933347209227&permissions=8&scope=bot%20applications.commands',
                          ),
                        );
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
        searchKeywords: [
          AppLocalizations.of(context)!.faqFanContentPolicy,
          AppLocalizations.of(context)!.faqSupercellFanContentPolicyLink,
        ],
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
                      label: AppLocalizations.of(
                        context,
                      )!.faqSupercellFanContentPolicyLink,
                      icon: Icons.policy,
                      onPressed: () async {
                        launchUrl(
                          Uri.parse(
                            'https://supercell.com/en/fan-content-policy/',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // Accounts, alerts & widgets section
      _buildSectionHeader(
        AppLocalizations.of(context)!.faqSectionAccountsAlertsWidgets,
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqLinkedAccountsTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqLinkedAccountsAnswer,
          AppLocalizations.of(context)!.faqLinkedAccountsSolution1,
          AppLocalizations.of(context)!.faqLinkedAccountsSolution2,
          AppLocalizations.of(context)!.faqLinkedAccountsSolution3,
        ],
        icon: Icons.manage_accounts_rounded,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqLinkedAccountsAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqLinkedAccountsSolution1,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqLinkedAccountsSolution2,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqLinkedAccountsSolution3,
                ),
              ],
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqNotificationsTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqNotificationsAnswer,
          AppLocalizations.of(context)!.faqNotificationsSolution1,
          AppLocalizations.of(context)!.faqNotificationsSolution2,
          AppLocalizations.of(context)!.faqNotificationsSolution3,
        ],
        icon: Icons.notifications_active_rounded,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqNotificationsAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqNotificationsSolution1,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqNotificationsSolution2,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqNotificationsSolution3,
                ),
              ],
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWidgetsTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqWidgetsAnswer,
          AppLocalizations.of(context)!.faqWidgetsSolution1,
          AppLocalizations.of(context)!.faqWidgetsSolution2,
          AppLocalizations.of(context)!.faqWidgetsSolution3,
        ],
        icon: Icons.widgets_rounded,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faqWidgetsAnswer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqWidgetsSolution1,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqWidgetsSolution2,
                ),
                _buildSolutionItem(
                  AppLocalizations.of(context)!.faqWidgetsSolution3,
                ),
              ],
            ),
          ),
        ],
      ),

      // Support & Contact Section (grouped)
      _buildSectionHeader(
        AppLocalizations.of(context)!.faqSectionSupportAndContact,
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqSupportWork,
        searchKeywords: [
          AppLocalizations.of(context)!.faqSupportWorkAnswer,
          AppLocalizations.of(context)!.faqWaysToSupport,
          AppLocalizations.of(context)!.faqUseCodeClashKing,
          AppLocalizations.of(context)!.faqSupportUsOnPatreon,
          AppLocalizations.of(context)!.faqJoinDiscord,
        ],
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.faqUseCodeClashKing,
                          icon: Icons.gamepad,
                          onPressed: () async {
                            final languageCode = Localizations.localeOf(
                              context,
                            ).languageCode.toLowerCase();
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final url = Uri.https(
                                  'link.clashofclans.com',
                                  '/$languageCode',
                                  {
                                    'action': 'SupportCreator',
                                    'id': 'Clashking',
                                  },
                                );
                                return OpenClashDialog(url: url);
                              },
                            );
                          },
                        ),
                        _buildActionButton(
                          context: context,
                          label: AppLocalizations.of(
                            context,
                          )!.faqSupportUsOnPatreon,
                          icon: Icons.coffee,
                          onPressed: () async {
                            launchUrl(
                              Uri.parse(
                                'https://www.patreon.com/clashking?utm_campaign=creatorshare_creator',
                              ),
                            );
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
                          onPressed: () async {
                            launchUrl(
                              Uri.parse('https://discord.gg/clashking'),
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
        searchKeywords: [
          AppLocalizations.of(context)!.faqNeedHelpAnswer,
          AppLocalizations.of(context)!.faqSendEmail,
          AppLocalizations.of(context)!.faqJoinDiscord,
          'devs@clashk.ing',
        ],
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
                      onPressed: () async {
                        final Uri params = Uri(
                          scheme: 'mailto',
                          path: 'devs@clashk.ing',
                          query: 'subject=App%20Inquiry',
                        );

                        try {
                          await launchUrl(params);
                        } catch (exception, stackTrace) {
                          Sentry.captureException(
                            exception,
                            stackTrace: stackTrace,
                          );

                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.faqCannotOpenMailClient,
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.generalOk,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            FlutterClipboard.copy('devs@clashk.ing').then((_) {
                              if (mounted) {
                                showClipboardSnackbar(
                                  context,
                                  AppLocalizations.of(
                                    context,
                                  )!.generalCopiedToClipboard,
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
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqPrivacyDataTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqPrivacyDataAnswer,
          AppLocalizations.of(context)!.settingsPrivacyPolicy,
          'privacy',
          'gdpr',
          'rgpd',
          'data export',
          'account deletion',
        ],
        icon: Icons.privacy_tip_outlined,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.faqPrivacyDataAnswer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),

      // Troubleshooting Section
      _buildSectionHeader(AppLocalizations.of(context)!.faqTroubleshooting),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqWhyNotAccurate,
        searchKeywords: [
          AppLocalizations.of(context)!.faqClanNotTracked,
          AppLocalizations.of(context)!.faqClanNotTrackedAnswer,
          AppLocalizations.of(context)!.faqTrackingDown,
          AppLocalizations.of(context)!.faqTrackingDownAnswer,
          AppLocalizations.of(context)!.faqApiLimitation,
          AppLocalizations.of(context)!.faqApiLimitationAnswer,
        ],
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
                    text: AppLocalizations.of(context)!.faqClanNotTrackedAnswer,
                  ),
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
                    text: AppLocalizations.of(context)!.faqTrackingDownAnswer,
                  ),
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
                    text: AppLocalizations.of(context)!.faqApiLimitationAnswer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTranslationIssue,
        searchKeywords: [
          AppLocalizations.of(context)!.faqTranslationIssueAnswer,
          AppLocalizations.of(context)!.translationHelpUsTranslate,
          'Crowdin',
        ],
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
                      label: AppLocalizations.of(
                        context,
                      )!.translationHelpUsTranslate,
                      icon: Icons.language,
                      onPressed: () async {
                        launchUrl(
                          Uri.parse('https://crowdin.com/project/clashkingapp'),
                        );
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
        searchKeywords: [
          AppLocalizations.of(context)!.faqTroubleshootingDataDescription,
          AppLocalizations.of(context)!.faqTroubleshootingDataSolution1,
          AppLocalizations.of(context)!.faqTroubleshootingDataSolution2,
          AppLocalizations.of(context)!.faqTroubleshootingDataSolution3,
        ],
        icon: Icons.cloud_off,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.faqTroubleshootingDataDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingDataSolution1.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingDataSolution1,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingDataSolution2.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingDataSolution2,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingDataSolution3.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingDataSolution3,
                        ),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTroubleshootingCrashTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqTroubleshootingCrashDescription,
          AppLocalizations.of(context)!.faqTroubleshootingCrashSolution1,
          AppLocalizations.of(context)!.faqTroubleshootingCrashSolution2,
          AppLocalizations.of(context)!.faqTroubleshootingCrashSolution3,
          AppLocalizations.of(context)!.faqTroubleshootingCrashSolution4,
          AppLocalizations.of(context)!.faqContactSupport,
        ],
        icon: Icons.bug_report,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.faqTroubleshootingCrashDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingCrashSolution1.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingCrashSolution1,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingCrashSolution2.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingCrashSolution2,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingCrashSolution3.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingCrashSolution3,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingCrashSolution4.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingCrashSolution4,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(context)!.faqContactSupport.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(context)!.faqContactSupport,
                        ),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),

      _buildFAQItem(
        question: AppLocalizations.of(context)!.faqTroubleshootingAccountTitle,
        searchKeywords: [
          AppLocalizations.of(context)!.faqTroubleshootingAccountDescription,
          AppLocalizations.of(context)!.faqTroubleshootingAccountSolution1,
          AppLocalizations.of(context)!.faqTroubleshootingAccountSolution2,
          AppLocalizations.of(context)!.faqContactSupport,
        ],
        icon: Icons.account_circle,
        content: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.faqTroubleshootingAccountDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.faqTroubleshootingSolutions,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingAccountSolution1.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingAccountSolution1,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(
                      context,
                    )!.faqTroubleshootingAccountSolution2.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(
                            context,
                          )!.faqTroubleshootingAccountSolution2,
                        ),
                      ]
                    : [],
                ...AppLocalizations.of(context)!.faqContactSupport.isNotEmpty
                    ? [
                        _buildSolutionItem(
                          AppLocalizations.of(context)!.faqContactSupport,
                        ),
                      ]
                    : [],
              ],
            ),
          ),
        ],
      ),
    ];

    return faqItems;
  }

  Widget _buildSectionHeader(String title) {
    if (_searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required List<Widget> content,
    List<String> searchKeywords = const [],
    IconData? icon,
  }) {
    final searchableText = [question, ...searchKeywords].join(' ');
    final colorScheme = Theme.of(context).colorScheme;

    if (_searchQuery.isNotEmpty &&
        !searchableText.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              iconColor: colorScheme.onSurfaceVariant,
              collapsedIconColor: colorScheme.onSurfaceVariant,
              shape: const RoundedRectangleBorder(),
              collapsedShape: const RoundedRectangleBorder(),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: Row(
                children: [
                  if (icon != null) ...[
                    SizedBox(
                      width: 28,
                      child: Icon(
                        icon,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      question,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              children: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, textAlign: TextAlign.center),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
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
