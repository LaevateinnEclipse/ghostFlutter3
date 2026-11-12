import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/album.dart';
import '../models/album_query.dart';
import '../models/band_member.dart';
import '../models/band_member_query.dart';
import '../models/concert.dart';
import '../models/concert_query.dart';
import '../models/merch_item.dart';
import '../models/merch_query.dart';
import '../models/page_result.dart';
import '../models/track.dart';
import '../models/track_query.dart';
import '../repositories/album_repository.dart';
import '../repositories/band_member_repository.dart';
import '../repositories/concert_repository.dart';
import '../repositories/merch_repository.dart';
import '../repositories/track_repository.dart';

enum LoadStatus { idle, loading, success, error }

/// Общая загрузка страницы с отменой устаревшего запроса.
///
/// Пока пользователь набирает поиск, уходит несколько запросов. Ответ на
/// короткий запрос может прийти позже полного — тогда на экране окажутся
/// чужие данные. Новый запрос отменяет предыдущий.
mixin RemotePage<T> on ChangeNotifier {
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  PageResult<T> _result = PageResult.empty();
  final Set<int> _selected = {};
  CancelToken? _cancelToken;
  bool _disposed = false;

  LoadStatus get status => _status;
  String? get error => _error;
  PageResult<T> get result => _result;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<PageResult<T>> fetch(CancelToken cancelToken);
  String get failureText;

  void cancelPending() {
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('Запрос устарел');
    }
    _cancelToken = null;
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    _safeNotify();
    cancelPending();
    final token = CancelToken();
    _cancelToken = token;
    try {
      final page = await fetch(token);
      if (_disposed || token.isCancelled || !identical(token, _cancelToken)) {
        return;
      }
      _result = page;
      _status = LoadStatus.success;
    } on CancelledException {
      return;
    } on Object catch (error) {
      if (_disposed || token.isCancelled || !identical(token, _cancelToken)) {
        return;
      }
      _error = error is ApiException ? error.message : '$failureText: $error';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    _safeNotify();
  }

  void selectAll(Iterable<int> ids) {
    _selected
      ..clear()
      ..addAll(ids);
    _safeNotify();
  }

  void clear() {
    _selected.clear();
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelPending();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }
}

class MerchListNotifier extends ChangeNotifier with RemotePage<MerchItem> {
  MerchListNotifier(this._repo);
  final MerchRepository _repo;
  MerchQuery _query = const MerchQuery();
  MerchQuery get query => _query;

  @override
  String get failureText => 'Не удалось загрузить товары';

  @override
  Future<PageResult<MerchItem>> fetch(CancelToken cancelToken) =>
      _repo.find(_query, cancelToken: cancelToken);

  Future<void> applyQuery(MerchQuery query) async {
    _query = query;
    clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> deleteSelected(bool hard) async {
    if (hard) {
      await _repo.hardDeleteMany(_selected.toList());
    } else {
      await _repo.softDeleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }
}

class BandMemberListNotifier extends ChangeNotifier
    with RemotePage<BandMember> {
  BandMemberListNotifier(this._repo);
  final BandMemberRepository _repo;
  BandMemberQuery _query = const BandMemberQuery();
  BandMemberQuery get query => _query;

  @override
  String get failureText => 'Не удалось загрузить состав группы';

  @override
  Future<PageResult<BandMember>> fetch(CancelToken cancelToken) =>
      _repo.find(_query, cancelToken: cancelToken);

  Future<void> applyQuery(BandMemberQuery query) async {
    _query = query;
    clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> deleteSelected(bool hard) async {
    if (hard) {
      await _repo.hardDeleteMany(_selected.toList());
    } else {
      await _repo.softDeleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }
}

class AlbumListNotifier extends ChangeNotifier with RemotePage<Album> {
  AlbumListNotifier(this._repo);
  final AlbumRepository _repo;
  AlbumQuery _query = const AlbumQuery();
  AlbumQuery get query => _query;

  @override
  String get failureText => 'Не удалось загрузить альбомы';

  @override
  Future<PageResult<Album>> fetch(CancelToken cancelToken) =>
      _repo.find(_query, cancelToken: cancelToken);

  Future<void> applyQuery(AlbumQuery query) async {
    _query = query;
    clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> deleteSelected(bool hard) async {
    if (hard) {
      await _repo.hardDeleteMany(_selected.toList());
    } else {
      await _repo.softDeleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }
}

class TrackListNotifier extends ChangeNotifier with RemotePage<Track> {
  TrackListNotifier(this._repo);
  final TrackRepository _repo;
  TrackQuery _query = const TrackQuery();
  TrackQuery get query => _query;

  @override
  String get failureText => 'Не удалось загрузить треки';

  @override
  Future<PageResult<Track>> fetch(CancelToken cancelToken) =>
      _repo.find(_query, cancelToken: cancelToken);

  Future<void> applyQuery(TrackQuery query) async {
    _query = query;
    clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> deleteSelected(bool hard) async {
    if (hard) {
      await _repo.hardDeleteMany(_selected.toList());
    } else {
      await _repo.softDeleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }
}

class ConcertListNotifier extends ChangeNotifier with RemotePage<Concert> {
  ConcertListNotifier(this._repo);
  final ConcertRepository _repo;
  ConcertQuery _query = const ConcertQuery();
  ConcertQuery get query => _query;

  @override
  String get failureText => 'Не удалось загрузить концерты';

  @override
  Future<PageResult<Concert>> fetch(CancelToken cancelToken) =>
      _repo.find(_query, cancelToken: cancelToken);

  Future<void> applyQuery(ConcertQuery query) async {
    _query = query;
    clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repo.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repo.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> deleteSelected(bool hard) async {
    if (hard) {
      await _repo.hardDeleteMany(_selected.toList());
    } else {
      await _repo.softDeleteMany(_selected.toList());
    }
    _selected.clear();
    await load();
  }
}
