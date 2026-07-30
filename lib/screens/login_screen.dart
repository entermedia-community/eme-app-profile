import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';
import '../services/workspace_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;
  final VoidCallback? onWorkspaceChanged;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    this.onWorkspaceChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'support@openedit.org');
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  late Workspace _selectedWorkspace;
  bool _isOtpStage = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  int _timerSeconds = 0;
  Timer? _resendTimer;
  String? _otpError;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedWorkspace = WorkspaceService.activeWorkspace;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _otpFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _fadeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = 30;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _resendTimer?.cancel();
          }
        });
      }
    });
  }

  void _sendOtp({bool isResend = false}) async {
    if (!_isOtpStage && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      await AuthService.sendMagicLink(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isOtpStage = true;
        _otpController.clear();
      });

      _startResendTimer();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF38B6FF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isResend
                      ? 'Verification code resent to your email!'
                      : 'Verification code sent to your email!',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF161C24),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF38B6FF).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_otpFocusNode.canRequestFocus) {
          _otpFocusNode.requestFocus();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: const Color(0xFFF50057),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) {
      setState(() {
        _otpError = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final success = await AuthService.loginWithOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        widget.onLoginSuccess(_emailController.text.trim());
      } else {
        setState(() {
          _isLoading = false;
          _otpError = 'Invalid verification code. Please try again.';
          _otpController.clear();
        });
        _otpFocusNode.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = e.toString().replaceAll('Exception: ', '');
        _otpController.clear();
      });
      _otpFocusNode.requestFocus();
    }
  }

  void _submit() {
    if (_isOtpStage) {
      _verifyOtp();
    } else {
      _sendOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F13), Color(0xFF141923), Color(0xFF0F1319)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glowing elements
            Positioned(
              top: -size.height * 0.2,
              right: -size.width * 0.1,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38B6FF).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.2,
              left: -size.width * 0.1,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8A2387).withValues(alpha: 0.06),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 450 : double.infinity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF161C24,
                              ).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 40,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Logo Container
                                  Center(
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF38B6FF,
                                            ).withValues(alpha: 0.2),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Image(
                                        image: AssetImage('assets/testu.png'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  const Text(
                                    'TestU Labs',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Single Sign-On (SSO)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF90A4AE),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  if (!_isOtpStage) ...[
                                    // Workspace Selection Menu
                                    const Text(
                                      'Workspace',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildWorkspaceDropdown(),
                                    const SizedBox(height: 20),

                                    // Email Address Input
                                    const Text(
                                      'Email Address',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      controller: _emailController,
                                      hintText: 'Enter your enterprise email',
                                      prefixIcon: Icons.email_outlined,
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!val.contains('@')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Remember me checkbox
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: const Color(
                                              0xFF38B6FF,
                                            ),
                                            checkColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _rememberMe = val ?? false;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember my session',
                                          style: TextStyle(
                                            color: Color(0xFF90A4AE),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // OTP Input Stage
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Verification Code',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isOtpStage = false;
                                              _otpController.clear();
                                              _otpError = null;
                                              _resendTimer?.cancel();
                                              _timerSeconds = 0;
                                            });
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Color(0xFF38B6FF),
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit Email',
                                                style: TextStyle(
                                                  color: Color(0xFF38B6FF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sent to ${_emailController.text}',
                                      style: const TextStyle(
                                        color: Color(0xFF90A4AE),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.hub_rounded,
                                          size: 12,
                                          color: Color(0xFF38B6FF),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Workspace: ${_selectedWorkspace.name}',
                                          style: const TextStyle(
                                            color: Color(0xFF38B6FF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildOtpInput(),
                                    if (_otpError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          _otpError!,
                                          style: const TextStyle(
                                            color: Color(0xFFF50057),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _timerSeconds > 0
                                              ? 'Resend code in ${_timerSeconds}s'
                                              : "Didn't receive the code? ",
                                          style: const TextStyle(
                                            color: Color(0xFF90A4AE),
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (_timerSeconds == 0)
                                          GestureDetector(
                                            onTap: () =>
                                                _sendOtp(isResend: true),
                                            child: const Text(
                                              'Resend Code',
                                              style: TextStyle(
                                                color: Color(0xFF38B6FF),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(height: 28),

                                  // Submit Button
                                  _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF38B6FF),
                                                ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF38B6FF),
                                                Color(0xFF8A2387),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF38B6FF,
                                                ).withValues(alpha: 0.25),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              _isOtpStage
                                                  ? 'Verify & Sign In'
                                                  : 'Send Verification Code',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),

                                  const SizedBox(height: 24),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Powered by eMe.world',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Stack(
      children: [
        // Hidden text field to capture inputs
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: _otpController,
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _otpError = null;
                });
                if (value.length == 6) {
                  _verifyOtp();
                }
              },
            ),
          ),
        ),
        // Visual representation of 6 digits
        GestureDetector(
          onTap: () {
            if (!_otpFocusNode.hasFocus) {
              _otpFocusNode.requestFocus();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              String char = '';
              if (_otpController.text.length > index) {
                char = _otpController.text[index];
              }

              final isFocused =
                  _otpFocusNode.hasFocus &&
                  (_otpController.text.length == index ||
                      (index == 5 && _otpController.text.length == 6));

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 5 ? 0 : 6,
                  ),
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1319),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF38B6FF)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isFocused ? 2.0 : 1.0,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF38B6FF,
                              ).withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    char,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1319),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 20,
          ),
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(color: Color(0xFFF50057), fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildWorkspaceDropdown() {
    final currentWorkspace = WorkspaceService.workspaces.firstWhere(
      (w) => w.id.toLowerCase() == _selectedWorkspace.id.toLowerCase(),
      orElse: () => _selectedWorkspace,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1319),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Workspace>(
          value: currentWorkspace,
          isExpanded: true,
          dropdownColor: const Color(0xFF161C24),
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white54,
          ),
          items: WorkspaceService.workspaces.map((ws) {
            final isSelected = ws.id == currentWorkspace.id;
            final color = ws.id == 'misur'
                ? const Color(0xFF0072FF)
                : ws.id == 'eme'
                    ? const Color(0xFF00C853)
                    : const Color(0xFF8A2387);
            return DropdownMenuItem<Workspace>(
              value: ws,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: color,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.hub_rounded,
                      size: 13,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ws.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF38B6FF)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        Text(
                          ws.mediaDBRoot,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Workspace? newWorkspace) async {
            if (newWorkspace != null) {
              final isLoggedIn =
                  await AuthService.switchWorkspace(newWorkspace);
              if (isLoggedIn) {
                widget.onLoginSuccess(
                  AuthService.currentUser?.email ?? AuthService.userId ?? '',
                );
              } else {
                setState(() {
                  _selectedWorkspace = newWorkspace;
                  _isOtpStage = false;
                  _otpController.clear();
                  _otpError = null;
                });
                widget.onWorkspaceChanged?.call();
              }
            }
          },
        ),
      ),
    );
  }
}
