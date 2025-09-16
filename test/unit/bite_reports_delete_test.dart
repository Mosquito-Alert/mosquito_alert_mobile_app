import 'package:flutter_test/flutter_test.dart';
import '../mocks/mocks.dart';

void main() {
  group('Bite Reports Delete API Tests', () {
    late MockMosquitoAlert mockClient;
    late MockBitesApi mockBitesApi;

    setUp(() {
      mockClient = MockMosquitoAlert();
      mockBitesApi = mockClient.bitesApi;
    });

    test('should successfully delete bite report', () async {
      // Given
      const testUuid = 'test-bite-uuid-123';
      final initialBites = [
        createTestBite(uuid: testUuid, totalBites: 2),
        createTestBite(uuid: 'other-bite', totalBites: 3),
      ];
      mockBitesApi.setBites(initialBites);

      // When
      final response = await mockBitesApi.destroy(uuid: testUuid);

      // Then
      expect(response.statusCode, equals(204)); // No Content
      expect(mockBitesApi.destroyCalled, isTrue);
      expect(mockBitesApi.lastDestroyedUuid, equals(testUuid));

      // Verify the bite was removed from mock data
      final remainingBites = await mockBitesApi.listMine();
      final bites = remainingBites.data?.results?.toList() ?? [];
      expect(bites.length, equals(1));
      expect(bites.first.uuid, equals('other-bite'));
    });

    test('should handle delete failure', () async {
      // Given
      const testUuid = 'test-bite-uuid-fail';
      mockBitesApi.shouldFailDestroy = true;

      // When & Then
      expect(
        () async => await mockBitesApi.destroy(uuid: testUuid),
        throwsA(isA<Exception>()),
      );

      expect(mockBitesApi.destroyCalled, isTrue);
      expect(mockBitesApi.lastDestroyedUuid, equals(testUuid));
    });

    test('should validate UUID parameter', () async {
      // Given
      const emptyUuid = '';

      // When & Then - should still attempt the call with empty UUID
      final response = await mockBitesApi.destroy(uuid: emptyUuid);

      expect(response.statusCode, equals(204));
      expect(mockBitesApi.destroyCalled, isTrue);
      expect(mockBitesApi.lastDestroyedUuid, equals(emptyUuid));
    });

    test('should handle valid UUID format', () async {
      // Given
      const validUuid =
          '550e8400-e29b-41d4-a716-446655440000'; // Valid UUID format
      mockBitesApi.setBites([
        createTestBite(uuid: validUuid, totalBites: 1),
      ]);

      // When
      final response = await mockBitesApi.destroy(uuid: validUuid);

      // Then
      expect(response.statusCode, equals(204));
      expect(mockBitesApi.destroyCalled, isTrue);
      expect(mockBitesApi.lastDestroyedUuid, equals(validUuid));
      expect(
          validUuid.length, equals(36)); // UUID should be exactly 36 characters
    });

    test('should remove bite from list after successful delete', () async {
      // Given
      const biteToDelete = 'bite-to-delete';
      const biteToKeep = 'bite-to-keep';

      final initialBites = [
        createTestBite(uuid: biteToDelete, totalBites: 1),
        createTestBite(uuid: biteToKeep, totalBites: 2),
      ];
      mockBitesApi.setBites(initialBites);

      // Verify initial state
      var allBites = await mockBitesApi.listMine();
      expect(allBites.data?.results?.length, equals(2));

      // When
      await mockBitesApi.destroy(uuid: biteToDelete);

      // Then
      allBites = await mockBitesApi.listMine();
      final remainingBites = allBites.data?.results?.toList() ?? [];

      expect(remainingBites.length, equals(1));
      expect(remainingBites.first.uuid, equals(biteToKeep));
      expect(remainingBites.any((bite) => bite.uuid == biteToDelete), isFalse);
    });

    test('should not remove bite from list if delete fails', () async {
      // Given
      const biteUuid = 'bite-delete-fail';
      final initialBites = [
        createTestBite(uuid: biteUuid, totalBites: 1),
      ];
      mockBitesApi.setBites(initialBites);
      mockBitesApi.shouldFailDestroy = true;

      // Verify initial state
      var allBites = await mockBitesApi.listMine();
      expect(allBites.data?.results?.length, equals(1));

      // When & Then
      expect(
        () async => await mockBitesApi.destroy(uuid: biteUuid),
        throwsA(isA<Exception>()),
      );

      // Verify bite is still in the list (delete failed)
      allBites = await mockBitesApi.listMine();
      final remainingBites = allBites.data?.results?.toList() ?? [];
      expect(remainingBites.length, equals(1));
      expect(remainingBites.first.uuid, equals(biteUuid));
    });
  });
}
