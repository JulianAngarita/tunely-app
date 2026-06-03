import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunely/core/router/app_router_with_deeplink.dart';
import '../../../core/network/api_client.dart';
import '../models/search_result_model.dart';

// ─── FILTER STATE ──────────────────────────────────────────────

enum SearchFilter { all, spotify, youtube }

final searchFilterProvider = StateProvider<SearchFilter>(
  (_) => SearchFilter.all,
);

// ─── SEARCH STATE ──────────────────────────────────────────────

class SearchState {
  final String query;
  final List<SearchResultModel> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResultModel>? results,
    bool? isLoading,
    String? error,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  // Filtrar resultados según el filtro activo
  List<SearchResultModel> filtered(SearchFilter filter) {
    if (filter == SearchFilter.all) return results;
    if (filter == SearchFilter.spotify) {
      return results
          .where((r) => r.platform == SearchPlatform.spotify)
          .toList();
    }
    return results.where((r) => r.platform == SearchPlatform.youtube).toList();
  }
}

// ─── NOTIFIER ──────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounce;

  SearchNotifier(this._ref) : super(const SearchState());

  void onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: query, isLoading: true);
    // Debounce 400ms para no hacer request en cada tecla
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final router = _ref.read(routerProvider);
      final client = _ref.read(apiClientProvider(router));

      final response = await client.get('/songs/search', params: {'q': query});

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final spotify = (data['spotify'] as List<dynamic>?) ?? [];
      final youtube = (data['youtube'] as List<dynamic>?) ?? [];

      final results = [
        ...spotify.map(
          (e) => SearchResultModel.fromSpotify(e as Map<String, dynamic>),
        ),
        ...youtube.map(
          (e) => SearchResultModel.fromYoutube(e as Map<String, dynamic>),
        ),
      ];

      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Marcar canción como agregada en la UI sin refetch
  void markAsAdded(String resultId) {
    final updated = state.results.map((r) {
      if (r.id == resultId) r.isAdded = true;
      return r;
    }).toList();
    state = state.copyWith(results: updated);
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ─── PROVIDER ──────────────────────────────────────────────────

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier(ref);
});
