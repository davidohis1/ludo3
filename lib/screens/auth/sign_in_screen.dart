import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/cubits/auth/auth_cubit.dart';
import '/cubits/user/user_cubit.dart';
import '/screens/theme/app_theme.dart';
import '/utils/toast_utils.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    print('❌ Error: $message');
    ToastUtils.showError(context, message);
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting email sign-in...');
      await context.read<AuthCubit>().signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print('✅ Email sign-in initiated');
      // Navigation happens in listener
    } catch (e) {
      print('❌ Email sign-in error: $e');
      _showError(e.toString());
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting Google sign-in...');
      await context.read<AuthCubit>().signInWithGoogle();
      print('✅ Google sign-in initiated');
      // Navigation happens in listener
    } catch (e) {
      print('❌ Google sign-in error: $e');
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, authState) {
              print('🔔 [SignIn] Auth state changed: ${authState.runtimeType}');
              
              if (authState is AuthAuthenticated) {
                print('✅ [SignIn] User authenticated: ${authState.userId}');
                
                // Initialize UserCubit
                context.read<UserCubit>().emit(
                  UserLoaded(currentUser: authState.currentUser),
                );
                
                // Start user stream
                context.read<UserCubit>().startUserStream(authState.userId);
                
                // Navigate to main screen
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    print('✅ [SignIn] Navigating to /main');
                    Navigator.of(context).pushReplacementNamed('/main');
                  }
                });
              } else if (authState is AuthError) {
                print('❌ [SignIn] Auth error: ${authState.message}');
                _showError(authState.message);
              } else if (authState is AuthLoading) {
                print('⏳ [SignIn] Auth loading...');
                setState(() {
                  _isLoading = true;
                });
              } else if (authState is AuthUnauthenticated) {
                print('🔓 [SignIn] User unauthenticated');
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
          
          BlocListener<UserCubit, UserState>(
            listener: (context, userState) {
              print('👤 [SignIn] User state changed: ${userState.runtimeType}');
              if (userState is UserLoaded) {
                print('   Name: ${userState.currentUser.displayName}');
                print('   Coins: ${userState.currentUser.totalCoins}');
              }
            },
          ),
        ],
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    // App Title
                    Center(
                      child: Text(
                        'LudoTitan',
                        style: kHeadingStyle.copyWith(
                          color: kBlackColor.withOpacity(0.8),
                          fontSize: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // Heading
                    Text(
                      'Get Started',
                      style: kHeadingStyle.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Login or Sign Up to play.',
                      style: kBodyTextStyle,
                    ),
                    const SizedBox(height: 40),

                    // ✅ Google Sign-In Button
                    _buildSocialButton(
                      text: 'Continue with Google',
                      color: kCardColor,
                      textColor: kBlackColor,
                      icon: Icons.g_mobiledata,
                      onTap: _signInWithGoogle,
                    ),

                    const SizedBox(height: 20),
                    const Center(child: Text('OR', style: kBodyTextStyle)),
                    const SizedBox(height: 20),

                    // Email Input
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 20),
                    
                    // Password Input
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Password'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => _showError(
                                'Password reset feature not implemented.',
                              ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign In Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: kWhiteColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: kBodyTextStyle,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(context, '/sign_up'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: kPrimaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Color color,
    required Color textColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          minimumSize: const Size(double.infinity, 56),
          elevation: 2,
          shadowColor: Colors.black26,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}