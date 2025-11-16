import 'package:flutter/material.dart';
import 'dart:async';
import 'package:setor_mobil/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _animationController.forward();

    Future.delayed(Duration(milliseconds: 500), () {
      _bounceController.repeat(reverse: true);
    });

    _dotsController.repeat();

    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 80,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.directions_car,
                                size: 80,
                                color: Color(0xFF0066FF),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 40),

                      Text(
                        'SeTor-Mobil',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Sewa Motor & Mobil',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blue.shade100,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAnimatedDot(0),
                              SizedBox(width: 8),
                              _buildAnimatedDot(200),
                              SizedBox(width: 8),
                              _buildAnimatedDot(400),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 60),

                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    final value = (_dotsController.value - (index * 0.2)) % 1.0;
    final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
    final scale = 0.6 + (opacity * 0.4);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
