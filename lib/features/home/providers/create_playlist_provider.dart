import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';

// ─── STATE ─────────────────────────────────────────────────────

class CreatePlaylistState {
  final bool isLoading;
  final String? error;

  const CreatePlaylistState({this.isLoading = false, this.error});

  CreatePlaylistState copyWith({bool? isLoading, String? error}) =>
      CreatePlaylistState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

// ─── NOTIFIER ──────────────────────────────────────────────────

class CreatePlaylistNotifier extends StateNotifier<CreatePlaylistState> {
  final Ref _ref;

  CreatePlaylistNotifier(this._ref) : super(const CreatePlaylistState());

  Future<void> create({
    required String name,
    String? description,
    bool isPublic = false,
    int gradientIndex = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final router = _ref.read(routerProvider);
      final client = _ref.read(apiClientProvider(router));

      await client.post<Map<String, dynamic>>(
        '/playlists',
        data: {
          'name': name,
          if (description != null) 'Description': description,
          'isPublic': isPublic,
          'coverGradientIndex': gradientIndex,
        },
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// ─── PROVIDER ──────────────────────────────────────────────────

final createPlaylistProvider =
    StateNotifierProvider<CreatePlaylistNotifier, CreatePlaylistState>((ref) {
      return CreatePlaylistNotifier(ref);
    });
