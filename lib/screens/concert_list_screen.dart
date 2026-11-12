import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/seed_data.dart';
import '../models/concert.dart';
import '../models/concert_query.dart';
import '../state/catalog_notifier.dart';
import '../state/list_notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_table.dart';

class ConcertListScreen extends StatefulWidget {
  final ConcertQuery query;
  const ConcertListScreen({super.key, required this.query});
  @override
  State<ConcertListScreen> createState() => _ConcertListScreenState();
}

class _ConcertListScreenState extends State<ConcertListScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void didUpdateWidget(covariant ConcertListScreen old) {
    super.didUpdateWidget(old);
    if (old.query.toQueryParameters().toString() !=
        widget.query.toQueryParameters().toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sync());
    }
  }

  void sync() => context.read<ConcertListNotifier>().applyQuery(widget.query);
  void go(ConcertQuery q) {
    final p = q.toQueryParameters();
    context.go(p.isEmpty
        ? '/concerts'
        : Uri(path: '/concerts', queryParameters: p).toString());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext c) {
    final n = c.watch<ConcertListNotifier>();
    final catalog = c.watch<CatalogNotifier>();
    return AppScaffold(
        title: 'Афиша',
        index: 4,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => context.go('/concerts/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый концерт')))),
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

  Widget filters(ConcertListNotifier n, CatalogNotifier catalog) {
    final q = widget.query;
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: 260,
              child: TextFormField(
                  initialValue: q.search,
                  decoration: const InputDecoration(
                      labelText: 'Поиск: город, площадка, код',
                      border: OutlineInputBorder()),
                  onChanged: (v) {
                    timer?.cancel();
                    timer = Timer(const Duration(milliseconds: 350),
                        () => go(q.copyWith(search: v)));
                  })),
          SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                  initialValue:
                      catalog.cities.contains(q.city) ? q.city : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Город', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все города')),
                    ...catalog.cities.map((city) => DropdownMenuItem<String?>(
                        value: city, child: Text(city)))
                  ],
                  onChanged: (v) => go(q.copyWith(city: v)))),
          SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                  initialValue: q.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Статус', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все статусы')),
                    ...Concert.statuses.map((status) => DropdownMenuItem<String?>(
                        value: status, child: Text(concertStatusLabel(status))))
                  ],
                  onChanged: (v) => go(q.copyWith(status: v)))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(
                value: q.includeDeleted,
                onChanged: (v) => go(q.copyWith(includeDeleted: v))),
            const Text('Удалённые')
          ]),
          TextButton(
              onPressed: q.hasActiveFilters
                  ? () => go(ConcertQuery(
                      size: q.size,
                      sortField: q.sortField,
                      sortAscending: q.sortAscending))
                  : null,
              child: const Text('Сбросить'))
        ]));
  }

  Widget selection(ConcertListNotifier n) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: [
        Text('Выбрано: ${n.selected.length}'),
        FilledButton(
            onPressed: () async {
              if (await confirm(context, 'Удалить выбранные концерты?')) {
                await _run(() => n.deleteSelected(false));
              }
            },
            child: const Text('Удалить')),
        OutlinedButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть выбранные концерты?',
                  hard: true)) {
                await _run(() => n.deleteSelected(true));
              }
            },
            child: const Text('Стереть навсегда')),
        TextButton(onPressed: n.clear, child: const Text('Снять выделение'))
      ]));

  Widget body(ConcertListNotifier n, CatalogNotifier catalog) {
    if (n.status == LoadStatus.idle || n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return StatusView(text: n.error ?? 'Ошибка', error: true, retry: n.load);
    }
    if (n.result.items.isEmpty) {
      return const StatusView(text: 'Концерты не найдены.');
    }
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return ListView(
          children: [for (final item in n.result.items) card(n, catalog, item)]);
    }
    return EntityTable<Concert>(
        items: n.result.items,
        id: (item) => item.id,
        selected: n.selected,
        toggle: n.toggle,
        sort: n.query.sortField,
        asc: n.query.sortAscending,
        onSort: (f) => go(n.query.copyWith(
            sortField: f,
            sortAscending: f == n.query.sortField ? !n.query.sortAscending : true)),
        columns: [
          ('Город', 'city', (item) => Text(item.city)),
          ('Площадка', null, (item) => Text(item.venue)),
          ('Дата', 'date', (item) => Text(_date(item.date))),
          ('Цена', 'ticketPrice', (item) => Text('${item.ticketPrice} ₽')),
          ('Статус', 'status', (item) => Text(concertStatusLabel(item.status))),
          ('Альбом', null, (item) => Text(catalog.albumTitle(item.albumId))),
        ],
        actions: (item) => actions(n, item));
  }

  Widget card(ConcertListNotifier n, CatalogNotifier catalog, Concert item) =>
      Card(
          child: ListTile(
              leading: Checkbox(
                  value: n.selected.contains(item.id),
                  onChanged: (_) => n.toggle(item.id)),
              title: Text('${item.city} — ${item.venue}'),
              subtitle: Text(
                  '${_date(item.date)} • ${concertStatusLabel(item.status)}\n${catalog.albumTitle(item.albumId)} • ${item.ticketPrice} ₽'),
              isThreeLine: true,
              trailing: Wrap(children: actions(n, item))));

  List<Widget> actions(ConcertListNotifier n, Concert item) => [
        IconButton(
            tooltip: 'Карточка',
            onPressed: () => context.go('/concerts/${item.id}'),
            icon: const Icon(Icons.visibility_outlined)),
        IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/concerts/${item.id}/edit'),
            icon: const Icon(Icons.edit_outlined)),
        if (item.isDeleted)
          IconButton(
              onPressed: () => _run(() => n.restore(item.id)),
              icon: const Icon(Icons.restore))
        else
          IconButton(
              onPressed: () async {
                if (await confirm(context,
                    'Удалить концерт в ${item.city}, ${item.venue}?')) {
                  await _run(() => n.softDelete(item.id));
                }
              },
              icon: const Icon(Icons.delete_outline)),
        IconButton(
            onPressed: () async {
              if (await confirm(
                  context, 'Стереть концерт в ${item.city}, ${item.venue}?',
                  hard: true)) {
                await _run(() => n.hardDelete(item.id));
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
