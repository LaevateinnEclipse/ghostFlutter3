import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../models/track_query.dart';
import '../state/catalog_notifier.dart';
import '../state/list_notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_table.dart';

class TrackListScreen extends StatefulWidget {
  final TrackQuery query;
  const TrackListScreen({super.key, required this.query});
  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void didUpdateWidget(covariant TrackListScreen old) {
    super.didUpdateWidget(old);
    if (old.query.toQueryParameters().toString() !=
        widget.query.toQueryParameters().toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sync());
    }
  }

  void sync() => context.read<TrackListNotifier>().applyQuery(widget.query);
  void go(TrackQuery q) {
    final p = q.toQueryParameters();
    context.go(p.isEmpty ? '/tracks' : Uri(path: '/tracks', queryParameters: p).toString());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final n = c.watch<TrackListNotifier>();
    final catalog = c.watch<CatalogNotifier>();
    return AppScaffold(
        title: 'Треки',
        index: 3,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => context.go('/tracks/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый трек')))),
          filters(n, catalog),
          if (n.hasSelection) selection(n),
          Expanded(child: body(n, catalog)),
          if (n.status == LoadStatus.success && n.result.total > 0)
            Pager(
                page: n.result.page,
                totalPages: n.result.totalPages,
                total: n.result.total,
                size: n.result.size,
                onPage: (x) => go(n.query.copyWith(page: x)),
                onSize: (x) => go(n.query.copyWith(size: x)))
        ]));
  }

  Widget filters(TrackListNotifier n, CatalogNotifier catalog) {
    final q = widget.query;
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: 260,
              child: TextFormField(
                  initialValue: q.search,
                  decoration: const InputDecoration(
                      labelText: 'Поиск по названию',
                      border: OutlineInputBorder()),
                  onChanged: (v) {
                    timer?.cancel();
                    timer = Timer(const Duration(milliseconds: 350),
                        () => go(q.copyWith(search: v)));
                  })),
          SizedBox(
              width: 240,
              child: DropdownButtonFormField<int?>(
                  initialValue: catalog.albums.any((album) => album.id == q.albumId)
                      ? q.albumId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Альбом', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Все альбомы')),
                    ...catalog.albums.map((a) => DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(a.title, overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (v) => go(q.copyWith(albumId: v)))),
          SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                  initialValue:
                      catalog.genres.contains(q.genre) ? q.genre : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Жанр', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все жанры')),
                    ...catalog.genres.map((g) => DropdownMenuItem<String?>(
                        value: g, child: Text(g, overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (v) => go(q.copyWith(genre: v)))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(
                value: q.includeDeleted,
                onChanged: (v) => go(q.copyWith(includeDeleted: v))),
            const Text('Удалённые')
          ]),
          TextButton(
              onPressed: q.hasActiveFilters
                  ? () => go(TrackQuery(
                      size: q.size,
                      sortField: q.sortField,
                      sortAscending: q.sortAscending))
                  : null,
              child: const Text('Сбросить'))
        ]));
  }

  Widget selection(TrackListNotifier n) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: [
        Text('Выбрано: ${n.selected.length}'),
        FilledButton(
            onPressed: () async {
              if (await confirm(context, 'Удалить выбранные треки?')) {
                await _run(() => n.deleteSelected(false));
              }
            },
            child: const Text('Удалить')),
        OutlinedButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть выбранные треки?', hard: true)) {
                await _run(() => n.deleteSelected(true));
              }
            },
            child: const Text('Стереть навсегда')),
        TextButton(onPressed: n.clear, child: const Text('Снять выделение'))
      ]));

  Widget body(TrackListNotifier n, CatalogNotifier catalog) {
    if (n.status == LoadStatus.idle || n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return StatusView(text: n.error ?? 'Ошибка', error: true, retry: n.load);
    }
    if (n.result.items.isEmpty) {
      return const StatusView(text: 'Треки не найдены.');
    }
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return ListView(
          children: [for (final t in n.result.items) card(n, catalog, t)]);
    }
    return EntityTable<Track>(
        items: n.result.items,
        id: (t) => t.id,
        selected: n.selected,
        toggle: n.toggle,
        sort: n.query.sortField,
        asc: n.query.sortAscending,
        onSort: (f) => go(n.query.copyWith(
            sortField: f,
            sortAscending: f == n.query.sortField ? !n.query.sortAscending : true)),
        columns: [
          (
            'Название',
            'title',
            (t) => Text(t.isDeleted ? '${t.title} (удалён)' : t.title)
          ),
          ('Альбом', null, (t) => Text(catalog.albumTitle(t.albumId))),
          ('№', 'trackNumber', (t) => Text('${t.trackNumber}')),
          ('Длительность', 'durationSeconds', (t) => Text(t.durationLabel)),
          ('Жанр', 'genre', (t) => Text(t.genre)),
        ],
        actions: (t) => actions(n, t));
  }

  Widget card(TrackListNotifier n, CatalogNotifier catalog, Track t) => Card(
      child: ListTile(
          leading: Checkbox(
              value: n.selected.contains(t.id), onChanged: (_) => n.toggle(t.id)),
          title: Text(t.title),
          subtitle: Text(
              '${catalog.albumTitle(t.albumId)}\n№${t.trackNumber} • ${t.durationLabel} • ${t.genre}'),
          isThreeLine: true,
          trailing: Wrap(children: actions(n, t))));

  List<Widget> actions(TrackListNotifier n, Track t) => [
        IconButton(
            tooltip: 'Карточка',
            onPressed: () => context.go('/tracks/${t.id}'),
            icon: const Icon(Icons.visibility_outlined)),
        IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/tracks/${t.id}/edit'),
            icon: const Icon(Icons.edit_outlined)),
        if (t.isDeleted)
          IconButton(
              onPressed: () => _run(() => n.restore(t.id)),
              icon: const Icon(Icons.restore))
        else
          IconButton(
              onPressed: () async {
                if (await confirm(context, 'Удалить трек «${t.title}»?')) {
                  await _run(() => n.softDelete(t.id));
                }
              },
              icon: const Icon(Icons.delete_outline)),
        IconButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть трек «${t.title}»?', hard: true)) {
                await _run(() => n.hardDelete(t.id));
              }
            },
            icon: const Icon(Icons.delete_forever))
      ];

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await context.read<CatalogNotifier>().load();
    } catch (error) {
      if (mounted) toast(context, '$error');
    }
  }
}
