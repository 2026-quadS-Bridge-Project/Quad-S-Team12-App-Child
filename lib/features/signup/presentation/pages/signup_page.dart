import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/services/fcm_bootstrap.dart';
import '../../../../core/models/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/bridge_button.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';
import '../../../../features/auth/data/models/auth_token.dart';
import '../../../../features/auth/data/repositories/auth_repository.dart';

enum _SignupErrorType {
  invalidName,
  invalidUsername,
  duplicatedUsername,
  invalidPassword,
  passwordMismatch,
}

enum _CheckState { hidden, inactive, active }

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{12,15}$',
  );

  late final AuthRepository _repository = createAuthRepository();
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  _SignupErrorType? _activeError;
  String? _genericErrorMessage;

  String get _name => _nameController.text.trim();
  String get _email => _emailController.text.trim();
  String get _password => _passwordController.text;
  String get _passwordConfirm => _passwordConfirmController.text;

  bool get _isNameValid => _name.characters.length >= 2;
  bool get _isUsernameFormatValid => _emailPattern.hasMatch(_email);
  // Inline duplicate-detection happens server-side now; the live helper text
  // only flips after a failed signup attempt surfaces a duplicate failure.
  bool _serverReportedDuplicate = false;
  bool get _isUsernameDuplicate =>
      _email.isNotEmpty && _serverReportedDuplicate;
  bool get _isPasswordValid => _passwordPattern.hasMatch(_password);
  bool get _isPasswordMatched =>
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty &&
      _password == _passwordConfirm;

  bool get _hasAllFields =>
      _name.isNotEmpty &&
      _email.isNotEmpty &&
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty;

  bool get _hasUsernameError => _usernameInlineMessage != null;

  bool get _hasPasswordError => _passwordInlineMessage != null;

  bool get _hasPasswordConfirmError => _passwordConfirmInlineMessage != null;

  bool get _canSubmit =>
      _hasAllFields &&
      _isUsernameFormatValid &&
      !_isUsernameDuplicate &&
      _isPasswordValid &&
      _isPasswordMatched &&
      !_isSubmitting;

  String? get _usernameInlineMessage {
    if (_email.isEmpty) {
      return null;
    }
    if (!_isUsernameFormatValid) {
      return '이메일 형식으로 입력해주세요.';
    }
    if (_isUsernameDuplicate) {
      return '이미 사용 중인 이메일입니다.';
    }
    return null;
  }

  String? get _passwordInlineMessage {
    if (_password.isEmpty || _isPasswordValid) {
      return null;
    }
    return '영문 대/소문자, 숫자, 특수문자 혼합 12~15자 / 빈칸, 공백 불가';
  }

  String? get _passwordConfirmInlineMessage {
    if (_passwordConfirm.isEmpty) {
      return null;
    }
    if (_isPasswordMatched) {
      return null;
    }
    return '비밀번호가 일치하지 않습니다.';
  }

  String? get _errorMessage {
    switch (_activeError) {
      case _SignupErrorType.invalidName:
        return '이름을 2자 이상 입력해주세요.';
      case _SignupErrorType.invalidUsername:
        return '이메일 형식에 어긋납니다. 수정해주세요.';
      case _SignupErrorType.duplicatedUsername:
        return '이메일이 중복됩니다. 수정해주세요!';
      case _SignupErrorType.invalidPassword:
        return '비밀번호 규칙에 어긋납니다. 수정해주세요.';
      case _SignupErrorType.passwordMismatch:
        return '비밀번호가 일치하지 않습니다. 확인해주세요.';
      case null:
        return _genericErrorMessage;
    }
  }

  _CheckState get _usernameCheckState {
    if (_isUsernameFormatValid && !_isUsernameDuplicate) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  _CheckState get _passwordCheckState {
    if (_isPasswordValid) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  _CheckState get _passwordConfirmCheckState {
    if (_isPasswordValid && _isPasswordMatched) {
      return _CheckState.active;
    }
    return _CheckState.inactive;
  }

  void _onNameChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidName) {
        _activeError = null;
      }
      _genericErrorMessage = null;
    });
  }

  void _onUsernameChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidUsername ||
          _activeError == _SignupErrorType.duplicatedUsername) {
        _activeError = null;
      }
      // Re-typing the username clears the stale server-side duplicate flag so
      // the user can retry with the same (corrected) value without a phantom
      // helper message stuck on screen.
      _serverReportedDuplicate = false;
      _genericErrorMessage = null;
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.invalidPassword ||
          _activeError == _SignupErrorType.passwordMismatch) {
        _activeError = null;
      }
      _genericErrorMessage = null;
    });
  }

  void _onPasswordConfirmChanged(String value) {
    setState(() {
      if (_activeError == _SignupErrorType.passwordMismatch) {
        _activeError = null;
      }
      _genericErrorMessage = null;
    });
  }

  Future<void> _submit() async {
    // Re-entrancy guard: a rapid double-tap can fire `_submit` twice before
    // the button rebuilds with `onPressed: null`. Bail out on the second call.
    if (_isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    if (!_isNameValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidName;
      });
      return;
    }

    if (!_isUsernameFormatValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidUsername;
      });
      return;
    }

    if (!_isPasswordValid) {
      setState(() {
        _activeError = _SignupErrorType.invalidPassword;
      });
      return;
    }

    if (!_isPasswordMatched) {
      setState(() {
        _activeError = _SignupErrorType.passwordMismatch;
      });
      return;
    }

    setState(() {
      _activeError = null;
      _genericErrorMessage = null;
      _isSubmitting = true;
    });

    final Result<AuthToken> result = await _repository.signup(
      name: _name,
      username: _email,
      password: _password,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<AuthToken>(:final AuthToken data):
        if (data.accessToken.isEmpty) {
          setState(() {
            _isSubmitting = false;
          });
          context.go(
            Uri(
              path: '/login',
              queryParameters: <String, String>{
                'username': _email,
                'notice': 'signup-complete',
              },
            ).toString(),
          );
          return;
        }
        await AuthSession.saveLogin(
          username: data.username,
          memberId: data.memberId,
          name: data.name,
          childCode: data.childCode,
        );
        await AuthSession.saveTokens(
          accessToken: data.accessToken,
          refreshToken: data.refreshToken,
        );
        // Register the FCM device for the new session — see LoginPage
        // for rationale. Mock impl is a no-op.
        unawaited(FcmBootstrap.registerForCurrentSession());
        if (!mounted) {
          return;
        }
        context.go('/child-home');
      case Failure<AuthToken>(:final String message):
        setState(() {
          _isSubmitting = false;
          if (message == AuthFailureMessages.duplicatedUsername) {
            _activeError = _SignupErrorType.duplicatedUsername;
            _serverReportedDuplicate = true;
            _genericErrorMessage = null;
          } else {
            // Network / generic server failures (e.g. messages produced by
            // failureFromDioException) flow through here. Surface them via
            // the existing toast instead of misleading the user with an
            // "invalid username" inline rule violation.
            _activeError = null;
            _genericErrorMessage = message;
          }
        });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
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
                  constraints: const BoxConstraints(
                    maxWidth: AppTokens.mobileFrameWidth,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.pageHorizontal,
                          ),
                          child: Column(
                            children: [
                              BridgeAppBar(
                                title: '회원가입',
                                onBack: () => context.pop(),
                              ),
                              const SizedBox(height: 25),
                              _SignupField(
                                label: '이름',
                                controller: _nameController,
                                borderColor:
                                    _activeError == _SignupErrorType.invalidName
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                checkState: _isNameValid
                                    ? _CheckState.active
                                    : _CheckState.inactive,
                                helperText: null,
                                onChanged: _onNameChanged,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'^\s'),
                                  ),
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                keyboardType: TextInputType.name,
                                labelBottomSpacing: 10,
                              ),
                              const SizedBox(height: 35),
                              _SignupField(
                                label: '이메일',
                                controller: _emailController,
                                borderColor: _hasUsernameError
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                checkState: _usernameCheckState,
                                helperText: _usernameInlineMessage,
                                onChanged: _onUsernameChanged,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\s'),
                                  ),
                                  LengthLimitingTextInputFormatter(80),
                                ],
                                keyboardType: TextInputType.emailAddress,
                                labelBottomSpacing: 10,
                              ),
                              const SizedBox(height: 35),
                              _SignupField(
                                label: '비밀번호',
                                controller: _passwordController,
                                borderColor: _hasPasswordError
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                checkState: _passwordCheckState,
                                helperText: _passwordInlineMessage,
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
                              const SizedBox(height: 35),
                              _SignupField(
                                label: '비밀번호 재확인',
                                controller: _passwordConfirmController,
                                borderColor: _hasPasswordConfirmError
                                    ? AppColors.destructive
                                    : AppColors.gray200,
                                checkState: _passwordConfirmCheckState,
                                helperText: _passwordConfirmInlineMessage,
                                onChanged: _onPasswordConfirmChanged,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\s'),
                                  ),
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                keyboardType: TextInputType.visiblePassword,
                                labelBottomSpacing: 10,
                                obscureText: true,
                              ),
                              const Spacer(),
                              if (_errorMessage case final String message) ...[
                                _SignupToast(message: message),
                                const SizedBox(height: 15),
                              ],
                              BridgeButton(
                                label: '회원가입',
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

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.label,
    required this.controller,
    required this.borderColor,
    required this.checkState,
    required this.helperText,
    required this.onChanged,
    required this.inputFormatters,
    required this.keyboardType,
    required this.labelBottomSpacing,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final Color borderColor;
  final _CheckState checkState;
  final String? helperText;
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
            borderRadius: BorderRadius.circular(AppTokens.fieldRadius),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
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
              if (checkState != _CheckState.hidden) ...[
                const SizedBox(width: 12),
                _FieldCheck(state: checkState),
              ],
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: AppTypography.captionMedium.copyWith(
                fontSize: 12,
                height: 1.334,
                letterSpacing: 0.12,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldCheck extends StatelessWidget {
  const _FieldCheck({required this.state});

  final _CheckState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Visibility(
        visible: state == _CheckState.active,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: const Center(
          child: Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SignupToast extends StatelessWidget {
  const _SignupToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray500,
        borderRadius: BorderRadius.circular(AppTokens.errorBannerRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const _ToastWarningIcon(),
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

class _ToastWarningIcon extends StatelessWidget {
  const _ToastWarningIcon();

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
          style: AppTypography.captionSemiBold.copyWith(
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
