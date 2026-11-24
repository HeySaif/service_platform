import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/chat/booking_detail_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/client/post_request_screen.dart';
import '../features/client/request_detail_screen.dart';
import '../features/provider/provider_request_screen.dart';
import '../models/models.dart';
import '../features/auth/register_screen.dart';
import '../features/profile/provider_onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../services/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects when session or user row changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  ref.listen(currentUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(supabaseProvider).auth.currentSession != null;
      final loc = state.matchedLocation;
      final onAuth = loc == '/login' || loc == '/register';
      if (!signedIn) return onAuth ? null : '/login';
      if (onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const AppShell()),
      GoRoute(path: '/post-request', builder: (_, s) => PostRequestScreen(initialCategory: s.extra as ServiceCategory?)),
      GoRoute(path: '/request/:id', builder: (_, s) => RequestDetailScreen(requestId: s.pathParameters['id']!)),
      GoRoute(path: '/provider/request/:id', builder: (_, s) => ProviderRequestScreen(requestId: s.pathParameters['id']!)),
      GoRoute(path: '/booking/:id', builder: (_, s) => BookingDetailScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/chat/:id', builder: (_, s) => ChatScreen(bookingId: s.pathParameters['id']!, readOnly: s.uri.queryParameters['readonly'] == 'true')),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/provider-onboarding', builder: (_, __) => const ProviderOnboardingScreen()),
    ],
  );
});
