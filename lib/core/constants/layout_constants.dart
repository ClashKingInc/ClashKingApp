import 'package:flutter/foundation.dart';

/// The maximum width for the app content on larger screens (desktop/tablet).
const double kMaxContentWidth = 800.0;

/// Vertical spacing between chip rows.
/// Negative on mobile compensates for chip internal padding; positive on web avoids row overlap.
double get kChipRunSpacing => kIsWeb ? 4.0 : -7.0;
