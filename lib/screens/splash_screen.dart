import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

// Splash Screen displaying the SVG logo with premium pulsing animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Repeat the pulse back and forth
    _controller.repeat(reverse: true);

    // Transition to Login screen after a short delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glows (top-left & bottom-right)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.04),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.03),
              ),
              child: const SizedBox(),
            ),
          ),
          
          // Centered pulsing logo and label
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with dynamic shadows
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInner,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: SvgPicture.asset(
                      'assets/svg/logo.svg',
                      placeholderBuilder: (BuildContext context) => const CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Brand Name Text
                  const Text(
                    'NanoUrls',
                    style: TextStyle(
                      fontFamily: 'SplineSans',
                      fontSize: 36.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppColors.shadowGlow,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  
                  // Subtitle description matching site headers
                  Text(
                    'Encurte seus links com estilo',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
