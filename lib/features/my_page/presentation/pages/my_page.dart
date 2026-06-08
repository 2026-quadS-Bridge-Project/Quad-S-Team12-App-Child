import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/my_page_repository.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final MyPageRepository _repository = createMyPageRepository();

  // Defaults shown while the profile fetch is in flight. They mirror the
  // canned mock values so the layout never flashes empty strings.
  String _username = AuthSession.fallbackUsername;
  String _accountType = '자녀회원';
  String _childCode = 'XY785eZ';

  // Guards against double-confirm on the delete-account dialog. The dialog
  // is dismissed immediately on the first confirm tap, but a same-frame
  // second tap could still re-enter before the pop animation completes.
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final Result<UserProfile> result = await _repository.fetchProfile();
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<UserProfile>(:final UserProfile data):
        setState(() {
          _username = data.username;
          _accountType = data.accountType;
          _childCode = data.childCode;
        });
      case Failure<UserProfile>():
        // Fall back to AuthSession username so the screen still shows the
        // logged-in id even if the profile fetch fails.
        final String username = await AuthSession.username();
        if (!mounted) {
          return;
        }
        setState(() {
          _username = username;
        });
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'delete-account-dialog',
      barrierColor: AppColors.scrim,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: _AccountActionDialog(
                    message: '탈퇴하시겠습니까?',
                    onConfirm: _handleDeleteAccount,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'logout-dialog',
      barrierColor: AppColors.scrim,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: _AccountActionDialog(
                    message: '로그아웃하시겠습니까?',
                    onConfirm: _handleLogout,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 160),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final GoRouter router = GoRouter.of(context);
    context.pop();
    await AuthSession.clearLogin();
    await AuthSession.clearTokens();
    if (!mounted) {
      return;
    }
    router.go('/');
  }

  Future<void> _handleDeleteAccount() async {
    // Re-entry guard: a fast double-tap on 확인 could fire before the dialog
    // pop animation registers. Bail out on the second invocation.
    if (_deletingAccount) {
      return;
    }
    _deletingAccount = true;

    final GoRouter router = GoRouter.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Dismiss the dialog before awaiting the network call so the user sees
    // immediate feedback regardless of which branch we land on.
    context.pop();

    try {
      final Result<void> result = await _repository.deleteAccount();
      if (!mounted) {
        return;
      }
      switch (result) {
        case Success<void>():
          await AuthSession.clearLogin();
          await AuthSession.clearTokens();
          if (!mounted) {
            return;
          }
          router.push('/mypage/delete-complete');
        case Failure<void>(:final String message):
          messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        _deletingAccount = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BridgeAppBar(title: '마이페이지'),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: '회원유형', value: _accountType),
                      const SizedBox(height: 24),
                      _InfoRow(label: '아이디', value: _username),
                      const SizedBox(height: 24),
                      _InfoRow(label: '자녀코드', value: _childCode),
                      const SizedBox(height: 24),
                      const _PasswordRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 7,
                  color: AppColors.gray150,
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MyPageActionButton(
                          label: '로그아웃',
                          width: 89,
                          backgroundColor: const Color(0xFFEDEEF1),
                          foregroundColor: AppColors.gray600,
                          onTap: () => _showLogoutDialog(context),
                        ),
                        const SizedBox(width: 12),
                        _MyPageActionButton(
                          label: '탈퇴하기',
                          width: 80,
                          backgroundColor: const Color(0xFFFFD3D3),
                          foregroundColor: AppColors.destructive,
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyPageActionButton extends StatelessWidget {
  const _MyPageActionButton({
    required this.label,
    required this.width,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final double width;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: foregroundColor.withValues(alpha: 0.08),
        highlightColor: foregroundColor.withValues(alpha: 0.12),
        splashColor: foregroundColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: 37,
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: foregroundColor,
                height: 1.5,
                letterSpacing: 0.091,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountActionDialog extends StatelessWidget {
  const _AccountActionDialog({required this.message, required this.onConfirm});

  final String message;

  /// Invoked when the user taps 확인. Owner ([_MyPageState]) is responsible
  /// for dismissing the dialog, calling the repository, and routing.
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 328,
        height: 211,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 37, bottom: 30),
          child: Column(
            children: [
              const _WarningBadge(),
              const SizedBox(height: 18),
              _DeleteDialogTitle(message),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DeleteDialogButton(
                    label: '취소',
                    filled: false,
                    onTap: context.pop,
                  ),
                  const SizedBox(width: 15),
                  _DeleteDialogButton(
                    label: '확인',
                    filled: true,
                    onTap: () {
                      onConfirm();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBadge extends StatelessWidget {
  const _WarningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 8,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 1.33,
                child: Container(
                  width: 2.67,
                  height: 10.67,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                bottom: 0.67,
                child: Container(
                  width: 2.67,
                  height: 2.67,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteDialogTitle extends StatelessWidget {
  const _DeleteDialogTitle(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: AppTypography.bodySemiBold.copyWith(
        color: AppColors.gray800,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _DeleteDialogButton extends StatelessWidget {
  const _DeleteDialogButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 120,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
          border: filled ? null : Border.all(color: AppColors.primary),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: filled ? AppColors.white : AppColors.primary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 69,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
                letterSpacing: 0.091,
              ),
            ),
          ),
          Container(width: 1, height: 22, color: AppColors.gray200),
          const SizedBox(width: 23),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkBlack,
              letterSpacing: 0.091,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatelessWidget {
  const _PasswordRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Text(
            '비밀번호',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray600,
              letterSpacing: 0.091,
            ),
          ),
          const SizedBox(width: 13),
          Material(
            color: const Color(0xFFEDEEF1),
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/mypage/password'),
              hoverColor: AppColors.gray600.withValues(alpha: 0.08),
              highlightColor: AppColors.gray600.withValues(alpha: 0.12),
              splashColor: AppColors.gray600.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 37,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                child: Text(
                  '수정하기',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray600,
                    height: 1.5,
                    letterSpacing: 0.082,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
