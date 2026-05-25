import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../features/auth/data/models/auth_token.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';

enum _LoginErrorType { missingUser, wrongPassword }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthRepository _repository = createAuthRepository();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _LoginErrorType? _activeError;
  String? _genericErrorMessage;
  bool _isSubmitting = false;

  String get _username => _usernameController.text;
  String get _password => _passwordController.text;
  bool get _canSubmit =>
      _username.isNotEmpty && _password.isNotEmpty && !_isSubmitting;

  String? get _errorMessage {
    switch (_activeError) {
      case _LoginErrorType.missingUser:
        return '존재하지 않는 아이디입니다.';
      case _LoginErrorType.wrongPassword:
        return '비밀번호가 일치하지 않습니다.';
      case null:
        return _genericErrorMessage;
    }
  }

  void _onUsernameChanged(String value) {
    setState(() {
      if (_activeError == _LoginErrorType.missingUser) {
        _activeError = null;
      }
      _genericErrorMessage = null;
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (_activeError == _LoginErrorType.wrongPassword) {
        _activeError = null;
      }
      _genericErrorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    final Result<AuthToken> result = await _repository.login(
      username: _username,
      password: _password,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<AuthToken>(:final AuthToken data):
        setState(() {
          _activeError = null;
          _genericErrorMessage = null;
        });
        await AuthSession.saveLogin(username: data.username);
        await AuthSession.saveTokens(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
        );
        if (!mounted) {
          return;
        }
        // Land on the actual home (donut/empty + missions). `/child-home/onboarding`
        // is reserved for the first-time parent-connect overlay, not every login.
        context.go('/child-home');
      case Failure<AuthToken>(:final String message):
        setState(() {
          _applyFailure(message);
          _isSubmitting = false;
        });
    }
  }

  /// Maps a repository failure [message] into either a field-bound error
  /// (red border + canned toast copy) or a generic toast that surfaces the
  /// raw message verbatim. Network/timeout messages from
  /// [failureFromDioException] do not match the [AuthFailureMessages]
  /// constants, so they fall through to the generic path instead of being
  /// mislabelled as an unknown-user error.
  void _applyFailure(String message) {
    switch (message) {
      case AuthFailureMessages.unknownUser:
        _activeError = _LoginErrorType.missingUser;
        _genericErrorMessage = null;
      case AuthFailureMessages.wrongPassword:
        _activeError = _LoginErrorType.wrongPassword;
        _genericErrorMessage = null;
      default:
        _activeError = null;
        _genericErrorMessage = message;
    }
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
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.black),
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
              style: AppTypography.labelMedium.copyWith(color: AppColors.white),
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
