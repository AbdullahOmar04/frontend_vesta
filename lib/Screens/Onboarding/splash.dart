import 'package:flutter/material.dart';
import 'package:frontend_vesta/Helpers/widgets.dart';
import 'package:frontend_vesta/Screens/Onboarding/login.dart';
import 'package:frontend_vesta/Screens/Onboarding/register.dart';

class OnboardingSplash extends StatelessWidget {
  const OnboardingSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                      'Welcome To',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                SizedBox(
                  height: 160,
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: 400,
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/Dark.png',
                      width: 400,
                      height: 400,
                    ),
                  ),
                ),
                Text(
                  'Link. Manage. Thrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    splashSmallButton(
                      context,
                      'Log In',
                      Theme.of(context).colorScheme.primary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                    ),
                    Spacer(),
                    splashSmallButton(
                      context,
                      'Join Now',
                      Theme.of(context).colorScheme.secondary,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Register()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
