import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // TODO(backend): wire _accountType and _childCode to user profile API.
  // Static placeholders until the backend endpoint is available
  // (see audit 08-mypage.md Issue 8).
  static const String _accountType = '자녀회원';
  static const String _childCode = 'XY785eZ';

  String _username = AuthSession.fallbackUsername;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final String username = await AuthSession.username();
    if (!mounted) {
      return;
    }
    setState(() {
      _username = username;
    });
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'delete-account-dialog',
      barrierColor: const Color.fromRGBO(68, 68, 68, 0.6),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 375),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 21),
                  child: _DeleteAccountDialog(),
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
                      const _InfoRow(label: '회원유형', value: _accountType),
                      const SizedBox(height: 24),
                      _InfoRow(label: '아이디', value: _username),
                      const SizedBox(height: 24),
                      const _InfoRow(label: '자녀코드', value: _childCode),
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
                    // 로그아웃 button intentionally absent per Figma 773:11103.
                    // Only 탈퇴하기 (80×35 chip, node 257:3713) is rendered.
                    child: BridgeButton(
                      label: '탈퇴하기',
                      variant: BridgeButtonVariant.destructive,
                      size: BridgeButtonSize.small,
                      fullWidth: false,
                      onPressed: () => _showDeleteAccountDialog(context),
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

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 294.897,
        height: 189.705,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 33, 18, 27),
          child: Column(
            children: [
              Container(
                width: 28.77,
                height: 28.77,
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
                          top: 1.5,
                          child: Container(
                            width: 2.4,
                            height: 9.6,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0.5,
                          child: Container(
                            width: 2.4,
                            height: 2.4,
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
              ),
              const SizedBox(height: 16),
              Text(
                '탈퇴하시겠습니까?',
                style: AppTypography.labelBold.copyWith(
                  fontSize: 14.39,
                  height: 1.5,
                  letterSpacing: 0.082,
                  color: AppColors.gray800,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DeleteDialogButton(
                    label: '취소',
                    filled: false,
                    onTap: context.pop,
                  ),
                  const SizedBox(width: 13.486),
                  _DeleteDialogButton(
                    label: '확인',
                    filled: true,
                    onTap: () async {
                      final GoRouter router = GoRouter.of(context);
                      context.pop();
                      await AuthSession.clearLogin();
                      router.push('/mypage/delete-complete');
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
        width: 107.889,
        height: 37.761,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : const Color(0xFFEBF5FE),
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: AppColors.primary, width: 0.899),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontSize: 12.59,
            height: 1.429,
            letterSpacing: 0.1826,
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
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () => context.push('/mypage/password'),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.gray600,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '수정하기',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white,
                  letterSpacing: 0.091,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
