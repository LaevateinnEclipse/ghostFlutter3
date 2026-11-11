import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  final String location;
  const NotFoundScreen({super.key, required this.location});
  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Страница не найдена')),
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.travel_explore, size: 48),
        const SizedBox(height: 12),
        const Text('Такой страницы нет'),
        Text(location),
        FilledButton(
            onPressed: () => c.go('/'), child: const Text('На главную'))
      ])));
}
