import 'dart:ui';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_page.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/legend/player_legend_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:clipboard/clipboard.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:shimmer/shimmer.dart';

class PlayerInfoHeader extends StatefulWidget {
  final int selectedTab;
  const PlayerInfoHeader({super.key, required this.selectedTab});

  @override
  PlayerInfoHeaderState createState() => PlayerInfoHeaderState();
}

class PlayerInfoHeaderState extends State<PlayerInfoHeader>
    with SingleTickerProviderStateMixin {
  Player? player;

  @override
  void initState() {
    super.initState();
    final playerService = context.read<PlayerService>();
    final cocAccountService = context.read<CocAccountService>();
    player = playerService.getSelectedProfile(cocAccountService);
  }

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return Center(child: CircularProgressIndicator());
    }

    // Determine UI elements depending on selected tab
    final String backgroundImageUrl = widget.selectedTab == 0
        ? ImageAssets.homeBaseBackground
        : ImageAssets.builderBaseBackground;

    final String hallImageUrl =
        widget.selectedTab == 0 ? player!.townHallPic : player!.builderHallPic;

    final List<Widget> stars = widget.selectedTab == 0
        ? _buildStars(player!.townHallWeaponLevel)
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

  /// 👤 Player avatar, icons & stats
  Widget _buildPlayerMainInfo(String hallImageUrl) {
    return Positioned(
      bottom: -72,
      child: Row(
        children: [
          _buildPlayerActions(),
          SizedBox(width: 16),
          CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: hallImageUrl,
              width: 170),
          SizedBox(width: 16),
          _buildExternalActions(),
        ],
      ),
    );
  }

  /// 🎮 Buttons for in-app actions
  Widget _buildPlayerActions() {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.verified_rounded, color: Colors.white, size: 32),
          onPressed: () {},
        ),
        SizedBox(height: 8),
        IconButton(
          icon: Icon(LucideIcons.barChart3, color: Colors.white, size: 32),
          onPressed: () {},
        ),
        SizedBox(height: 48),
      ],
    );
  }

  /// 🌐 External actions (e.g. open in Clash of Clans)
  Widget _buildExternalActions() {
    return Column(
      children: [
        IconButton(
          icon:
              Icon(Icons.sports_esports_rounded, color: Colors.white, size: 32),
          onPressed: () {
            final languageCode =
                Localizations.localeOf(context).languageCode.toLowerCase();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                final url =
                    Uri.https('link.clashofclans.com', '/$languageCode', {
                  'action': 'OpenPlayerProfile',
                  'tag': player!.tag,
                });
                return OpenClashDialog(url: url);
              },
            );
          },
        ),
        SizedBox(height: 48),
      ],
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
                player!.name,
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
        FlutterClipboard.copy(player!.tag).then((_) {
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
          player!.tag,
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
      if (player!.clan != null)
        GestureDetector(
          onTap: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            final Clan clanInfo =
                await ClanService().loadClanData(player!.clan!.tag);
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
                imageUrl: player!.clan!.badgeUrls.small,
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
                player!.clan!.name,
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
          PlayerService().getRoleText(player!.role, context),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: CachedNetworkImage(
              errorWidget: (context, url, error) => Icon(Icons.error),
              imageUrl: player!.townHallPic),
        ),
        label: Text(
          AppLocalizations.of(context)?.thLevel(player!.townHallLevel) ??
              'TH ${player!.townHallLevel}',
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
          NumberFormat('#,###', locale).format(player!.expLevel),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronUp,
            color: const Color.fromARGB(255, 27, 114, 33)),
        label: Text(
          NumberFormat('#,###', locale).format(player!.donations),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronDown,
            color: const Color.fromARGB(255, 155, 4, 4)),
        label: Text(
          NumberFormat('#,###', locale).format(player!.donationsReceived),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      Chip(
        avatar: Icon(LucideIcons.chevronsUpDown,
            color: const Color.fromARGB(255, 0, 136, 255)),
        label: Text(
          (player!.donations /
                  (player!.donationsReceived == 0
                      ? 1
                      : player!.donationsReceived))
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
          NumberFormat('#,###', locale).format(player!.warStars),
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
              .format(player!.clanCapitalContributions),
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
              imageUrl: player!.warPreference == 'in'
                  ? ImageAssets.warPreferenceIn
                  : ImageAssets.warPreferenceOut,
            ),
          ),
          label: Text(
            player!.warPreference == 'in'
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
            NumberFormat('#,###', locale).format(player!.attackWins),
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
            NumberFormat('#,###', locale).format(player!.defenseWins),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        // Legend trophies + optional shimmer
        player!.legendsBySeason != null &&
                player!.legendsBySeason!.allSeasons.isNotEmpty
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
                      builder: (context) => LegendScreen(),
                    ),
                  );
                },
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: MobileWebImage(imageUrl: player!.leagueUrl),
                  ),
                  label: Shimmer.fromColors(
                    period: const Duration(seconds: 3),
                    baseColor: Theme.of(context).colorScheme.onSurface,
                    highlightColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    child: Text(
                      NumberFormat('#,###', locale).format(player!.trophies),
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
                      imageUrl: player!.leagueUrl),
                ),
                label: Text(
                  NumberFormat('#,###', locale).format(player!.trophies),
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
            NumberFormat('#,###', locale).format(player!.bestTrophies),
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
            NumberFormat('#,###', locale).format(player!.builderBaseTrophies),
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
                .format(player!.bestBuilderBaseTrophies),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
