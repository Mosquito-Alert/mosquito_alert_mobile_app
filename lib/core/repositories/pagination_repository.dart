abstract class PaginationRepository<T, TApi> {
  final TApi itemApi;

  PaginationRepository({required this.itemApi});

  Future<(List<T> items, bool hasMore)> fetchPage({
    required int page,
    required int pageSize,
  });
}
