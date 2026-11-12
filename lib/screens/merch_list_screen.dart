import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/seed_data.dart';
import '../models/merch_item.dart';
import '../models/merch_query.dart';
import '../state/catalog_notifier.dart';
import '../state/list_notifiers.dart';
import '../widgets/common.dart';
import '../widgets/entity_table.dart';

class MerchListScreen extends StatefulWidget {
  final MerchQuery query;
  const MerchListScreen({super.key, required this.query});
  @override
  State<MerchListScreen> createState() => _MerchListScreenState();
}

class _MerchListScreenState extends State<MerchListScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant MerchListScreen old) {
    super.didUpdateWidget(old);
    if (old.query.toQueryParameters().toString() !=
        widget.query.toQueryParameters().toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  void _sync() => context.read<MerchListNotifier>().applyQuery(widget.query);
  void _go(MerchQuery q) {
    final p = q.toQueryParameters();
    context.go(p.isEmpty
        ? '/merch'
        : Uri(path: '/merch', queryParameters: p).toString());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<MerchListNotifier>();
    return AppScaffold(
        title: 'Мерч группы',
        index: 0,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                      onPressed: () => context.go('/merch/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Новый товар')))),
          _filters(n),
          if (n.hasSelection) _selection(n),
          Expanded(child: _body(n)),
          if (n.status == LoadStatus.success && n.result.total > 0)
            Pager(
                page: n.result.page,
                totalPages: n.result.totalPages,
                total: n.result.total,
                size: n.result.size,
                onPage: (v) => _go(n.query.copyWith(page: v)),
                onSize: (v) => _go(n.query.copyWith(size: v)))
        ]));
  }

  Widget _filters(MerchListNotifier n) {
    final q = widget.query;
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
              width: 260,
              child: TextFormField(
                  initialValue: q.search,
                  decoration: const InputDecoration(
                      labelText: 'Поиск: товар или артикул',
                      border: OutlineInputBorder()),
                  onChanged: (v) {
                    _timer?.cancel();
                    _timer = Timer(const Duration(milliseconds: 350),
                        () => _go(q.copyWith(search: v)));
                  })),
          SizedBox(
              width: 180,
              child: DropdownButtonFormField<String?>(
                  // value: q.category,
                  decoration: const InputDecoration(
                      labelText: 'Категория', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все категории')),
                    ...merchCategories.map((v) =>
                        DropdownMenuItem<String?>(value: v, child: Text(v)))
                  ],
                  onChanged: (v) => _go(q.copyWith(category: v)))),
          SizedBox(
              width: 115,
              child: TextFormField(
                  initialValue: q.stockFrom?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Остаток от', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      _go(q.copyWith(stockFrom: int.tryParse(v))))),
          SizedBox(
              width: 115,
              child: TextFormField(
                  initialValue: q.stockTo?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Остаток до', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      _go(q.copyWith(stockTo: int.tryParse(v))))),
          SizedBox(
              width: 120,
              child: TextFormField(
                  initialValue: q.priceFrom?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Цена от', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      _go(q.copyWith(priceFrom: int.tryParse(v))))),
          SizedBox(
              width: 120,
              child: TextFormField(
                  initialValue: q.priceTo?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Цена до', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (v) =>
                      _go(q.copyWith(priceTo: int.tryParse(v))))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Switch(
                value: q.includeDeleted,
                onChanged: (v) => _go(q.copyWith(includeDeleted: v))),
            const Text('Удалённые')
          ]),
          TextButton(
              onPressed: q.hasActiveFilters
                  ? () => _go(MerchQuery(
                      size: q.size,
                      sortField: q.sortField,
                      sortAscending: q.sortAscending))
                  : null,
              child: const Text('Сбросить'))
        ]));
  }

  Widget _selection(MerchListNotifier n) => Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, children: [
        Text('Выбрано: ${n.selected.length}'),
        FilledButton(
            onPressed: () async {
              if (await confirm(context, 'Удалить выбранные товары?')) {
                await _run(() => n.deleteSelected(false));
              }
            },
            child: const Text('Удалить')),
        OutlinedButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть выбранные товары?',
                  hard: true)) {
                await _run(() => n.deleteSelected(true));
              }
            },
            child: const Text('Стереть навсегда')),
        TextButton(onPressed: n.clear, child: const Text('Снять выделение'))
      ]));
  Widget _body(MerchListNotifier n) {
    if (n.status == LoadStatus.idle || n.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (n.status == LoadStatus.error) {
      return StatusView(text: n.error ?? 'Ошибка', error: true, retry: n.load);
    }
    if (n.result.items.isEmpty) {
      return const StatusView(text: 'Товары по заданным условиям не найдены.');
    }
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return ListView(children: [for (final m in n.result.items) _card(n, m)]);
    }
    return EntityTable<MerchItem>(
        items: n.result.items,
        id: (m) => m.id,
        selected: n.selected,
        toggle: n.toggle,
        sort: n.query.sortField,
        asc: n.query.sortAscending,
        onSort: (f) => _go(n.query.copyWith(
            sortField: f,
            sortAscending:
                f == n.query.sortField ? !n.query.sortAscending : true)),
        columns: [
          (
            'Название',
            'name',
            (m) => Text(m.isDeleted ? '${m.name} (удалён)' : m.name)
          ),
          ('Артикул', null, (m) => Text(m.sku)),
          ('Категория', 'category', (m) => Text(m.category)),
          ('Остаток', 'stock', (m) => Text('${m.stock} шт.')),
          ('Цена', 'price', (m) => Text('${m.price} ₽'))
        ],
        actions: (m) => _actions(n, m));
  }

  Widget _card(MerchListNotifier n, MerchItem m) => Card(
      child: ListTile(
          leading: Checkbox(
              value: n.selected.contains(m.id),
              onChanged: (_) => n.toggle(m.id)),
          title: Text(m.name),
          subtitle: Text(
              '${m.sku} • ${m.category}\n${m.stock} шт. • ${m.price} ₽'),
          isThreeLine: true,
          trailing: Wrap(children: _actions(n, m))));
  List<Widget> _actions(MerchListNotifier n, MerchItem m) => [
        IconButton(
            tooltip: 'Карточка',
            onPressed: () => context.go('/merch/${m.id}'),
            icon: const Icon(Icons.visibility_outlined)),
        IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/merch/${m.id}/edit'),
            icon: const Icon(Icons.edit_outlined)),
        if (m.isDeleted)
          IconButton(
              onPressed: () => _run(() => n.restore(m.id)),
              icon: const Icon(Icons.restore))
        else
          IconButton(
              onPressed: () async {
                if (await confirm(context, 'Удалить товар «${m.name}»?')) {
                  await _run(() => n.softDelete(m.id));
                }
              },
              icon: const Icon(Icons.delete_outline)),
        IconButton(
            onPressed: () async {
              if (await confirm(context, 'Стереть товар «${m.name}»?',
                  hard: true)) {
                await _run(() => n.hardDelete(m.id));
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