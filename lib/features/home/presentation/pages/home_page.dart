import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';

const TextStyle _bridgeTitleStyle = TextStyle(
  color: AppColors.brandWordmark,
  fontFamily: 'Sigmar',
  fontFamilyFallback: <String>[AppTypography.fontFamily],
  fontSize: 40,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  height: 1.364,
  letterSpacing: -0.776,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Gate the build until we know whether the user is already logged in. This
  // prevents a one-frame flash of the intro screen before the redirect runs.
  Future<bool>? _shouldShowIntro;

  @override
  void initState() {
    super.initState();
    _shouldShowIntro = _redirectCachedLogin();
  }

  /// Returns `true` when the intro screen should be rendered (i.e. the user is
  /// not logged in). When a cached login is found, navigates to the real home
  /// and returns `false` so the build stays blank during the transition.
  Future<bool> _redirectCachedLogin() async {
    if (!await AuthSession.isLoggedIn()) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    // Cached-login users skip straight to the real home, not the first-time
    // onboarding overlay (which is reserved for the first parent-connect flow).
    context.go('/child-home');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.gray050,
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: _shouldShowIntro,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              // While the auth check is in flight, render nothing to avoid the
              // intro flashing for one frame before the redirect lands.
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTokens.mobileFrameWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.mobileHorizontalPadding,
                        ),
                        child: Column(
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment(0, -0.08),
                                child: _IntroContent(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _BottomActions(
                                isCompact: constraints.maxHeight < 700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Bridge', textAlign: TextAlign.center, style: _bridgeTitleStyle),
        const SizedBox(height: 20),
        const _BridgeIcon(),
        const SizedBox(height: 28),
        Text(
          '통제를 넘어 자율로,\n자기주도적 스마트폰 사용의 시작',
          textAlign: TextAlign.center,
          style: AppTypography.heading2Regular.copyWith(
            color: AppColors.gray600,
            letterSpacing: -0.24,
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BridgeButton(
          label: '자녀 회원가입',
          onPressed: () => context.push('/signup'),
        ),
        SizedBox(height: isCompact ? 14 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '이미 계정이 있나요?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray400,
                letterSpacing: 0.09,
              ),
            ),
            const SizedBox(width: 8),
            BridgeButton(
              label: '로그인',
              variant: BridgeButtonVariant.textLink,
              fullWidth: false,
              onPressed: () => context.push('/login'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BridgeIcon extends StatelessWidget {
  const _BridgeIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/Icon Container.svg',
      width: 90,
      height: 90,
      fit: BoxFit.contain,
    );
  }
}
