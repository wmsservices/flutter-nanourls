import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../helpers/glyph_helper.dart';

class OnboardingScreen extends StatefulWidget {
  // Static flag to disable infinite looping in test environments
  static bool isTesting = false;

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    // Retrieve the target route and arguments passed from SplashScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final targetRoute = args?['targetRoute'] as String? ?? '/login';
    final targetArguments = args?['targetArguments'];

    Navigator.of(context).pushReplacementNamed(
      targetRoute,
      arguments: targetArguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient background glows
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.03),
                ),
              ),
            ),

            // Top bar with "Skip" button
            Positioned(
              top: 10,
              right: 16,
              child: AnimatedOpacity(
                opacity: isLastPage ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: isLastPage,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                    child: Text(
                      context.l10n('onboarding_skip'),
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main PageView content
            Column(
              children: [
                const SizedBox(height: 60.0),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildPage(
                        visualWidget: const ShortenAnimationWidget(),
                        titleKey: 'onboarding_title_1',
                        descKey: 'onboarding_desc_1',
                      ),
                      _buildPage(
                        visualWidget: const FilterAnimationWidget(),
                        titleKey: 'onboarding_title_2',
                        descKey: 'onboarding_desc_2',
                      ),
                      _buildPage(
                        visualWidget: const ShareAnimationWidget(),
                        titleKey: 'onboarding_title_3',
                        descKey: 'onboarding_desc_3',
                      ),
                    ],
                  ),
                ),

                // Bottom actions section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) => _buildDot(index)),
                      ),
                      const SizedBox(height: 32.0),

                      // Navigation Button
                      AnimatedCrossFade(
                        firstChild: SizedBox(
                          width: double.infinity,
                          height: 54.0,
                          child: ElevatedButton(
                            onPressed: _completeOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textLight,
                              shadowColor: AppColors.primary.withValues(alpha: 0.35),
                              elevation: 12,
                            ),
                            child: Text(
                              context.l10n('onboarding_start'),
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        secondChild: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48), // Spacing mock to balance layout
                            ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(16.0),
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.border, width: 1),
                                shadowColor: Colors.transparent,
                                elevation: 0,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, size: 24),
                            ),
                          ],
                        ),
                        crossFadeState: isLastPage
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required Widget visualWidget,
    required String titleKey,
    required String descKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual Illustration Card Area
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInner,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.0),
                    child: visualWidget,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36.0),

          // Descriptive Text Info Area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  context.l10n(titleKey),
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  context.l10n(descKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15.0,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isSelected ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

// -------------------------------------------------------------
// Slide 1 Animation: Link Shortening (with go.nanourls.com/short & nurls.me/short)
// -------------------------------------------------------------
class ShortenAnimationWidget extends StatefulWidget {
  const ShortenAnimationWidget({super.key});

  @override
  State<ShortenAnimationWidget> createState() => _ShortenAnimationWidgetState();
}

class _ShortenAnimationWidgetState extends State<ShortenAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _typingAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final String _targetText = "https://github.com/rafaelwms/projects/nanourls";
  int _state = 0; // 0: typing, 1: typed/ready, 2: shortening transition, 3: shortened results

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _typingAnimation = IntTween(begin: 0, end: _targetText.length).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.linear),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.55, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.70, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.65, curve: Curves.easeIn),
      ),
    );

    _controller.addListener(() {
      final val = _controller.value;
      int newState;
      if (val < 0.45) {
        newState = 0;
      } else if (val < 0.58) {
        newState = 1;
      } else if (val < 0.85) {
        newState = 2;
      } else {
        newState = 3;
      }

      if (newState != _state) {
        setState(() {
          _state = newState;
        });
      }
    });

    if (OnboardingScreen.isTesting) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMockResultPill(String url, {required bool isPrimary}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPrimary ? AppColors.primary : Colors.blueAccent.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? AppColors.primary : Colors.blueAccent).withValues(alpha: 0.2),
            blurRadius: 8.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPrimary ? Icons.bolt_rounded : Icons.link_rounded,
            color: isPrimary ? AppColors.primary : Colors.blueAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              url,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentText = _targetText.substring(0, _typingAnimation.value);

        return LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth * 0.84;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Top decoration dots
                Positioned(
                  top: 20,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Long URL text input field mockup
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _state < 2 ? 1.0 : 0.15,
                        child: Container(
                          width: cardWidth,
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: _state == 1
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.white70,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              if (_state == 0)
                                Container(
                                  width: 2.0,
                                  height: 14.0,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16.0),

                      // Trigger button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_state == 1)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4 * _glowAnimation.value),
                                    blurRadius: 20.0,
                                    spreadRadius: 8.0,
                                  ),
                                ],
                              ),
                            ),
                          AnimatedScale(
                            scale: _state == 1 ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: _state >= 1 ? AppColors.primary : AppColors.surface,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: _state >= 1 ? AppColors.textLight : AppColors.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16.0),

                      // Resulting links: go.nanourls.com/short and nurls.me/short
                      Opacity(
                        opacity: _opacityAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMockResultPill("https://go.nanourls.com/short", isPrimary: true),
                              const SizedBox(height: 8.0),
                              _buildMockResultPill("https://nurls.me/short", isPrimary: false),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Slide 2 Animation: List Filtering matching HomeScreen layout exactly
// -------------------------------------------------------------
class FilterAnimationWidget extends StatefulWidget {
  const FilterAnimationWidget({super.key});

  @override
  State<FilterAnimationWidget> createState() => _FilterAnimationWidgetState();
}

class _FilterAnimationWidgetState extends State<FilterAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _activeFilterState = 0; // 0: All, 1: Analytics Active, 2: Password Active

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _controller.addListener(() {
      final val = _controller.value;
      int newState;
      if (val < 0.33) {
        newState = 0;
      } else if (val < 0.66) {
        newState = 1;
      } else {
        newState = 2;
      }

      if (newState != _activeFilterState) {
        setState(() {
          _activeFilterState = newState;
        });
      }
    });

    if (OnboardingScreen.isTesting) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMockViewModeToggle() {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.view_list,
          color: AppColors.primary,
          size: 18.0,
        ),
      ),
    );
  }

  Widget _buildMockGlyphDropdown(BuildContext context) {
    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: AppColors.primary, size: 18),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    context.l10n('filter_all_glyphs'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.0,
                      fontFamily: 'SplineSans',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4.0),
          const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildMockFilterToggle(IconData icon, bool isSelected, {bool isLock = false}) {
    final displayIcon = isLock
        ? (isSelected ? Icons.lock : Icons.lock_open)
        : icon;

    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          displayIcon,
          color: isSelected ? AppColors.primary : AppColors.textMuted,
          size: 18.0,
        ),
      ),
    );
  }

  Widget _buildMockCard({
    required String title,
    required String shortUrl,
    required bool hasAnalytics,
    required bool hasPassword,
    required String glyph,
    required bool isVisible,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          height: isVisible ? null : 0.0,
          margin: EdgeInsets.only(bottom: isVisible ? 8.0 : 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  GlyphHelper.getIconData(glyph),
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shortUrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasPassword) ...[
                const Icon(Icons.lock, color: Colors.amber, size: 12),
                const SizedBox(width: 6.0),
              ],
              if (hasAnalytics)
                const Icon(Icons.bar_chart, color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showCard1 = _activeFilterState == 0 || _activeFilterState == 1; // Google (Analytics)
    final showCard2 = _activeFilterState == 0 || _activeFilterState == 2; // GitHub (Password)
    final showCard3 = _activeFilterState == 0 || _activeFilterState == 1 || _activeFilterState == 2; // Spotify (Both)

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 300.0,
        height: 300.0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field from HomeScreen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInner,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n('search_hint'),
                        style: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                          fontSize: 13.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // Filter Controls Row (Fidelity with HomeScreen)
              Row(
                children: [
                  _buildMockViewModeToggle(),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMockGlyphDropdown(context),
                  ),
                  const SizedBox(width: 8.0),
                  _buildMockFilterToggle(Icons.bar_chart, _activeFilterState == 1),
                  const SizedBox(width: 8.0),
                  _buildMockFilterToggle(Icons.lock, _activeFilterState == 2, isLock: true),
                ],
              ),
              const SizedBox(height: 12.0),

              // Cards list
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMockCard(
                      title: "google.com",
                      shortUrl: "go.nanourls.com/g",
                      hasAnalytics: true,
                      hasPassword: false,
                      glyph: "search",
                      isVisible: showCard1,
                    ),
                    _buildMockCard(
                      title: "github.com",
                      shortUrl: "nurls.me/git",
                      hasAnalytics: false,
                      hasPassword: true,
                      glyph: "code",
                      isVisible: showCard2,
                    ),
                    _buildMockCard(
                      title: "spotify.com",
                      shortUrl: "go.nanourls.com/sp",
                      hasAnalytics: true,
                      hasPassword: true,
                      glyph: "music_note",
                      isVisible: showCard3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Slide 3 Animation: Card Expand & QR Code Dialog Pop-up
// -------------------------------------------------------------
class ShareAnimationWidget extends StatefulWidget {
  const ShareAnimationWidget({super.key});

  @override
  State<ShareAnimationWidget> createState() => _ShareAnimationWidgetState();
}

class _ShareAnimationWidgetState extends State<ShareAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _laserAnimation;
  late Animation<double> _dialogOpacity;
  late Animation<double> _dialogScale;

  int _cycleState = 0; // 0: cursor moving to more_vert, 1: clicking more_vert, 2: menu open & cursor moving to QR, 3: clicking QR, 4: menu closes/dialog opening, 5: laser scan loop

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );

    _dialogOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 0.52, curve: Curves.easeIn),
      ),
    );

    _dialogScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 0.55, curve: Curves.elasticOut),
      ),
    );

    _laserAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 0.95), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 0.05), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.95, curve: Curves.easeInOut),
      ),
    );

    _controller.addListener(() {
      final val = _controller.value;
      int newState;
      if (val < 0.18) {
        newState = 0;
      } else if (val < 0.24) {
        newState = 1;
      } else if (val < 0.38) {
        newState = 2;
      } else if (val < 0.44) {
        newState = 3;
      } else if (val < 0.52) {
        newState = 4;
      } else {
        newState = 5;
      }

      if (newState != _cycleState) {
        setState(() {
          _cycleState = newState;
        });
      }
    });

    if (OnboardingScreen.isTesting) {
      _controller.forward();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMockMenuItem(BuildContext context, IconData icon, String label, Color iconColor, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
      child: Row(
        children: [
          Icon(icon, size: 16.0, color: isSelected ? AppColors.primary : iconColor),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 320.0,
        height: 320.0,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final val = _controller.value;
            double curRight = 20.0;
            double curTop = 200.0;
            double curScale = 1.0;
            bool showPointer = false;

            if (val < 0.18) {
              showPointer = true;
              final double progress = (val / 0.18).clamp(0.0, 1.0);
              curRight = Tween<double>(begin: 20.0, end: 38.0).transform(progress);
              curTop = Tween<double>(begin: 200.0, end: 20.0).transform(progress);
            } else if (val < 0.24) {
              showPointer = true;
              curRight = 38.0;
              curTop = 20.0;
              final double progress = ((val - 0.18) / 0.06).clamp(0.0, 1.0);
              curScale = TweenSequence<double>([
                TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.75), weight: 50),
                TweenSequenceItem(tween: Tween<double>(begin: 0.75, end: 1.0), weight: 50),
              ]).transform(progress);
            } else if (val < 0.38) {
              showPointer = true;
              final double progress = ((val - 0.24) / 0.14).clamp(0.0, 1.0);
              curRight = Tween<double>(begin: 38.0, end: 50.0).transform(progress);
              curTop = Tween<double>(begin: 20.0, end: 88.0).transform(progress);
            } else if (val < 0.44) {
              showPointer = true;
              curRight = 50.0;
              curTop = 88.0;
              final double progress = ((val - 0.38) / 0.06).clamp(0.0, 1.0);
              curScale = TweenSequence<double>([
                TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.75), weight: 50),
                TweenSequenceItem(tween: Tween<double>(begin: 0.75, end: 1.0), weight: 50),
              ]).transform(progress);
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // Background Expanded Card (Fidelity with Expanded UrlCard)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Opacity(
                    opacity: _cycleState >= 4 ? 0.2 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.music_note, color: AppColors.primary, size: 16),
                              ),
                              const SizedBox(width: 10.0),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "go.nanourls.com/sp",
                                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 2.0),
                                    Text(
                                      "ACTIVE",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9.0,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.more_vert, color: _cycleState == 1 ? AppColors.primary : AppColors.textMuted, size: 20),
                              const SizedBox(width: 4.0),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white30, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8.0),

                          // Target/Original URL Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceInner,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: const Text(
                              "https://spotify.com/playlist/my-favorites",
                              style: TextStyle(fontFamily: 'Courier', fontSize: 11.0, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // Description
                          const Text(
                            "My favorite songs playlist",
                            style: TextStyle(fontSize: 12.0, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),

                          const Divider(color: AppColors.borderSubtle, height: 1.0),
                          const SizedBox(height: 8.0),

                          // Click counter & buttons
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 270.0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.bar_chart, size: 14.0, color: AppColors.primary),
                                        SizedBox(width: 4.0),
                                        Text("45 clicks", style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),

                                  // Share Action Button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white10, width: 1.0),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Theme.of(context).platform == TargetPlatform.iOS ? Icons.ios_share : Icons.share,
                                          size: 11.0,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          context.l10n('share'),
                                          style: const TextStyle(fontSize: 11.0, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
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

                // Mock Popup Menu Dropdown Overlay
                if (_cycleState == 2 || _cycleState == 3)
                  Positioned(
                    right: 20.0,
                    top: 44.0,
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.border, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMockMenuItem(context, Icons.info_outline, context.l10n('details'), AppColors.primary, false),
                          _buildMockMenuItem(context, Icons.qr_code, context.l10n('qr_code'), Colors.blueAccent, _cycleState == 3),
                          _buildMockMenuItem(context, Icons.edit, context.l10n('edit'), Colors.white70, false),
                          _buildMockMenuItem(context, Icons.delete, context.l10n('delete'), Colors.redAccent, false),
                        ],
                      ),
                    ),
                  ),

                // Touch pointer overlay
                if (showPointer)
                  Positioned(
                    right: curRight,
                    top: curTop,
                    child: Transform.scale(
                      scale: curScale,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // QrCodeDialog popup mockup (Fidelity with QrCodeDialog)
                if (_cycleState >= 4)
                  Opacity(
                    opacity: _dialogOpacity.value,
                    child: Transform.scale(
                      scale: _dialogScale.value,
                      child: Container(
                        width: 240, // Fixed width on canvas
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: AppColors.border, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dialog Title
                            Text(
                              context.l10n('qr_code_dialog_title'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0),
                            ),
                            const SizedBox(height: 8.0),

                            // White QR Code Image Container
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6.0),
                                    child: CustomPaint(
                                      size: const Size(80, 80),
                                      painter: QRPainter(color: Colors.black87),
                                    ),
                                  ),
                                ),
                                // Laser scan line animation
                                if (_cycleState == 5)
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 88 * _laserAnimation.value,
                                    child: Container(
                                      height: 2.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                            blurRadius: 4,
                                            spreadRadius: 1.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8.0),

                            // Underline Shortlink text
                            const Text(
                              "go.nanourls.com/sp",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10.0),

                            // Mock Share Button
                            Container(
                              width: double.infinity,
                              height: 36.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Theme.of(context).platform == TargetPlatform.iOS ? Icons.ios_share : Icons.share,
                                    size: 13,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    context.l10n('share'),
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6.0),

                            // Mock Close Button
                            Container(
                              width: double.infinity,
                              height: 36.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: AppColors.border, width: 1.0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.l10n('close'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Custom Painter to draw finder patterns and QR dots
class QRPainter extends CustomPainter {
  final Color color;
  QRPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    void drawFinderPattern(double x, double y, double size) {
      canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);
      canvas.drawRect(
        Rect.fromLTWH(x + size / 6, y + size / 6, size * 2 / 3, size * 2 / 3),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + size * 2 / 6, y + size * 2 / 6, size * 2 / 6, size * 2 / 6),
        paint,
      );
    }

    final double patternSize = w * 0.32;
    drawFinderPattern(0, 0, patternSize);
    drawFinderPattern(w - patternSize, 0, patternSize);
    drawFinderPattern(0, h - patternSize, patternSize);

    final randomDots = [
      Rect.fromLTWH(w * 0.42, h * 0.10, w * 0.10, h * 0.10),
      Rect.fromLTWH(w * 0.56, h * 0.06, w * 0.10, h * 0.14),
      Rect.fromLTWH(w * 0.10, h * 0.42, w * 0.14, h * 0.10),
      Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.10, h * 0.14),
      Rect.fromLTWH(w * 0.44, h * 0.48, w * 0.18, h * 0.10),
      Rect.fromLTWH(w * 0.66, h * 0.42, w * 0.10, h * 0.20),
      Rect.fromLTWH(w * 0.80, h * 0.42, w * 0.10, h * 0.10),
      Rect.fromLTWH(w * 0.42, h * 0.72, w * 0.10, h * 0.20),
      Rect.fromLTWH(w * 0.58, h * 0.82, w * 0.18, h * 0.10),
      Rect.fromLTWH(w * 0.82, h * 0.82, w * 0.10, h * 0.10),
    ];

    for (final rect in randomDots) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
