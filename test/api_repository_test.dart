import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_music_site/core/api_client.dart';
import 'package:ghost_music_site/core/api_exceptions.dart';
import 'package:ghost_music_site/models/album.dart';
import 'package:ghost_music_site/models/album_query.dart';
import 'package:ghost_music_site/repositories/api_album_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.responder);
  final Future<ResponseBody> Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _body(int status, Object payload) => ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _albumJson() => {
      'id': 1,
      'title': 'Meliora',
      'catalogCode': 'GH-ALB-003',
      'albumType': 'studio',
      'year': 2015,
      'label': 'Loma Vista',
      'coverUrl': 'covers/meliora.jpg',
      'memberIds': [1],
      'trackIds': [6],
      'concertIds': [10],
      'deletedAt': null,
    };

Dio _dio(_StubAdapter adapter) {
  final dio = buildDio();
  dio.httpClientAdapter = adapter;
  return dio;
}

Album _draft() => const Album(
      id: 0,
      title: 'Копия',
      catalogCode: 'GH-ALB-003',
      albumType: 'studio',
      year: 2026,
      label: 'Loma Vista',
    );

void main() {
  group('ApiAlbumRepository', () {
    test('разбирает страницу альбомов с сервера', () async {
      final adapter = _StubAdapter((_) async => _body(200, {
            'items': [_albumJson()],
            'page': 1,
            'size': 10,
            'total': 1,
          }));
      final result = await ApiAlbumRepository(_dio(adapter)).find(const AlbumQuery());
      expect(result.items, hasLength(1));
      expect(result.total, 1);
      expect(result.items.first.title, 'Meliora');
      expect(result.items.first.catalogCode, 'GH-ALB-003');
      expect(result.items.first.trackIds, [6]);
    });

    test('поиск, фильтры, сортировка и страница уходят на сервер', () async {
      final adapter = _StubAdapter((_) async => _body(200, {
            'items': [_albumJson()],
            'page': 2,
            'size': 25,
            'total': 30,
          }));
      await ApiAlbumRepository(_dio(adapter)).find(const AlbumQuery(
        search: ' meliora ',
        albumType: 'studio',
        yearFrom: 2010,
        yearTo: 2020,
        sortField: 'year',
        sortAscending: false,
        page: 2,
        size: 25,
        includeDeleted: true,
      ));
      final query = adapter.requests.single.queryParameters;
      expect(query['search'], 'meliora');
      expect(query['albumType'], 'studio');
      expect(query['yearFrom'], 2010);
      expect(query['yearTo'], 2020);
      expect(query['sort'], 'year,desc');
      expect(query['page'], 2);
      expect(query['size'], 25);
      expect(query['includeDeleted'], 'true');
    });

    test('ответ 422 становится ValidationException с полем каталожного номера', () async {
      final adapter = _StubAdapter((_) async => _body(422, {
            'message': 'Ошибка валидации',
            'errors': {'catalogCode': 'Альбом с таким каталожным номером уже есть'},
          }));
      expect(
        () => ApiAlbumRepository(_dio(adapter)).save(_draft()),
        throwsA(isA<ValidationException>().having(
          (error) => error.errorFor('catalogCode'),
          'catalogCode',
          'Альбом с таким каталожным номером уже есть',
        )),
      );
    });

    test('ответ 409 становится ConflictException', () async {
      final adapter = _StubAdapter((_) async => _body(409, {
            'message': 'Нельзя удалить альбом: связанных треков — 3, мерча — 2, концертов — 1',
          }));
      expect(
        () => ApiAlbumRepository(_dio(adapter)).softDelete(3),
        throwsA(isA<ConflictException>().having(
          (error) => error.message,
          'message',
          contains('связанных треков'),
        )),
      );
    });

    test('недоступный сервер становится NetworkException и чтение повторяется трижды', () async {
      final adapter = _StubAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final repository = ApiAlbumRepository(_dio(adapter));
      await expectLater(
        repository.find(const AlbumQuery()),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests, hasLength(3));
    });

    test('создание записи при сетевом сбое не повторяется', () async {
      final adapter = _StubAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      final repository = ApiAlbumRepository(_dio(adapter));
      await expectLater(repository.save(_draft()), throwsA(isA<NetworkException>()));
      expect(adapter.requests, hasLength(1));
    });
  });
}
