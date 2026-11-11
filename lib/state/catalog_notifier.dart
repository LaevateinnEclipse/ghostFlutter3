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

  List<Album> get albums => List.unmodifiable(_albumOptions);
  List<BandMember> get members => List.unmodifiable(_memberOptions);
  List<Track> get tracks => List.unmodifiable(_trackOptions);
  List<MerchItem> get merch => List.unmodifiable(_merchOptions);
  List<Concert> get concerts => List.unmodifiable(_concertOptions);
  bool get loaded => _loaded;

  Future<void> load() async {
    _albumOptions = await _albums.all();
    _memberOptions = await _members.all();
    _trackOptions = await _tracks.all();
    _merchOptions = await _merch.all();
    _concertOptions = await _concerts.all();
    _loaded = true;
    notifyListeners();
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
