import 'dart:convert';
import 'dart:math' as math;

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'side_tabs/popular_page.dart';
part 'side_tabs/rankings_page.dart';
part 'side_tabs/stats_page.dart';
part 'side_tabs/calculators_page.dart';
part 'side_tabs/bases_armies_page.dart';
part 'side_tabs/game_assets_page.dart';
part 'side_tabs/side_tab_components.dart';

const _pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 28);
