import 'dart:ui';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_page.dart';
import 'package:clashkingapp/features/player/presentation/player/player_achievement_page.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body_card.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/war_stats_page.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member_presence.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clipboard/clipboard.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:shimmer/shimmer.dart';

class PlayerInfoHeader extends StatefulWidget {
  final int selectedTab;
  final Player player;

  const PlayerInfoHeader(
      {super.key, required this.selectedTab, required this.player});

  @override
  PlayerInfoHeaderState createState() => PlayerInfoHeaderState();
}

class PlayerInfoHeaderState extends State<PlayerInfoHeader>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    // Determine UI elements depending on selected tab
    final String backgroundImageUrl = widget.selectedTab == 0
        ? ImageAssets.homeBaseBackground
        : ImageAssets.builderBaseBackground;

    final String hallImageUrl = widget.selectedTab == 0
        ? widget.player.townHallPic
        : widget.player.builderHallPic;

    final List<Widget> stars = widget.selectedTab == 0
        ? _buildStars(widget.player.townHallWeaponLevel)
        : _buildStars(0);

    final Widget hallChips = widget.selectedTab == 0
        ? _buildTownHallChips()
        : _buildBuilderHallChips();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              _buildBackgroundImage(backgroundImageUrl),
              _buildBackButton(context),
              _buildAction(context),
              _buildPlayerMainInfo(hallImageUrl),
            ],
          ),
          SizedBox(height: 46),
          _buildPlayerDetails(context, stars),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: hallChips,
          ),
        ],
      ),
    );
  }

  /// 🎨 Background image with blur effect
  Widget _buildBackgroundImage(String imageUrl) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3),
            BlendMode.darken,
          ),
          child: CachedNetworkImage(
            errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl: imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 🔙 Back button
  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 40,
      left: 10,
      child: IconButton(
        icon: Icon(Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary, size: 32),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// ⚙️ Action button (three dot menu)
  Widget _buildAction(BuildContext context) {
    return Positioned(
      top: 40,
      right: 10,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.sports_esports_rounded,
                color: Colors.white, size: 32),
            onPressed: () {
              final languageCode =
                  Localizations.localeOf(context).languageCode.toLowerCase();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  final url =
                      Uri.https('link.clashofclans.com', '/$languageCode', {
                    'action': 'OpenPlayerProfile',
                    'tag': widget.player.tag,
                  });
                  return OpenClashDialog(url: url);
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'achievements',
                    child: Row(
                      children: [
                        MobileWebImage(
                            imageUrl:
                                widget.player.clanOverview.badgeUrls.small,
                            width: 20),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.achievements),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PlayerAchievementScreen(
                                  player: widget.player,
                                )),
                      );
                    },
                  ),
                  PopupMenuItem(
                    value: 'war_stats',
                    child: Row(
                      children: [
                        MobileWebImage(imageUrl: ImageAssets.war, width: 20),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.warStats),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PlayerWarStatsScreen(player: widget.player)),
                      );
                    },
                  ),
                  PopupMenuItem(
                    value: 'todolist',
                    child: Row(
                      children: [
                        MobileWebImage(
                            imageUrl: ImageAssets.iconBuilderPotion, width: 20),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.toDoList),
                      ],
                    ),
                    onTap: () {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.all(8),
                            child: IntrinsicHeight(
                              child: PlayerToDoBodyCard(
                                player: widget.player,
                                member: WarMemberPresence.empty(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 👤 Player avatar, icons & stats
  Widget _buildPlayerMainInfo(String hallImageUrl) {
    return Positioned(
      bottom: -72,
      child: Row(
        children: [
          SizedBox(width: 16),
          CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: hallImageUrl,
              width: 190),
          SizedBox(width: 16),
        ],
      ),
    );
  }

  /// 📜 Player details: name, tag & stars
  Widget _buildPlayerDetails(BuildContext context, List<Widget> stars) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 22),
              stars.isNotEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: stars,
                    )
                  : SizedBox(height: 22),
              SizedBox(height: 8),
              Text(
                widget.player.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildCopyablePlayerTag(context),
            ],
          ),
        ),
      ],
    );
  }

  /// 📋 Copy player tag to clipboard
  Widget _buildCopyablePlayerTag(BuildContext context) {
    return InkWell(
      onTap: () {
        FlutterClipboard.copy(widget.player.tag).then((_) {
          if (context.mounted) {
            final snackBar = SnackBar(
              content: Center(
                child: Text(
                  AppLocalizations.of(context)!.copiedToClipboard,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              duration: Duration(milliseconds: 1500),
              backgroundColor: Theme.of(context).colorScheme.surface,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.only(top: 2.0, bottom: 10.0),
        child: Text(
          widget.player.tag,
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
    );
  }

  /// ⭐ Build stars based on level
  List<Widget> _buildStars(int count) {
    return List<Widget>.generate(
      count,
      (index) => CachedNetworkImage(
        errorWidget: (context, url, error) => Icon(Icons.error),
        imageUrl: ImageAssets.builderBaseStar,
        width: 22.0,
        height: 22.0,
      ),
    );
  }

  List<Widget> _buildAllHallChips() {
    final locale = Localizations.localeOf(context).toString();

    return [
      if (widget.player.clanTag != "")
        GestureDetector(
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            final Clan clanInfo =
                await ClanService().loadClanData(widget.player.clanTag);
            if (mounted) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClanInfoScreen(
                    clanInfo: clanInfo,
                  ),
                ),
              );
            }
          },
          child: Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: widget.player.clanOverview.badgeUrls.small,
              ),
            ),
            label: Shimmer.fromColors(
              period: const Duration(seconds: 3),
              baseColor: Theme.of(context).colorScheme.onSurface,
              highlightColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              child: Text(
                widget.player.clanOverview.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
            errorWidget: (context, url, error) => Icon(Icons.error),
            imageUrl: ImageAssets.getHeroImage("Archer Queen"),
          ),
        ),
        label: Text(
          PlayerService().getRoleText(widget.player.role, context),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: widget.player.townHallPic),
        ),
        label: Text(
          AppLocalizations.of(context)?.thLevel(widget.player.townHallLevel) ??
              'TH ${widget.player.townHallLevel}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: ImageAssets.xp)),
        label: Text(
          NumberFormat('#,###', locale).format(widget.player.expLevel),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronUp,
            color: const Color.fromARGB(255, 27, 114, 33)),
        label: Text(
          NumberFormat('#,###', locale).format(widget.player.donations),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronDown,
            color: const Color.fromARGB(255, 155, 4, 4)),
        label: Text(
          NumberFormat('#,###', locale).format(widget.player.donationsReceived),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronsUpDown,
            color: const Color.fromARGB(255, 0, 136, 255)),
        label: Text(
          (widget.player.donations /
                  (widget.player.donationsReceived == 0
                      ? 1
                      : widget.player.donationsReceived))
              .toStringAsFixed(2),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
                errorWidget: (context, url, error) => Icon(Icons.error),
                imageUrl: ImageAssets.attackStar)),
        label: Text(
          NumberFormat('#,###', locale).format(widget.player.warStars),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: ImageAssets.capitalGold),
        ),
        label: Text(
          NumberFormat('#,###', locale)
              .format(widget.player.clanCapitalContributions),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ];
  }

  /// 🏆 Town Hall Chip
  Widget _buildTownHallChips() {
    final locale = Localizations.localeOf(context).toString();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 0,
      children: [
        ..._buildAllHallChips(),
        Chip(
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: widget.player.warPreference == 'in'
                  ? ImageAssets.warPreferenceIn
                  : ImageAssets.warPreferenceOut,
            ),
          ),
          label: Text(
            widget.player.warPreference == 'in'
                ? AppLocalizations.of(context)!.ready
                : AppLocalizations.of(context)!.unready,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.sword)),
          label: Text(
            NumberFormat('#,###', locale).format(widget.player.attackWins),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.shield)),
          label: Text(
            NumberFormat('#,###', locale).format(widget.player.defenseWins),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        // Legend trophies + optional shimmer
        widget.player.legendsBySeason != null &&
                widget.player.legendsBySeason!.allSeasons.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerLegendScreen(
                        player: widget.player,
                      ),
                    ),
                  );
                },
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: MobileWebImage(imageUrl: widget.player.leagueUrl),
                  ),
                  label: Shimmer.fromColors(
                    period: const Duration(seconds: 3),
                    baseColor: Theme.of(context).colorScheme.onSurface,
                    highlightColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    child: Text(
                      NumberFormat('#,###', locale)
                          .format(widget.player.trophies),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              )
            : Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: CachedNetworkImage(
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      imageUrl: widget.player.leagueUrl),
                ),
                label: Text(
                  NumberFormat('#,###', locale).format(widget.player.trophies),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.bestTrophies)),
          label: Text(
            NumberFormat('#,###', locale).format(widget.player.bestTrophies),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }

  /// 🏗️ Builder Hall Chip
  Widget _buildBuilderHallChips() {
    final locale = Localizations.localeOf(context).toString();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      runSpacing: 0,
      children: [
        ..._buildAllHallChips(),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.trophies)),
          label: Text(
            NumberFormat('#,###', locale)
                .format(widget.player.builderBaseTrophies),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Chip(
          avatar: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  imageUrl: ImageAssets.trophies)),
          label: Text(
            NumberFormat('#,###', locale)
                .format(widget.player.bestBuilderBaseTrophies),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
