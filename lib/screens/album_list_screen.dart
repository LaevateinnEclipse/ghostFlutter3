import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/seed_data.dart';
import '../models/album.dart';
import '../models/album_query.dart';
import '../state/catalog_notifier.dart';
import '../state/list_notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_table.dart';

class AlbumListScreen extends StatefulWidget {
  final AlbumQuery query;
  const AlbumListScreen({super.key, required this.query});
  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void didUpdateWidget(covariant AlbumListScreen old) {
    super.didUpdateWidget(old);
    if (old.query.toQueryParameters().toString() !=
        widget.query.toQueryParameters().toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sync());
    }
  }

  void sync() => context.read<AlbumListNotifier>().applyQuery(widget.query);
  void go(AlbumQuery q) {
    final p = q.toQueryParameters();
    context.go(p.isEmpty ? '/albums' : Uri(path: '/albums', queryParameters: p).toString());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final n = c.watch<AlbumListNotifier>();
    return AppScaffold(
        title: 'Дискография',
        index: 2,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => context.go('/albums/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый альбом')))),
          filters(n),
          if (n.hasSelection) selection(n),
          Expanded(child: body(n)),
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

  Widget filters(AlbumListNotifier n) {
    final q = widget.query;
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: 280,
              child: TextFormField(
                  initialValue: q.search,
                  decoration: const InputDecoration(
                      labelText: 'Поиск: название, код или лейбл',
                      border: OutlineInputBorder()),
                  onChanged: (v) {
                    timer?.cancel();
                    timer = Timer(const Duration(milliseconds: 350),
                        () => go(q.copyWith(search: v)));
                  })),
          SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                  initialValue: q.albumType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Тип', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все типы')),
                    ...Album.types.map((v) => DropdownMenuItem<String?>(
                        value: v, child: Text(albumTypeLabel(v))))
                  ],
                  onChanged: (v) => go(q.copyWith(albumType: v)))),
          SizedBox(
              width: 110,
              child: TextFormField(
                  initialValue: q.yearFrom?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Год от', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      go(q.copyWith(yearFrom: int.tryParse(v))))),
          SizedBox(
              width: 110,
              child: TextFormField(
                  initialValue: q.yearTo?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Год до', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      go(q.copyWith(yearTo: int.tryParse(v))))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(
                value: q.includeDeleted,
                onChanged: (v) => go(q.copyWith(includeDeleted: v))),
            const Text('Удалённые')
          ]),
          TextButton(
              onPressed: q.hasActiveFilters
                  ? () => go(AlbumQuery(
                      size: q.size,
                      sortField: q.sortField,
                      sortAscending: q.sortAscending))
                  : null,
              child: const Text('Сбросить'))
        ]));
  }

  Widget selection(AlbumListNotifier n) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: [
        Text('Выбрано: ${n.selected.length}'),
        FilledButton(
            onPressed: () async {
              if (await confirm(context, 'Удалить выбранные альбомы?')) {
                await _run(() => n.deleteSelected(false));
              }
            },
            child: const Text('Удалить')),
        OutlinedButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть выбранные альбомы?',
                  hard: true)) {
                await _run(() => n.deleteSelected(true));
              }
            },
            child: const Text('Стереть навсегда')),
        TextButton(onPressed: n.clear, child: const Text('Снять выделение'))
      ]));

  Widget body(AlbumListNotifier n) {
    if (n.status == LoadStatus.idle || n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return StatusView(text: n.error ?? 'Ошибка', error: true, retry: n.load);
    }
    if (n.result.items.isEmpty) {
      return const StatusView(text: 'Альбомы не найдены.');
    }
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return ListView(children: [for (final a in n.result.items) card(n, a)]);
    }
    return EntityTable<Album>(
        items: n.result.items,
        id: (a) => a.id,
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
            (a) => Text(a.isDeleted ? '${a.title} (удалён)' : a.title)
          ),
          ('Код', null, (a) => Text(a.catalogCode)),
          ('Тип', 'albumType', (a) => Text(albumTypeLabel(a.albumType))),
          ('Год', 'year', (a) => Text('${a.year}')),
          ('Лейбл', 'label', (a) => Text(a.label)),
        ],
        actions: (a) => actions(n, a));
  }

  Widget card(AlbumListNotifier n, Album a) => Card(
      child: ListTile(
          leading: Checkbox(
              value: n.selected.contains(a.id), onChanged: (_) => n.toggle(a.id)),
          title: Text(a.title),
          subtitle: Text(
              '${a.catalogCode} • ${albumTypeLabel(a.albumType)}\n${a.year}, ${a.label}'),
          isThreeLine: true,
          trailing: Wrap(children: actions(n, a))));

  List<Widget> actions(AlbumListNotifier n, Album a) => [
        IconButton(
            tooltip: 'Карточка',
            onPressed: () => context.go('/albums/${a.id}'),
            icon: const Icon(Icons.visibility_outlined)),
        IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/albums/${a.id}/edit'),
            icon: const Icon(Icons.edit_outlined)),
        if (a.isDeleted)
          IconButton(
              onPressed: () => _run(() => n.restore(a.id)),
              icon: const Icon(Icons.restore))
        else
          IconButton(
              onPressed: () async {
                if (await confirm(context, 'Удалить альбом «${a.title}»?')) {
                  await _run(() => n.softDelete(a.id));
                }
              },
              icon: const Icon(Icons.delete_outline)),
        IconButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть альбом «${a.title}»?',
                  hard: true)) {
                await _run(() => n.hardDelete(a.id));
              }
            },
            icon: const Icon(Icons.delete_forever))
      ];

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await context.read<CatalogNotifier>().load(force: true);
    } catch (error) {
      if (mounted) await showOperationError(context, error);
    }
  }
}
