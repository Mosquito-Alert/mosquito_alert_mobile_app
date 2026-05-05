import 'package:flutter_test/flutter_test.dart';
import 'package:mosquito_alert_app/core/providers/pagination_provider.dart';
import 'package:mosquito_alert_app/core/repositories/pagination_repository.dart';

class FakePaginationRepository extends PaginationRepository<int, Object> {
  FakePaginationRepository() : super(itemApi: Object());

  final Map<int, (List<int>, bool)> responses = {};
  final Set<int> failingPages = {};

  @override
  Future<(List<int> items, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    if (failingPages.contains(page)) {
      throw Exception('page $page failed');
    }
    return responses[page] ?? (<int>[], false);
  }
}

class TestPaginatedProvider
    extends PaginatedProvider<int, FakePaginationRepository> {
  TestPaginatedProvider({required FakePaginationRepository repository})
    : super(repository: repository);
}

void main() {
  test('loadMore keeps pagination retryable after an error', () async {
    final repository = FakePaginationRepository()
      ..responses[1] = ([1, 2], true)
      ..failingPages.add(2);
    final provider = TestPaginatedProvider(repository: repository);

    await provider.loadInitial();

    expect(provider.items, [1, 2]);
    expect(provider.page, 1);
    expect(provider.hasMore, isTrue);

    await provider.loadMore();

    expect(provider.items, [1, 2]);
    expect(provider.page, 1);
    expect(provider.hasMore, isTrue);
    expect(provider.error, contains('page 2 failed'));

    repository
      ..failingPages.clear()
      ..responses[2] = ([3], false);

    await provider.loadMore();

    expect(provider.items, [1, 2, 3]);
    expect(provider.page, 2);
    expect(provider.hasMore, isFalse);
    expect(provider.error, isNull);
  });
}
