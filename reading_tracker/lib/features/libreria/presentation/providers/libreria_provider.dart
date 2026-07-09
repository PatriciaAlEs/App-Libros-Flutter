import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/libreria_engine.dart';
import '../../engine/libreria_engine.dart';
import '../../libreria_feature_flags.dart';
import '../models/libreria_view_state.dart';

final libreriaFeatureEnabledProvider = Provider<bool>(
  (ref) => LibreriaFeatureFlags.enabled,
);

final libreriaEngineProvider = Provider<LibreriaEngine>(
  (ref) => const LibrerIAEngine(),
);

final libreriaViewStateProvider = Provider<LibreriaViewState>((ref) {
  final engine = ref.watch(libreriaEngineProvider);
  return LibreriaViewState.fromEngineState(engine.state);
});
