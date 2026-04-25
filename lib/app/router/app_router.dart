import 'package:go_router/go_router.dart';

import '../../features/child_home/presentation/pages/child_home_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/my_page/presentation/pages/delete_account_complete_page.dart';
import '../../features/my_page/presentation/pages/my_page.dart';
import '../../features/my_page/presentation/pages/password_change_page.dart';
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
      builder: (context, state) =>
          const ChildHomePage(showOnboarding: true, showContent: false),
    ),
    GoRoute(path: '/mypage', builder: (context, state) => const MyPage()),
    GoRoute(
      path: '/mypage/password',
      builder: (context, state) => const PasswordChangePage(),
    ),
    GoRoute(
      path: '/mypage/delete-complete',
      builder: (context, state) => const DeleteAccountCompletePage(),
    ),
  ],
);
