import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_music_site/core/errors.dart';
import 'package:ghost_music_site/core/storage.dart';
import 'package:ghost_music_site/models/album.dart';
import 'package:ghost_music_site/models/band_member.dart';
import 'package:ghost_music_site/models/concert.dart';
import 'package:ghost_music_site/repositories/ghost_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fromJson переживает пустые и null-поля', () {
    final album = Album.fromJson({'id': '4', 'title': null});
    expect(album.id, 4);
    expect(album.title, '');
    expect(album.albumType, 'studio');
    final member = BandMember.fromJson({'id': 1});
    expect(member.albumIds, isEmpty);
    expect(member.email, '');
    final concert = Concert.fromJson({'id': 2, 'date': null, 'memberIds': null});
    expect(concert.memberIds, isEmpty);
    expect(concert.status, 'plan');
  });

  test('каталожный номер альбома уникален', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repos = GhostRepositories(prefs);
    expect(
      () => repos.albums.save(const Album(
        id: 0,
        title: 'Копия',
        catalogCode: 'GH-ALB-001',
        albumType: 'studio',
        year: 2026,
        label: 'Loma Vista',
      )),
      throwsA(isA<FieldValidationException>()),
    );
  });

  test('альбом со связанными треками нельзя удалить', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repos = GhostRepositories(prefs);
    expect(
      () => repos.albums.softDelete(3),
      throwsA(isA<LinkedRecordsException>()),
    );
  });

  test('концерт не принимает участника с другого альбома', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repos = GhostRepositories(prefs);
    final concert = (await repos.concerts.findById(1))!;
    expect(
      () => repos.concerts.save(concert.copyWith(memberIds: const [2])),
      throwsA(isA<FieldValidationException>()),
    );
  });

  test('старый ключ хранилища мигрирует без падения', () async {
    SharedPreferences.setMockInitialValues({
      'ghost_site_albums_v1':
          '[{"id":1,"title":"Old","catalogCode":"GH-OLD","year":"2010"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final repos = GhostRepositories(prefs);
    final album = await repos.albums.findById(1);
    expect(album?.title, 'Old');
    expect(album?.year, 2010);
    expect(VersionedStore.takeNotice(prefs), contains('обновлены'));
    expect(prefs.getString('ghost_site_albums_v1'), isNull);
  });
}
