import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/network/api_client.dart';
import 'package:base/src/core/storage/session.dart';

void main() {
  group('DTO and Mapper tests', () {
    test('ItemDto serializes and deserializes correctly', () {
      final json = <String, dynamic>{'id': 'item-123', 'title': 'Test Item'};

      final dto = ItemDto.fromJson(json);
      expect(dto.id, 'item-123');
      expect(dto.title, 'Test Item');

      final serialized = dto.toJson();
      expect(serialized['id'], 'item-123');
      expect(serialized['title'], 'Test Item');
    });

    test('PagedResponseDto serializes and deserializes snake_case fields', () {
      final json = <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': '1', 'title': 'First'},
          <String, dynamic>{'id': '2', 'title': 'Second'},
        ],
        'page': 1,
        'page_size': 20,
        'total': 100,
        'has_more': true,
      };

      final pagedDto = PagedResponseDto<ItemDto>.fromJson(
        json,
        (obj) => ItemDto.fromJson(obj! as Map<String, dynamic>),
      );

      expect(pagedDto.page, 1);
      expect(pagedDto.pageSize, 20);
      expect(pagedDto.total, 100);
      expect(pagedDto.hasMore, isTrue);
      expect(pagedDto.items.length, 2);
      expect(pagedDto.items.first.title, 'First');

      final serialized = pagedDto.toJson((item) => item.toJson());
      expect(serialized['page_size'], 20);
      expect(serialized['has_more'], isTrue);
      expect(serialized['items'], hasLength(2));
    });

    test('RefreshRequestDto formats snake_case refresh_token payload', () {
      const dto = RefreshRequestDto(refreshToken: 'token_abc');
      final json = dto.toJson();
      expect(json['refresh_token'], 'token_abc');

      final deserialized = RefreshRequestDto.fromJson(json);
      expect(deserialized.refreshToken, 'token_abc');
    });

    test('RefreshResponseDto deserializes and maps to Session', () {
      final json = <String, dynamic>{
        'access_token': 'new_access_123',
        'refresh_token': 'new_refresh_456',
        'token_type': 'Bearer',
        'expires_in': 3600,
      };

      final dto = RefreshResponseDto.fromJson(json);
      expect(dto.accessToken, 'new_access_123');
      expect(dto.refreshToken, 'new_refresh_456');
      expect(dto.tokenType, 'Bearer');
      expect(dto.expiresIn, 3600);

      final fixedNow = DateTime.utc(2026, 10, 31, 12);
      final session = dto.toSession(now: fixedNow);

      expect(session, isA<Session>());
      expect(session.accessToken, 'new_access_123');
      expect(session.refreshToken, 'new_refresh_456');
      expect(session.tokenType, 'Bearer');
      expect(session.expiresAt, fixedNow.add(const Duration(seconds: 3600)));
    });
  });
}
