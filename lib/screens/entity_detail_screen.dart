import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

class EntityDetailScreen extends StatefulWidget {
  final String collection;
  final int id;
  const EntityDetailScreen(
      {super.key, required this.collection, required this.id});
  @override
  State<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends State<EntityDetailScreen> {
  late final Future<Map<String, String>?> _details = _load();

  Future<Map<String, String>?> _load() async {
    final albums = context.read<AlbumRepository>();
    final members = context.read<BandMemberRepository>();
    final tracks = context.read<TrackRepository>();
    final merch = context.read<MerchRepository>();
    final concerts = context.read<ConcertRepository>();
    final Object? record = switch (widget.collection) {
      'albums' => await albums.findById(widget.id),
      'members' => await members.findById(widget.id),
      'tracks' => await tracks.findById(widget.id),
      'merch' => await merch.findById(widget.id),
      'concerts' => await concerts.findById(widget.id),
      _ => null,
    };
    if (record == null) return null;
    final albumNames = {
      for (final album in await albums.all(includeDeleted: true))
        album.id: album.title
    };
    final memberNames = {
      for (final member in await members.all(includeDeleted: true))
        member.id: member.fullName
    };
    String names(List<int> ids, Map<int, String> options) => ids.isEmpty
        ? '—'
        : ids.map((id) => options[id] ?? '#$id').join(', ');
    String date(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final rows = <String, String>{'Номер записи': '${widget.id}'};
    switch (record) {
      case Album album:
        rows.addAll({
          'Название': album.title,
          'Каталожный номер': album.catalogCode,
          'Тип': albumTypeLabel(album.albumType),
          'Год': '${album.year}',
          'Лейбл': album.label,
          'Обложка': album.coverUrl.isEmpty ? '—' : album.coverUrl,
          'Участники': names(album.memberIds, memberNames),
          'Треки': names(album.trackIds, {
            for (final track in await tracks.all(includeDeleted: true))
              track.id: track.title
          }),
          'Концерты': album.concertIds.isEmpty
              ? '—'
              : album.concertIds.map((id) => '#$id').join(', '),
          'Состояние': album.isDeleted ? 'Удалено' : 'Активно',
        });
      case BandMember member:
        rows.addAll({
          'Участник': member.fullName,
          'Роль': member.role,
          'Почта': member.email,
          'Год вступления': '${member.joinedYear}',
          'Лет в группе': '${member.yearsInBand}',
          'Гонорар': '${member.fee} ₽',
          'Фото': member.photoUrl.isEmpty ? '—' : member.photoUrl,
          'Биография': member.bio.isEmpty ? '—' : member.bio,
          'Альбомы': names(member.albumIds, albumNames),
          'Концерты': member.concertIds.isEmpty
              ? '—'
              : member.concertIds.map((id) => '#$id').join(', '),
          'Сценическое имя': member.stageName,
          'Код маски': member.maskCode,
          'Образ назначен': member.appointedOn,
          'Состояние': member.isDeleted ? 'Удалено' : 'Активно',
        });
      case Track track:
        rows.addAll({
          'Название': track.title,
          'Альбом': albumNames[track.albumId] ?? '#${track.albumId}',
          'Номер': '${track.trackNumber}',
          'Длительность': track.durationLabel,
          'Жанр': track.genre,
          'Состояние': track.isDeleted ? 'Удалено' : 'Активно',
        });
      case MerchItem item:
        rows.addAll({
          'Название': item.name,
          'Артикул': item.sku,
          'Категория': item.category,
          'Альбом': albumNames[item.albumId] ?? '#${item.albumId}',
          'Остаток': '${item.stock} шт.',
          'Цена': '${item.price} ₽',
          'Состояние': item.isDeleted ? 'Удалено' : 'Активно',
        });
      case Concert concert:
        rows.addAll({
          'Город': concert.city,
          'Площадка': concert.venue,
          'Дата': date(concert.date),
          'Альбом': albumNames[concert.albumId] ?? '#${concert.albumId}',
          'Состав': names(concert.memberIds, memberNames),
          'Код билета': concert.ticketCode,
          'Цена': '${concert.ticketPrice} ₽',
          'Почта': concert.contactEmail,
          'Статус': concertStatusLabel(concert.status),
          'Состояние': concert.isDeleted ? 'Удалено' : 'Активно',
        });
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/${widget.collection}')),
          title: const Text('Карточка'),
          actions: [
            IconButton(
                tooltip: 'Редактировать',
                onPressed: () =>
                    context.go('/${widget.collection}/${widget.id}/edit'),
                icon: const Icon(Icons.edit_outlined))
          ],
        ),
        body: FutureBuilder<Map<String, String>?>(
          future: _details,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data;
            if (rows == null) {
              return const Center(child: Text('Запись не найдена'));
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                for (final row in rows.entries)
                  ListTile(
                    title: Text(row.key),
                    subtitle: Text(row.value.isEmpty ? '—' : row.value),
                  )
              ],
            );
          },
        ),
      );
}
