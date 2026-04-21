import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';

abstract class PaginatedProvider<
  T,
  TRepository extends PaginationRepository<T, dynamic>
>
    extends ChangeNotifier {
  final TRepository repository;
  final List<T> Function(List<T>)? orderFunction;

  PaginatedProvider({required this.repository, this.orderFunction});

  bool loadedInitial = false;

  List<T> _items = [];

  List<T> get items => _items;

  void addItem(T item) {
    _items.insert(0, item);
    if (orderFunction != null) {
      _items = orderFunction!(_items);
    }
    notifyListeners();
  }

  void deleteItem(T item) {
    _items.removeWhere((element) => element == item);
    notifyListeners();
  }

  bool isLoading = false;
  bool isRefreshing = false;
  bool hasMore = true;
  int page = 0;
  int pageSize = 20;
  String? error;

  /// Implement this in your feature provider.
  Future<(List<T> items, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) {
    return repository.fetchPage(page: page, pageSize: pageSize);
  }

  // Load first page
  Future<void> loadInitial() async {
    isLoading = true;
    error = null;
    loadedInitial = false;
    notifyListeners();
    try {
      page = 1;
      hasMore = true;
      loadedInitial = true;
      final (newItems, newHasMore) = await fetchPage(
        page: page,
        pageSize: pageSize,
      );
      this._items = newItems;
      hasMore = newHasMore;
    } catch (e) {
      error = e.toString();
      page = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load more pages (infinite scroll)
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    int nextPage = page + 1;
    try {
      final (newItems, newHasMore) = await fetchPage(
        page: nextPage,
        pageSize: pageSize,
      );
      this._items.addAll(newItems);
      hasMore = newHasMore;
    } catch (e) {
      error = e.toString();
      hasMore = false;
      nextPage = page; // stay on the same page on error
    } finally {
      page = nextPage;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isRefreshing) return; // prevent double refresh
    isRefreshing = true;
    error = null;
    hasMore = true;
    notifyListeners();

    try {
      await loadInitial();
    } catch (e) {
      error = e.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }
}
