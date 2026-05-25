import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';

enum _LoginErrorType { missingUser, wrongPassword }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Set<String> _mockUsernames = <String>{'gdg12', 'abcd00'};
  static const String _mockPassword = 'Gdg123456789!';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _LoginErrorType? _activeError;

  String get _username => _usernameController.text;
  String get _password => _passwordController.text;
  bool get _canSubmit => _username.isNotEmpty && _password.isNotEmpty;

  String? get _errorMessage {
    switch (_activeError) {
      case _LoginErrorType.missingUser:
        return '존재하지 않는 아이디입니다.';
      case _LoginErrorType.wrongPassword:
        return '비밀번호가 일치하지 않습니다.';
      case null:
        return null;
    }
  }

  void _onUsernameChanged(String value) {
    setState(() {
      if (_activeError == _LoginErrorType.missingUser) {
        _activeError = null;
      }
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (_activeError == _LoginErrorType.wrongPassword) {
        _activeError = null;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_mockUsernames.contains(_username)) {
      setState(() {
        _activeError = _LoginErrorType.missingUser;
      });
      return;
    }

    if (_password != _mockPassword) {
      setState(() {
        _activeError = _LoginErrorType.wrongPassword;
      });
      return;
    }

    setState(() {
      _activeError = null;
    });

    await AuthSession.saveLogin(username: _username);
    if (!mounted) {
      return;
    }
    // Land on the actual home (donut/empty + missions). `/child-home/onboarding`
    // is reserved for the first-time parent-connect overlay, not every login.
    context.go('/child-home');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.gray100,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 375),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              BridgeAppBar(
                                title: '로그인',
                                onBack: () => context.pop(),
                              ),
                              const SizedBox(height: 25),
                              _LoginField(
                                label: '아이디',
                                controller: _usernameController,
                                borderColor:
                                    _activeError == _LoginErrorType.missingUser
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                onChanged: _onUsernameChanged,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\s'),
                                  ),
                                  LengthLimitingTextInputFormatter(12),
                                ],
                                keyboardType: TextInputType.text,
                                labelBottomSpacing: 10,
                              ),
                              const SizedBox(height: 35),
                              _LoginField(
                                label: '비밀번호',
                                controller: _passwordController,
                                borderColor:
                                    _activeError ==
                                        _LoginErrorType.wrongPassword
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                onChanged: _onPasswordChanged,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\s'),
                                  ),
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                keyboardType: TextInputType.visiblePassword,
                                labelBottomSpacing: 12,
                                obscureText: true,
                              ),
                              const Spacer(),
                              if (_errorMessage case final String message) ...[
                                _LoginToast(message: message),
                                const SizedBox(height: 15),
                              ],
                              BridgeButton(
                                label: '로그인',
                                variant: BridgeButtonVariant.primary,
                                size: BridgeButtonSize.large,
                                fullWidth: true,
                                onPressed: _canSubmit ? _submit : null,
                              ),
                              const SizedBox(height: 29),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.borderColor,
    required this.onChanged,
    required this.inputFormatters,
    required this.keyboardType,
    required this.labelBottomSpacing,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final Color borderColor;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final double labelBottomSpacing;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.0912,
            color: AppColors.gray600,
          ),
        ),
        SizedBox(height: labelBottomSpacing),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              obscureText: obscureText,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: inputFormatters,
              cursorColor: AppColors.black,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.0912,
                color: AppColors.black,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginToast extends StatelessWidget {
  const _LoginToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray500,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _LoginToastWarningIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 14,
                height: 1.429,
                letterSpacing: 0.203,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginToastWarningIcon extends StatelessWidget {
  const _LoginToastWarningIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.destructive,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '!',
          style: AppTypography.captionBold.copyWith(
            fontSize: 12,
            height: 1,
            letterSpacing: 0,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
