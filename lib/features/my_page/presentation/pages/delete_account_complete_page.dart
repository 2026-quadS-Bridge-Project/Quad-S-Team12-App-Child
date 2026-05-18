import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DeleteAccountCompletePage extends StatefulWidget {
  const DeleteAccountCompletePage({super.key});

  @override
  State<DeleteAccountCompletePage> createState() =>
      _DeleteAccountCompletePageState();
}

class _DeleteAccountCompletePageState extends State<DeleteAccountCompletePage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    unawaited(AuthSession.clearLogin());
    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      context.go('/');
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Block hardware back so the 3-second redirect to the entry page is not
    // interrupted by an unexpected pop.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.gray050,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: SizedBox(
                width: 328,
                child: Text(
                  '탈퇴가 완료되었습니다.\n언제든 다시 찾아와주세요!',
                  textAlign: TextAlign.center,
                  // Spec 05-delete.md L121 (Figma 773-11070) calls for gray600,
                  // not inkBlack — restoring per audit 10 Issue 6.
                  style: AppTypography.heading2Bold.copyWith(
                    color: AppColors.gray600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
