import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/core/network/api_client.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  ResponseBody? nextResponse;
  DioException? nextException;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse!;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient', () {
    late Dio dio;
    late FakeHttpClientAdapter adapter;
    late ApiClient client;

    setUp(() {
      adapter = FakeHttpClientAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.test.example'));
      dio.httpClientAdapter = adapter;
      client = ApiClient(dio);
    });

    test('getItems parses 200 OK paginated collection', () async {
      final jsonPayload = <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'prop-1', 'title': 'Villa 1'},
          <String, dynamic>{'id': 'prop-2', 'title': 'Apartment 2'},
        ],
        'page': 1,
        'page_size': 10,
        'total': 2,
        'has_more': false,
      };

      adapter.nextResponse = ResponseBody.fromString(
        jsonEncode(jsonPayload),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

      final response = await client.getItems(1, 10);
      expect(response.items, hasLength(2));
      expect(response.items[0].id, 'prop-1');
      expect(response.items[0].title, 'Villa 1');
      expect(response.hasMore, isFalse);
      expect(response.page, 1);
    });

    test('refresh parses 200 OK refresh response', () async {
      final jsonPayload = <String, dynamic>{
        'access_token': 'new_acc_tok',
        'refresh_token': 'new_ref_tok',
        'token_type': 'Bearer',
        'expires_in': 3600,
      };

      adapter.nextResponse = ResponseBody.fromString(
        jsonEncode(jsonPayload),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

      final response = await client.refresh(
        const RefreshRequestDto(refreshToken: 'old_ref_tok'),
      );

      expect(response.accessToken, 'new_acc_tok');
      expect(response.refreshToken, 'new_ref_tok');
      expect(response.expiresIn, 3600);
    });

    test('deleteItem handles 204 No Content successfully', () async {
      adapter.nextResponse = ResponseBody.fromString(
        '',
        204,
        headers: <String, List<String>>{},
      );

      expect(client.deleteItem('prop-1'), completes);
    });

    test('error status throws DioException with response preserved', () async {
      adapter.nextResponse = ResponseBody.fromString(
        jsonEncode(<String, dynamic>{'error': 'Forbidden'}),
        403,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

      expect(
        () => client.getItems(1, 10),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });
}
