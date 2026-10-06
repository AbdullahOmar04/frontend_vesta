import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/colors.dart';
import 'package:frontend_vesta/Helpers/ui.dart';
import 'package:frontend_vesta/Screens/Onboarding/login.dart';
import 'package:frontend_vesta/Screens/Onboarding/onboarding_questions.dart';

class OnboardingSplash extends StatelessWidget {
  const OnboardingSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: VestaBackground(
        child: Stack(
          children: [
            // Soft accent glow behind the mark, as in the prototype.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 0.75,
                    colors: [
                      scheme.primary.withValues(alpha: dark ? 0.28 : 0.18),
                      scheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _PixelConfetti()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VestaSpace.xl),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Image.asset(
                      'assets/images/vesta_head.png',
                      height: 128,
                      color: dark ? scheme.onSurface : v.accentInk,
                      filterQuality: FilterQuality.medium,
                    ),
                    const SizedBox(height: VestaSpace.lg),
                    Text(
                      'Welcome to Vesta',
                      textAlign: TextAlign.center,
                      style: headingStyle(26),
                    ),
                    const SizedBox(height: VestaSpace.sm),
                    Text(
                      'Log in or create an account to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: v.muted),
                    ),
                    const SizedBox(height: VestaSpace.xl),
                    PrimaryButton(
                      label: 'Log in',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlineButton(
                      label: 'Sign up',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingQuestions(),
                          ),
                        );
                      },
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A few small coloured squares scattered over the welcome screen, after the
/// floating pixels in the prototype (static here).
class _PixelConfetti extends StatelessWidget {
  const _PixelConfetti();

  @override
  Widget build(BuildContext context) {
    final v = context.vesta;
    // (x, y, size, colour, opacity) with x and y as fractions of the screen.
    final pixels = [
      (0.10, 0.08, 7.0, v.pxGreen, 0.6),
      (0.47, 0.13, 6.0, v.pxPurple, 0.7),
      (0.28, 0.16, 8.0, v.pxPurple, 0.9),
      (0.27, 0.21, 8.0, v.pxBlue, 0.6),
      (0.52, 0.22, 8.0, v.pxGreen, 0.5),
      (0.95, 0.24, 6.0, v.pxBlue, 0.7),
      (0.10, 0.50, 8.0, v.pxYellow, 0.6),
      (0.88, 0.44, 8.0, v.pxBlue, 0.5),
      (0.16, 0.68, 6.0, v.pxGreen, 0.5),
      (0.40, 0.70, 8.0, v.pxYellow, 0.8),
      (0.81, 0.78, 8.0, v.pxPurple, 0.8),
      (0.48, 0.92, 6.0, v.pxTeal, 0.7),
    ];
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              for (final (x, y, size, color, opacity) in pixels)
                Positioned(
                  left: x * w,
                  top: y * h,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
