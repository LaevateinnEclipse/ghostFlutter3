import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'core/router.dart';
import 'core/storage.dart';
import 'repositories/album_repository.dart';
import 'repositories/api_album_repository.dart';
import 'repositories/api_band_member_repository.dart';
import 'repositories/api_concert_repository.dart';
import 'repositories/api_merch_repository.dart';
import 'repositories/api_track_repository.dart';
import 'repositories/band_member_repository.dart';
import 'repositories/concert_repository.dart';
import 'repositories/merch_repository.dart';
import 'repositories/track_repository.dart';
import 'state/catalog_notifier.dart';
import 'state/list_notifiers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final preferences = await SharedPreferences.getInstance();
  final migrationNotice = VersionedStore.takeNotice(preferences);
  final dio = buildDio();
  runApp(MultiProvider(providers: [
    Provider<Dio>.value(value: dio),
    Provider<MerchRepository>(create: (_) => ApiMerchRepository(dio)),
    Provider<BandMemberRepository>(create: (_) => ApiBandMemberRepository(dio)),
    Provider<AlbumRepository>(create: (_) => ApiAlbumRepository(dio)),
    Provider<TrackRepository>(create: (_) => ApiTrackRepository(dio)),
    Provider<ConcertRepository>(create: (_) => ApiConcertRepository(dio)),
    ChangeNotifierProvider(
        create: (c) => MerchListNotifier(c.read<MerchRepository>())),
    ChangeNotifierProvider(
        create: (c) => BandMemberListNotifier(c.read<BandMemberRepository>())),
    ChangeNotifierProvider(
        create: (c) => AlbumListNotifier(c.read<AlbumRepository>())),
    ChangeNotifierProvider(
        create: (c) => TrackListNotifier(c.read<TrackRepository>())),
    ChangeNotifierProvider(
        create: (c) => ConcertListNotifier(c.read<ConcertRepository>())),
    ChangeNotifierProvider(
        create: (c) => CatalogNotifier(
              albums: c.read<AlbumRepository>(),
              members: c.read<BandMemberRepository>(),
              tracks: c.read<TrackRepository>(),
              merch: c.read<MerchRepository>(),
              concerts: c.read<ConcertRepository>(),
            )..load()),
  ], child: GhostApp(notice: migrationNotice)));
}

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class GhostApp extends StatelessWidget {
  final String? notice;
  const GhostApp({super.key, this.notice});
  @override
  Widget build(BuildContext c) => MaterialApp.router(
      title: 'Ghost',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade800),
          useMaterial3: true),
      routerConfig: appRouter,
      builder: (context, child) {
        if (notice == null) return child ?? const SizedBox.shrink();
        return _MigrationNoticeHost(message: notice!, child: child!);
      });
}

class _MigrationNoticeHost extends StatefulWidget {
  final String message;
  final Widget child;
  const _MigrationNoticeHost({required this.message, required this.child});
  @override
  State<_MigrationNoticeHost> createState() => _MigrationNoticeHostState();
}

class _MigrationNoticeHostState extends State<_MigrationNoticeHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(widget.message),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
