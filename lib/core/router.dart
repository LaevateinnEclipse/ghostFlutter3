import 'package:go_router/go_router.dart';
import '../models/album_query.dart';
import '../models/band_member_query.dart';
import '../models/concert_query.dart';
import '../models/merch_query.dart';
import '../models/track_query.dart';
import '../screens/album_form_screen.dart';
import '../screens/album_list_screen.dart';
import '../screens/band_member_form_screen.dart';
import '../screens/band_member_list_screen.dart';
import '../screens/concert_form_screen.dart';
import '../screens/concert_list_screen.dart';
import '../screens/entity_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/merch_form_screen.dart';
import '../screens/merch_list_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/track_form_screen.dart';
import '../screens/track_list_screen.dart';
import '../widgets/dirty_guard.dart';

final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/merch',
          builder: (_, s) => MerchListScreen(query: MerchQuery.fromUri(s.uri))),
      GoRoute(
          path: '/merch/new',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, __) => const MerchFormScreen()),
      GoRoute(
          path: '/merch/:id/edit',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, s) => MerchFormScreen(
              id: int.tryParse(s.pathParameters['id'] ?? ''))),
      GoRoute(
          path: '/members',
          builder: (_, s) =>
              BandMemberListScreen(query: BandMemberQuery.fromUri(s.uri))),
      GoRoute(
          path: '/members/new',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, __) => const BandMemberFormScreen()),
      GoRoute(
          path: '/members/:id/edit',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, s) => BandMemberFormScreen(
              id: int.tryParse(s.pathParameters['id'] ?? ''))),
      GoRoute(
          path: '/albums',
          builder: (_, s) => AlbumListScreen(query: AlbumQuery.fromUri(s.uri))),
      GoRoute(
          path: '/albums/new',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, __) => const AlbumFormScreen()),
      GoRoute(
          path: '/albums/:id/edit',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, s) =>
              AlbumFormScreen(id: int.tryParse(s.pathParameters['id'] ?? ''))),
      GoRoute(
          path: '/tracks',
          builder: (_, s) => TrackListScreen(query: TrackQuery.fromUri(s.uri))),
      GoRoute(
          path: '/tracks/new',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, __) => const TrackFormScreen()),
      GoRoute(
          path: '/tracks/:id/edit',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, s) =>
              TrackFormScreen(id: int.tryParse(s.pathParameters['id'] ?? ''))),
      GoRoute(
          path: '/concerts',
          builder: (_, s) =>
              ConcertListScreen(query: ConcertQuery.fromUri(s.uri))),
      GoRoute(
          path: '/concerts/new',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, __) => const ConcertFormScreen()),
      GoRoute(
          path: '/concerts/:id/edit',
          onExit: (_, __) => DirtyGuard.mayLeave(),
          builder: (_, s) => ConcertFormScreen(
              id: int.tryParse(s.pathParameters['id'] ?? ''))),
      for (final collection in [
        'merch',
        'members',
        'albums',
        'tracks',
        'concerts'
      ])
        GoRoute(
            path: '/$collection/:id',
            builder: (_, state) => EntityDetailScreen(
                collection: collection,
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
    ],
    errorBuilder: (_, s) => NotFoundScreen(location: s.uri.toString()));
