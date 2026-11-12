import 'package:flutter/foundation.dart';
import '../data/seed_data.dart';
import '../models/album.dart';
import '../models/band_member.dart';
import '../models/concert.dart';
import '../models/merch_item.dart';
import '../models/track.dart';
import '../repositories/album_repository.dart';
import '../repositories/band_member_repository.dart';
import '../repositories/concert_repository.dart';
import '../repositories/merch_repository.dart';
import '../repositories/track_repository.dart';

class CatalogNotifier extends ChangeNotifier {
  CatalogNotifier({
    required AlbumRepository albums,
    required BandMemberRepository members,
    required TrackRepository tracks,
    required MerchRepository merch,
    required ConcertRepository concerts,
  })  : _albums = albums,
        _members = members,
        _tracks = tracks,
        _merch = merch,
        _concerts = concerts;

  final AlbumRepository _albums;
  final BandMemberRepository _members;
  final TrackRepository _tracks;
  final MerchRepository _merch;
  final ConcertRepository _concerts;
  List<Album> _albumOptions = [];
  List<BandMember> _memberOptions = [];
  List<Track> _trackOptions = [];
  List<MerchItem> _merchOptions = [];
  List<Concert> _concertOptions = [];
  bool _loaded = false;
  bool _loading = false;
  String? _error;
  DateTime? _loadedAt;
  Future<void>? _pending;
  bool _disposed = false;

  List<Album> get albums => List.unmodifiable(_albumOptions);
  List<BandMember> get members => List.unmodifiable(_memberOptions);
  List<Track> get tracks => List.unmodifiable(_trackOptions);
  List<MerchItem> get merch => List.unmodifiable(_merchOptions);
  List<Concert> get concerts => List.unmodifiable(_concertOptions);
  bool get loaded => _loaded;
  bool get loading => _loading;
  String? get error => _error;

  /// Справочники запрашиваются один раз и держатся пять минут.
  /// Повторное открытие формы не ходит на сервер, пока кэш свежий.
  Future<void> load({
    bool force = false,
    Duration refetchAfter = const Duration(minutes: 5),
  }) {
    return _pending ??= _load(force: force, refetchAfter: refetchAfter)
        .whenComplete(() => _pending = null);
  }

  Future<void> _load({
    required bool force,
    required Duration refetchAfter,
  }) async {
    final loadedAt = _loadedAt;
    if (!force &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < refetchAfter) {
      return;
    }
    if (_loading) return;
    _loading = true;
    _error = null;
    _safeNotify();
    try {
      final results = await Future.wait([
        _albums.all(),
        _members.all(),
        _tracks.all(),
        _merch.all(),
        _concerts.all(),
      ]);
      _albumOptions = results[0] as List<Album>;
      _memberOptions = results[1] as List<BandMember>;
      _trackOptions = results[2] as List<Track>;
      _merchOptions = results[3] as List<MerchItem>;
      _concertOptions = results[4] as List<Concert>;
      _loaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } on Object catch (error) {
      _error = '$error';
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String albumTitle(int id) {
    for (final album in _albumOptions) {
      if (album.id == id) return album.title;
    }
    return 'Альбом #$id';
  }

  String memberName(int id) {
    for (final member in _memberOptions) {
      if (member.id == id) return member.fullName;
    }
    return 'Участник #$id';
  }

  List<String> get albumTypes => Album.types;
  List<String> get roles {
    final values = {...bandRoles, ..._memberOptions.map((member) => member.role)}
        .where((role) => role.trim().isNotEmpty)
        .toList()
      ..sort();
    return values;
  }

  List<String> get categories {
    final values = {
      ...merchCategories,
      ..._merchOptions.map((item) => item.category)
    }.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    return values;
  }

  List<String> get genres {
    final values = {...trackGenres, ..._trackOptions.map((track) => track.genre)}
        .where((value) => value.trim().isNotEmpty)
        .toList()
      ..sort();
    return values;
  }

  List<String> get cities {
    final values = _concertOptions
        .map((concert) => concert.city)
        .where((city) => city.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }
}
