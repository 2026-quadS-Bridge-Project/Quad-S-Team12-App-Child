import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/child_home/presentation/pages/child_home_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/mission/presentation/pages/mission_info_page.dart';
import '../../features/my_page/presentation/pages/delete_account_complete_page.dart';
import '../../features/my_page/presentation/pages/my_page.dart';
import '../../features/my_page/presentation/pages/password_change_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/signup/presentation/pages/signup_page.dart';
import '../../features/time_confirm/presentation/pages/time_confirm_page.dart';
import '../../features/time_setup/presentation/pages/time_setup_root_page.dart';
import '../../features/time_setup/presentation/pages/time_setup_v2_root_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    // All routes are top-level (no shell, no bottom nav).
    // All 4 destinations (홈/리포트/알림/마이) are reached via header icons
    // or push navigation rather than a tab bar.
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/mypage',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyPage(),
    ),
    GoRoute(
      path: '/mypage/password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PasswordChangePage(),
    ),
    GoRoute(
      path: '/mypage/delete-complete',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DeleteAccountCompletePage(),
    ),
    GoRoute(
      path: '/child-home',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChildHomePage(),
    ),
    GoRoute(
      path: '/child-home/report',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportPage(),
    ),
    GoRoute(
      path: '/child-home/notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/child-home/time-setup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TimeSetupRootPage(),
    ),
    GoRoute(
      path: '/child-home/time-setup/v2',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TimeSetupV2RootPage(),
    ),
    GoRoute(
      path: '/child-home/time-setup/confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TimeConfirmPage(),
    ),
    GoRoute(
      path: '/child-home/mission/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          MissionInfoPage(missionId: state.pathParameters['id']!),
    ),
  ],
);
