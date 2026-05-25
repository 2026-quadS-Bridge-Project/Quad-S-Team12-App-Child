import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/layout/bridge_app_bar.dart';

enum _PasswordChangeErrorType { currentMismatch }

enum _HelperSeverity { neutral, error }

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  static const String _mockCurrentPassword = 'Gdg123456789!';
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])[^\s]{12,15}$',
  );

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  _PasswordChangeErrorType? _currentPasswordError;
  bool _showNewPasswordRuleHint = false;
  bool _newPasswordRuleSeverityIsError = false;
  bool _showSameAsCurrentError = false;
  bool _showConfirmMismatchError = false;

  String get _currentPassword => _currentPasswordController.text;
  String get _newPassword => _newPasswordController.text;
  String get _confirmPassword => _confirmPasswordController.text;

  bool get _isCurrentPasswordValid => _currentPassword == _mockCurrentPassword;
  bool get _isNewPasswordValid => _passwordPattern.hasMatch(_newPassword);
  bool get _isSameAsCurrentPassword =>
      _newPassword.isNotEmpty && _newPassword == _mockCurrentPassword;
  bool get _isConfirmMatched =>
      _newPassword.isNotEmpty &&
      _confirmPassword.isNotEmpty &&
      _newPassword == _confirmPassword;

  bool get _canSubmit =>
      _isCurrentPasswordValid &&
      _isNewPasswordValid &&
      !_isSameAsCurrentPassword &&
      _isConfirmMatched;

  String? get _currentPasswordHelperText {
    if (_currentPasswordError != _PasswordChangeErrorType.currentMismatch) {
      return null;
    }
    return '기존 비밀번호가 일치하지 않습니다.';
  }

  String? get _newPasswordHelperText {
    if (_showSameAsCurrentError) {
      return '새 비밀번호는 기존 비밀번호와 달라야 합니다.';
    }
    if (_showNewPasswordRuleHint) {
      return '영문 대문자, 소문자, 숫자, 특수문자 모두 혼합 (12~15자)';
    }
    return null;
  }

  _HelperSeverity get _newPasswordHelperSeverity {
    if (_showSameAsCurrentError) {
      return _HelperSeverity.error;
    }
    if (_newPasswordRuleSeverityIsError) {
      return _HelperSeverity.error;
    }
    return _HelperSeverity.neutral;
  }

  String? get _confirmPasswordHelperText {
    if (!_showConfirmMismatchError) {
      return null;
    }
    return '비밀번호가 일치하지 않습니다.';
  }

  void _handleCurrentPasswordChanged(String value) {
    setState(() {
      _currentPasswordError = null;
    });
  }

  void _handleNewPasswordChanged(String value) {
    setState(() {
      _showNewPasswordRuleHint = value.isNotEmpty && !_isNewPasswordValid;
      if (!_showNewPasswordRuleHint) {
        _newPasswordRuleSeverityIsError = false;
      }
      _showSameAsCurrentError = value.isNotEmpty && _isSameAsCurrentPassword;
      _showConfirmMismatchError =
          _confirmPassword.isNotEmpty && !_isConfirmMatched;
    });
  }

  void _handleConfirmPasswordChanged(String value) {
    setState(() {
      _showConfirmMismatchError = value.isNotEmpty && !_isConfirmMatched;
    });
  }

  void _clearField(
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    controller.clear();
    onChanged('');
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    setState(() {
      _currentPasswordError = _isCurrentPasswordValid
          ? null
          : _PasswordChangeErrorType.currentMismatch;
      _showNewPasswordRuleHint =
          _newPassword.isNotEmpty && !_isNewPasswordValid;
      _newPasswordRuleSeverityIsError = _showNewPasswordRuleHint;
      _showSameAsCurrentError =
          _newPassword.isNotEmpty && _isSameAsCurrentPassword;
      _showConfirmMismatchError =
          _confirmPassword.isNotEmpty && !_isConfirmMatched;
    });

    if (!_canSubmit) {
      return;
    }

    context.pop();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BridgeAppBar(title: '비밀번호 수정', onBack: context.pop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.pageHorizontal,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _PasswordChangeField(
                          label: '기존 비밀번호',
                          placeholder: '기존 비밀번호를 입력해주세요',
                          controller: _currentPasswordController,
                          focusNode: _currentPasswordFocusNode,
                          helperText: _currentPasswordHelperText,
                          helperSeverity: _currentPasswordHelperText != null
                              ? _HelperSeverity.error
                              : _HelperSeverity.neutral,
                          onChanged: _handleCurrentPasswordChanged,
                          onClear: () {
                            _clearField(
                              _currentPasswordController,
                              _handleCurrentPasswordChanged,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _PasswordChangeField(
                          label: '새 비밀번호',
                          placeholder: '새 비밀번호를 입력해주세요',
                          controller: _newPasswordController,
                          focusNode: _newPasswordFocusNode,
                          helperText: _newPasswordHelperText,
                          helperSeverity: _newPasswordHelperSeverity,
                          onChanged: _handleNewPasswordChanged,
                          onClear: () {
                            _clearField(
                              _newPasswordController,
                              _handleNewPasswordChanged,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _PasswordChangeField(
                          label: '새 비밀번호 확인',
                          placeholder: '새 비밀번호를 한번 더 입력해주세요',
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          helperText: _confirmPasswordHelperText,
                          helperSeverity: _confirmPasswordHelperText != null
                              ? _HelperSeverity.error
                              : _HelperSeverity.neutral,
                          onChanged: _handleConfirmPasswordChanged,
                          onClear: () {
                            _clearField(
                              _confirmPasswordController,
                              _handleConfirmPasswordChanged,
                            );
                          },
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Padding(
              padding: EdgeInsets.only(
                left: AppTokens.pageHorizontal,
                right: AppTokens.pageHorizontal,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
              ),
              child: _PasswordChangeButton(
                enabled: _canSubmit,
                onPressed: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordChangeField extends StatefulWidget {
  const _PasswordChangeField({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    required this.helperText,
    required this.helperSeverity,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? helperText;
  final _HelperSeverity helperSeverity;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PasswordChangeField> createState() => _PasswordChangeFieldState();
}

class _PasswordChangeFieldState extends State<_PasswordChangeField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _PasswordChangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_refresh);
      widget.focusNode.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showClearButton =
        widget.focusNode.hasFocus && widget.controller.text.isNotEmpty;

    final Color borderColor = widget.helperSeverity == _HelperSeverity.error
        ? AppColors.destructive
        : AppColors.gray200;

    final Color helperColor = widget.helperSeverity == _HelperSeverity.error
        ? AppColors.destructive
        : AppColors.gray500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.gray600),
        ),
        const SizedBox(height: 10),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onChanged: widget.onChanged,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  cursorColor: AppColors.black,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkBlack,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.gray300,
                    ),
                  ),
                ),
              ),
              if (showClearButton) ...[
                const SizedBox(width: 3),
                GestureDetector(
                  onTap: widget.onClear,
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/icons/Clear button.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 18,
          child: widget.helperText == null
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      widget.helperText!,
                      style: AppTypography.captionMedium.copyWith(
                        color: helperColor,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PasswordChangeButton extends StatelessWidget {
  const _PasswordChangeButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.buttonRadius),
          ),
        ),
        child: Text(
          '완료',
          style: AppTypography.headlineMedium.copyWith(
            color: enabled ? AppColors.white : AppColors.gray300,
          ),
        ),
      ),
    );
  }
}
