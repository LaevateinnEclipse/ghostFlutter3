import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import 'in_memory_album_repository.dart';
import 'in_memory_band_member_repository.dart';
import 'in_memory_concert_repository.dart';
import 'in_memory_merch_repository.dart';
import 'in_memory_track_repository.dart';

/// Связи и запрет удаления применяются и к одиночным, и к массовым операциям.
class GhostRepositories {
  final InMemoryAlbumRepository albums;
  final InMemoryBandMemberRepository members;
  final InMemoryTrackRepository tracks;
  final InMemoryMerchRepository merch;
  final InMemoryConcertRepository concerts;

  GhostRepositories(SharedPreferences prefs)
      : albums = InMemoryAlbumRepository(prefs),
        members = InMemoryBandMemberRepository(prefs),
        tracks = InMemoryTrackRepository(prefs),
        merch = InMemoryMerchRepository(prefs),
        concerts = InMemoryConcertRepository(prefs) {
    albums.deletionGuard = (ids, hard) async {
      final trackCount = tracks.items
          .where((track) =>
              ids.contains(track.albumId) && (hard || !track.isDeleted))
          .length;
      final merchCount = merch.items
          .where((item) =>
              ids.contains(item.albumId) && (hard || !item.isDeleted))
          .length;
      final concertCount = concerts.items
          .where((concert) =>
              ids.contains(concert.albumId) && (hard || !concert.isDeleted))
          .length;
      final count = trackCount + merchCount + concertCount;
      if (count > 0) {
        throw LinkedRecordsException(
            'Нельзя удалить альбом: связанных треков — $trackCount, мерча — $merchCount, концертов — $concertCount',
            count);
      }
    };
    members.deletionGuard = (ids, hard) async {
      final count = concerts.items
          .where((concert) =>
              concert.memberIds.any(ids.contains) &&
              (hard || !concert.isDeleted))
          .length;
      if (count > 0) {
        throw LinkedRecordsException(
            'Нельзя удалить участника: связанных концертов — $count', count);
      }
    };
    concerts.saveGuard = (concert) async {
      final album = await albums.findById(concert.albumId);
      if (album == null || album.isDeleted) {
        throw const FieldValidationException(
            'albumId', 'Выберите существующий активный альбом');
      }
      if (concert.memberIds.isEmpty) {
        throw const FieldValidationException(
            'memberIds', 'Выберите хотя бы одного участника');
      }
      for (final id in concert.memberIds) {
        final member = await members.findById(id);
        if (member == null ||
            member.isDeleted ||
            (member.albumIds.isNotEmpty &&
                !member.albumIds.contains(album.id))) {
          throw const FieldValidationException('memberIds',
              'Участник не записан на выбранном альбоме');
        }
      }
    };
    tracks.saveGuard = (track) async {
      final album = await albums.findById(track.albumId);
      if (album == null || album.isDeleted) {
        throw const FieldValidationException(
            'albumId', 'Выберите существующий активный альбом');
      }
    };
    merch.saveGuard = (item) async {
      final album = await albums.findById(item.albumId);
      if (album == null || album.isDeleted) {
        throw const FieldValidationException(
            'albumId', 'Выберите существующий активный альбом');
      }
    };
    members.saveGuard = (member) async {
      if (member.albumIds.isEmpty) {
        throw const FieldValidationException(
            'albumIds', 'Выберите хотя бы один альбом');
      }
      for (final id in member.albumIds) {
        final album = await albums.findById(id);
        if (album == null || album.isDeleted) {
          throw const FieldValidationException(
              'albumIds', 'Выберите существующие активные альбомы');
        }
      }
      final invalid = concerts.items.any((concert) =>
          !concert.isDeleted &&
          concert.memberIds.contains(member.id) &&
          !member.albumIds.contains(concert.albumId));
      if (invalid) {
        throw const FieldValidationException('albumIds',
            'Нельзя убрать альбом, пока участник заявлен на его концерты');
      }
    };
    concerts.afterChange = synchronizeLinks;
    tracks.afterChange = synchronizeLinks;
    merch.afterChange = synchronizeLinks;
    members.afterChange = synchronizeLinks;
  }

  Future<void> synchronizeLinks() async {
    for (final album in albums.items) {
      albums.replace(album.copyWith(
        trackIds: tracks.items
            .where((track) => track.albumId == album.id)
            .map((track) => track.id)
            .toList(),
        concertIds: concerts.items
            .where((concert) => concert.albumId == album.id)
            .map((concert) => concert.id)
            .toList(),
        memberIds: members.items
            .where((member) => member.albumIds.contains(album.id))
            .map((member) => member.id)
            .toList(),
      ));
    }
    for (final member in members.items) {
      members.replace(member.copyWith(
        concertIds: concerts.items
            .where((concert) => concert.memberIds.contains(member.id))
            .map((concert) => concert.id)
            .toList(),
      ));
    }
    await albums.persist();
    await members.persistOnly();
  }
}
