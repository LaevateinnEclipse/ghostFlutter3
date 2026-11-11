import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ghost — официальный сайт')),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Сайт музыкальной группы Ghost',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text(
                      'Мерч и состав группы — основа будущего сайта с афишей концертов, дискографией и оформлением заказов.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Wrap(spacing: 16, runSpacing: 16, children: [
                    FilledButton.icon(
                        onPressed: () => context.go('/merch'),
                        icon: const Icon(Icons.storefront),
                        label: const Text('Мерч')),
                    FilledButton.icon(
                        onPressed: () => context.go('/members'),
                        icon: const Icon(Icons.group),
                        label: const Text('Состав группы')),
                    FilledButton.icon(
                        onPressed: () => context.go('/albums'),
                        icon: const Icon(Icons.album),
                        label: const Text('Альбомы')),
                    FilledButton.icon(
                        onPressed: () => context.go('/tracks'),
                        icon: const Icon(Icons.music_note),
                        label: const Text('Треки')),
                    FilledButton.icon(
                        onPressed: () => context.go('/concerts'),
                        icon: const Icon(Icons.event),
                        label: const Text('Концерты')),
                  ]),
                ],
              )),
        )),
      );
}