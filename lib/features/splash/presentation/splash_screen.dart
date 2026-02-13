import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // Fetch version information
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version =
              "Version ${packageInfo.version}";
        });
      }
    } catch (e) {
      // Silently fail version fetch, navigation should still proceed
      debugPrint("Error fetching package info: $e");
    }

    // Simulate a delay for the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check authentication state
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        // User is logged in, go to dashboard
        context.go('/dashboard');
      } else {
        // User is not logged in, go to auth
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Deep Navy Base
          Container(color: AppColors.navyDeep),

          // 2. Mesh Gradient Glow (Bottom Right)
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.7,
                  colors: [
                    AppColors.sage.withAlpha(102), // ~40% opacity
                    AppColors.navyDeep.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gold Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldLight, width: 2),
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.goldLight,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Metallic Gold Logo Text
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.goldLight, // Light Gold
                          AppColors.goldDark, // Dark Gold
                        ],
                      ).createShader(bounds),
                  child: Text(
                    'KanakkuFi',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'PREMIUM FINANCE',
                  style: GoogleFonts.inter(
                    color: Colors.white.withAlpha(128), // 0.5 opacity
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 80),

                // Minimalist Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Version Number
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _version,
                style: GoogleFonts.inter(
                  color: Colors.white.withAlpha(128), // 0.5 opacity
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
