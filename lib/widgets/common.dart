import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../core/errors.dart';

const compactWidth = 600.0;

class AppScaffold extends StatelessWidget {
  final String title;
  final int index;
  final Widget child;
  const AppScaffold(
      {super.key,
      required this.title,
      required this.index,
      required this.child});
  @override
  Widget build(BuildContext c) {
    final compact = MediaQuery.sizeOf(c).width < compactWidth;
    final destinations = [
      (Icons.storefront, 'Мерч', '/merch'),
      (Icons.group, 'Состав', '/members'),
      (Icons.album, 'Альбомы', '/albums'),
      (Icons.music_note, 'Треки', '/tracks'),
      (Icons.event, 'Концерты', '/concerts'),
    ];
    final app = AppBar(title: Text(title));
    if (compact) {
      return Scaffold(
          appBar: app,
          body: child,
          bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => c.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.$1), label: d.$2)
              ]));
    }
    return Scaffold(
        appBar: app,
        body: Row(children: [
          NavigationRail(
              selectedIndex: index,
              extended: MediaQuery.sizeOf(c).width >= 1200,
              onDestinationSelected: (i) => c.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2))
              ]),
          const VerticalDivider(width: 1),
          Expanded(child: child)
        ]));
  }
}

class StatusView extends StatelessWidget {
  final String text;
  final bool error;
  final VoidCallback? retry;
  const StatusView(
      {super.key, required this.text, this.error = false, this.retry});
  @override
  Widget build(BuildContext c) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(error ? Icons.error_outline : Icons.search_off,
            size: 48, color: error ? Theme.of(c).colorScheme.error : null),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        if (retry != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton(
                  onPressed: retry, child: const Text('Повторить')))
      ]));
}

class Pager extends StatelessWidget {
  final int page, totalPages, total, size;
  final ValueChanged<int> onPage, onSize;
  const Pager(
      {super.key,
      required this.page,
      required this.totalPages,
      required this.total,
      required this.size,
      required this.onPage,
      required this.onSize});
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Всего: $total'),
            DropdownButton<int>(
                value: size,
                items: [10, 25, 50]
                    .map((x) => DropdownMenuItem(value: x, child: Text('$x')))
                    .toList(),
                onChanged: (x) {
                  if (x != null) onSize(x);
                }),
            IconButton(
                onPressed: page > 1 ? () => onPage(1) : null,
                icon: const Icon(Icons.first_page)),
            IconButton(
                onPressed: page > 1 ? () => onPage(page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            Text('$page / $totalPages'),
            IconButton(
                onPressed: page < totalPages ? () => onPage(page + 1) : null,
                icon: const Icon(Icons.chevron_right)),
            IconButton(
                onPressed: page < totalPages ? () => onPage(totalPages) : null,
                icon: const Icon(Icons.last_page))
          ]));
}

Future<bool> confirm(BuildContext c, String text, {bool hard = false}) async =>
    (await showDialog<bool>(
        context: c,
        builder: (x) => AlertDialog(
                title:
                    Text(hard ? 'Физическое удаление' : 'Логическое удаление'),
                content: Text(text),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(x, false),
                      child: const Text('Отмена')),
                  FilledButton(
                      onPressed: () => Navigator.pop(x, true),
                      child: Text(hard ? 'Стереть' : 'Удалить'))
                ]))) ??
    false;

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
}

/// Отказ операции не подменяет уже загруженный список экраном ошибки.
Future<void> showOperationError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  if (error is ConflictException || error is LinkedRecordsException) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Операция не выполнена'),
        content: Text('$error\n\nДанные не изменены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
    return;
  }
  toast(context, error.toString());
}
