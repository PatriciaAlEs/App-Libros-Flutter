import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/libreria_engine.dart';
import '../../domain/services/skeleton_libreria_engine.dart';
import '../../libreria_feature_flags.dart';
import '../models/libreria_view_state.dart';

final libreriaFeatureEnabledProvider = Provider<bool>(
  (ref) => LibreriaFeatureFlags.enabled,
);

final libreriaEngineProvider = Provider<LibreriaEngine>(
  (ref) => const SkeletonLibreriaEngine(),
);

final libreriaViewStateProvider = Provider<LibreriaViewState>(
  (ref) => const LibreriaViewState(),
);
