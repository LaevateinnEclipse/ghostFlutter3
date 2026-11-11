import 'package:flutter/foundation.dart';
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

class MerchListNotifier extends ChangeNotifier {
  MerchListNotifier(this._repo);
  final MerchRepository _repo;
  MerchQuery _query = const MerchQuery();
  PageResult<MerchItem> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  MerchQuery get query => _query;
  PageResult<MerchItem> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  Future<void> applyQuery(MerchQuery q) async {
    _query = q;
    _selected.clear();
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить товары: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    _selected
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
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

class BandMemberListNotifier extends ChangeNotifier {
  BandMemberListNotifier(this._repo);
  final BandMemberRepository _repo;
  BandMemberQuery _query = const BandMemberQuery();
  PageResult<BandMember> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  BandMemberQuery get query => _query;
  PageResult<BandMember> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  Future<void> applyQuery(BandMemberQuery q) async {
    _query = q;
    _selected.clear();
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить состав группы: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    _selected
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
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

class AlbumListNotifier extends ChangeNotifier {
  AlbumListNotifier(this._repo);
  final AlbumRepository _repo;
  AlbumQuery _query = const AlbumQuery();
  PageResult<Album> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  AlbumQuery get query => _query;
  PageResult<Album> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  Future<void> applyQuery(AlbumQuery q) async {
    _query = q;
    _selected.clear();
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить альбомы: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
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

class TrackListNotifier extends ChangeNotifier {
  TrackListNotifier(this._repo);
  final TrackRepository _repo;
  TrackQuery _query = const TrackQuery();
  PageResult<Track> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  TrackQuery get query => _query;
  PageResult<Track> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  Future<void> applyQuery(TrackQuery q) async {
    _query = q;
    _selected.clear();
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить треки: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
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

class ConcertListNotifier extends ChangeNotifier {
  ConcertListNotifier(this._repo);
  final ConcertRepository _repo;
  ConcertQuery _query = const ConcertQuery();
  PageResult<Concert> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  ConcertQuery get query => _query;
  PageResult<Concert> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  Future<void> applyQuery(ConcertQuery q) async {
    _query = q;
    _selected.clear();
    await load();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repo.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить концерты: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggle(int id) {
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
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