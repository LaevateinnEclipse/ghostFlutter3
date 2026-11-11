import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/seed_data.dart';
import '../models/band_member.dart';
import '../models/band_member_query.dart';
import '../state/catalog_notifier.dart';
import '../state/list_notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_table.dart';

class BandMemberListScreen extends StatefulWidget {
  final BandMemberQuery query;
  const BandMemberListScreen({super.key, required this.query});
  @override
  State<BandMemberListScreen> createState() => _BandMemberListScreenState();
}

class _BandMemberListScreenState extends State<BandMemberListScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void didUpdateWidget(covariant BandMemberListScreen old) {
    super.didUpdateWidget(old);
    if (old.query.toQueryParameters().toString() !=
        widget.query.toQueryParameters().toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => sync());
    }
  }

  void sync() =>
      context.read<BandMemberListNotifier>().applyQuery(widget.query);
  void go(BandMemberQuery q) {
    final p = q.toQueryParameters();
    context.go(p.isEmpty
        ? '/members'
        : Uri(path: '/members', queryParameters: p).toString());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final n = c.watch<BandMemberListNotifier>();
    return AppScaffold(
        title: 'Состав группы',
        index: 1,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => context.go('/members/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый участник')))),
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

  Widget filters(BandMemberListNotifier n) {
    final q = widget.query;
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: 280,
              child: TextFormField(
                  initialValue: q.search,
                  decoration: const InputDecoration(
                      labelText: 'Поиск: фамилия или роль',
                      border: OutlineInputBorder()),
                  onChanged: (v) {
                    timer?.cancel();
                    timer = Timer(const Duration(milliseconds: 350),
                        () => go(q.copyWith(search: v)));
                  })),
          SizedBox(
              width: 270,
              child: DropdownButtonFormField<String?>(
                  // value: q.role,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Роль', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все роли',
                            overflow: TextOverflow.ellipsis)),
                    ...bandRoles.map((v) => DropdownMenuItem<String?>(
                        value: v,
                        child: Text(v, overflow: TextOverflow.ellipsis)))
                  ],
                  onChanged: (v) => go(q.copyWith(role: v)))),
          SizedBox(
              width: 115,
              child: TextFormField(
                  initialValue: q.yearsFrom?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'В группе от', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      go(q.copyWith(yearsFrom: int.tryParse(v))))),
          SizedBox(
              width: 115,
              child: TextFormField(
                  initialValue: q.yearsTo?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'В группе до', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      go(q.copyWith(yearsTo: int.tryParse(v))))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(
                value: q.includeDeleted,
                onChanged: (v) => go(q.copyWith(includeDeleted: v))),
            const Text('Удалённые')
          ]),
          TextButton(
              onPressed: q.hasActiveFilters
                  ? () => go(BandMemberQuery(
                      size: q.size,
                      sortField: q.sortField,
                      sortAscending: q.sortAscending))
                  : null,
              child: const Text('Сбросить'))
        ]));
  }

  Widget selection(BandMemberListNotifier n) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: [
        Text('Выбрано: ${n.selected.length}'),
        FilledButton(
            onPressed: () async {
              if (await confirm(context, 'Удалить выбранных?')) {
                await _run(() => n.deleteSelected(false));
              }
            },
            child: const Text('Удалить')),
        OutlinedButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть выбранных?', hard: true)) {
                await _run(() => n.deleteSelected(true));
              }
            },
            child: const Text('Стереть навсегда')),
        TextButton(onPressed: n.clear, child: const Text('Снять выделение'))
      ]));
  Widget body(BandMemberListNotifier n) {
    if (n.status == LoadStatus.idle || n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return StatusView(text: n.error ?? 'Ошибка', error: true, retry: n.load);
    }
    if (n.result.items.isEmpty) {
      return const StatusView(text: 'Участники не найдены.');
    }
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return ListView(children: [for (final p in n.result.items) card(n, p)]);
    }
    return EntityTable<BandMember>(
        items: n.result.items,
        id: (p) => p.id,
        selected: n.selected,
        toggle: n.toggle,
        sort: n.query.sortField,
        asc: n.query.sortAscending,
        onSort: (f) => go(n.query.copyWith(
            sortField: f,
            sortAscending:
                f == n.query.sortField ? !n.query.sortAscending : true)),
        columns: [
          (
            'Фамилия',
            'lastName',
            (p) => Text(p.isDeleted ? '${p.lastName} (удалён)' : p.lastName)
          ),
          ('Имя', null, (p) => Text(p.firstName)),
          ('Роль', 'role', (p) => Text(p.role)),
          ('Годы в группе', 'yearsInBand', (p) => Text('${p.yearsInBand}')),
          // ('Гонорар', 'fee', (p) => Text('${p.fee} ₽'))
        ],
        actions: (p) => actions(n, p));
  }

  Widget card(BandMemberListNotifier n, BandMember p) => Card(
      child: ListTile(
          leading: Checkbox(
              value: n.selected.contains(p.id),
              onChanged: (_) => n.toggle(p.id)),
          title: Text(p.fullName),
          subtitle: Text(
              '${p.role}\nГоды в группе: ${p.yearsInBand}'),
          isThreeLine: true,
          trailing: Wrap(children: actions(n, p))));
  List<Widget> actions(BandMemberListNotifier n, BandMember p) => [
        IconButton(
            tooltip: 'Карточка',
            onPressed: () => context.go('/members/${p.id}'),
            icon: const Icon(Icons.visibility_outlined)),
        IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/members/${p.id}/edit'),
            icon: const Icon(Icons.edit_outlined)),
        if (p.isDeleted)
          IconButton(
              onPressed: () => _run(() => n.restore(p.id)),
              icon: const Icon(Icons.restore))
        else
          IconButton(
              onPressed: () async {
                if (await confirm(
                    context, 'Удалить участника «${p.fullName}»?')) {
                  await _run(() => n.softDelete(p.id));
                }
              },
              icon: const Icon(Icons.delete_outline)),
        IconButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть участника «${p.fullName}»?',
                  hard: true)) {
                await _run(() => n.hardDelete(p.id));
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