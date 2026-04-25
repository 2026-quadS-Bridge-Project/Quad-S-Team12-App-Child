import 'package:go_router/go_router.dart';

import '../../features/child_home/presentation/pages/child_home_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/signup/presentation/pages/signup_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/child-home',
      builder: (context, state) => const ChildHomePage(),
    ),
    GoRoute(
      path: '/child-home/onboarding',
      builder: (context, state) => const ChildHomePage(showOnboarding: true),
    ),
  ],
);
