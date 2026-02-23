import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'auth_viewmodel.dart';
import '../../../core/utils/validator.dart';
import '../../../core/utils/rate_limiter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  bool isPhone = false; // Default to email as requested
  late TabController _tabController;
  late AnimationController _buttonController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _inputError;
  String? _otpError;
  final _throttler = Throttler(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _inputController.addListener(_clearInputError);
    _otpController.addListener(_clearOtpError);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          isPhone = _tabController.index == 0;
          _otpSent = false;
          _inputController.clear();
          _inputError = null;
          _stopTimer();
        });
      }
    });
  }

  void _clearInputError() {
    if (_inputError != null) setState(() => _inputError = null);
  }

  void _clearOtpError() {
    if (_otpError != null) setState(() => _otpError = null);
  }

  void _startTimer() {
    setState(() => _resendCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        _stopTimer();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buttonController.dispose();
    _inputController.dispose();
    _otpController.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (!_otpSent) {
            setState(() => _otpSent = true);
            _startTimer();
          } else {
            if (Supabase.instance.client.auth.currentUser != null) {
              context.go('/dashboard');
            }
          }
        },
        error: (error, _) {
          final message = _getErrorMessage(error);
          setState(() {
            if (_otpSent) {
              _otpError = message;
            } else {
              _inputError = message;
            }
          });

          // Only show SnackBar for non-field specific errors or if mapping fails
          if (message.contains("unexpected") || message.contains("network")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildBrandHeader(),
              const SizedBox(height: 40),
              _buildAuthToggle(),
              const SizedBox(height: 32),
              _buildAnimatedInputSection(),
              const SizedBox(height: 48),
              _buildPrimaryButton(),
              const SizedBox(height: 24),
              // Social login removed for cleaner look
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'otp_expired':
          return "The verification code has expired. Please request a new one.";
        case 'invalid_credentials':
          return "Invalid verification code. Please check and try again.";
        case 'over_email_send_rate_limit':
          return "Too many requests. Please wait a moment before trying again.";
        default:
          return error.message;
      }
    }
    return "An unexpected error occurred. Please try again.";
  }

  Widget _buildBrandHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Let's Get Started",
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your details to manage your Kanakku efficiently.",
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthToggle() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [Tab(text: "Phone Number"), Tab(text: "Email Address")],
      ),
    );
  }

  Widget _buildAnimatedInputSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeInQuart,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.1, 0.0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child:
          !_otpSent
              ? _buildEmailInputSection()
              : _buildOtpInputSection(key: const ValueKey("otp_section")),
    );
  }

  Widget _buildEmailInputSection() {
    return Column(
      key: const ValueKey("email_section"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPhone ? "Mobile Number" : "Email Address",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inputController,
          keyboardType:
              isPhone ? TextInputType.phone : TextInputType.emailAddress,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            hint: isPhone ? "98765 43210" : "name@example.com",
            icon: isPhone ? Icons.phone_android_rounded : Icons.email_outlined,
            error: _inputError,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputSection({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "OTP Verification",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _otpController.clear();
                  _otpError = null;
                  _stopTimer();
                });
              },
              child: const Text(
                "Change Email",
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ],
        ),
        const Text(
          "We've sent a 6-digit code to your email. Please enter it below.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
          decoration: _inputDecoration(
            hint: "000000",
            icon: Icons.lock_outline_rounded,
            error: _otpError,
          ).copyWith(counterText: ""),
        ),
        const SizedBox(height: 16),
        Center(
          child:
              _resendCountdown > 0
                  ? Text(
                    "Resend code in ${_resendCountdown}s",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  )
                  : TextButton(
                    onPressed: () {
                      _throttler.run(() {
                        final input = _inputController.text.trim();
                        ref.read(authProvider.notifier).sendOtp(input);
                        _startTimer();
                      });
                    },
                    child: const Text(
                      "Resend Verification Code",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(icon, color: AppColors.primary.withAlpha(150), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: AppColors.border.withAlpha(100)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 15,
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;

    return ScaleTransition(
      scale: _buttonController,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () async {
                    _buttonController.reverse().then(
                      (_) => _buttonController.forward(),
                    );
                    HapticFeedback.lightImpact();

                    final input = _inputController.text.trim();

                    if (!_otpSent) {
                      if (input.isEmpty) {
                        setState(() => _inputError = "Please enter your email");
                        return;
                      }
                      if (!isPhone) {
                        final error = Validator.validateEmail(input);
                        if (error != null) {
                          setState(() => _inputError = error);
                          return;
                        }
                      }

                      if (isPhone) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Phone authentication not implemented yet",
                            ),
                          ),
                        );
                        return;
                      }

                      _throttler.run(() {
                        ref.read(authProvider.notifier).sendOtp(input);
                      });
                    } else {
                      final otp = _otpController.text.trim();
                      final error = Validator.validateOtp(otp);
                      if (error != null) {
                        setState(() => _otpError = error);
                        return;
                      }

                      _throttler.run(() {
                        ref
                            .read(authProvider.notifier)
                            .verifyOtp(
                              email: input, // Use input (email) here
                              token: otp,
                            );
                      });
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            disabledBackgroundColor: AppColors.primary.withAlpha(150),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    _otpSent ? "Verify & Proceed" : "Get Verification Code",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ),
    );
  }
}
