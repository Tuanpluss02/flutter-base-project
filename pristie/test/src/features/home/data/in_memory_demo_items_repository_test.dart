import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/features/home/data/repositories/in_memory_demo_items_repository.dart';

void main() {
  group('InMemoryDemoItemsRepository', () {
    final repository = InMemoryDemoItemsRepository();

    test('provides three stable pages of twenty demo items', () async {
      for (var page = 1; page <= 3; page++) {
        final result = await repository.getPage(page);
        expect(result, isA<Ok>());
        final data = (result as Ok).data;
        expect(data.items, hasLength(20));
        expect(data.items.first.id, (page - 1) * 20 + 1);
        expect(data.items.last.id, page * 20);
        expect(data.hasMore, page < 3);
      }
    });

    test('returns an empty terminal page after the third page', () async {
      final result = await repository.getPage(4);

      final data = (result as Ok).data;
      expect(data.items, isEmpty);
      expect(data.hasMore, isFalse);
    });

    test('rejects pages below one with an empty terminal page', () async {
      final result = await repository.getPage(0);

      final data = (result as Ok).data;
      expect(data.items, isEmpty);
      expect(data.hasMore, isFalse);
    });
  });
}
