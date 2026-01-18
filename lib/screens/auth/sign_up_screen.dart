import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/cubits/auth/auth_cubit.dart';
import '/cubits/user/user_cubit.dart';
import '/screens/theme/app_theme.dart';
import '/utils/toast_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    print('❌ Error: $message');
    ToastUtils.showError(context, message);
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final displayName = _displayNameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting email sign-up...');
      await context.read<AuthCubit>().registerWithEmail(
        email,
        password,
        displayName,
      );
      print('✅ Email sign-up initiated');
      // Navigation happens in listener
    } catch (e) {
      print('❌ Email sign-up error: $e');
      _showError(e.toString());
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting Google sign-up...');
      await context.read<AuthCubit>().signInWithGoogle();
      print('✅ Google sign-up initiated');
      // Navigation happens in listener
    } catch (e) {
      print('❌ Google sign-up error: $e');
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlackColor),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, authState) {
              print('🔔 [SignUp] Auth state changed: ${authState.runtimeType}');
              
              if (authState is AuthAuthenticated) {
                print('✅ [SignUp] User authenticated: ${authState.userId}');
                
                // Initialize UserCubit
                context.read<UserCubit>().emit(
                  UserLoaded(currentUser: authState.currentUser),
                );
                
                // Start user stream
                context.read<UserCubit>().startUserStream(authState.userId);
                
                // Navigate to main screen
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    print('✅ [SignUp] Navigating to /main');
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main',
                      (route) => false,
                    );
                  }
                });
              } else if (authState is AuthError) {
                print('❌ [SignUp] Auth error: ${authState.message}');
                _showError(authState.message);
              } else if (authState is AuthLoading) {
                print('⏳ [SignUp] Auth loading...');
                setState(() {
                  _isLoading = true;
                });
              } else if (authState is AuthUnauthenticated) {
                print('🔓 [SignUp] User unauthenticated');
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
          
          BlocListener<UserCubit, UserState>(
            listener: (context, userState) {
              print('👤 [SignUp] User state changed: ${userState.runtimeType}');
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
                    const SizedBox(height: 20),
                    
                    // Heading
                    Text(
                      'Create Account',
                      style: kHeadingStyle.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sign up to get started!',
                      style: kBodyTextStyle,
                    ),
                    const SizedBox(height: 40),

                    // Display Name Input
                    TextField(
                      controller: _displayNameController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(hintText: 'Full Name'),
                      enabled: !_isLoading,
                    ),
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
                    const SizedBox(height: 20),

                    // Confirm Password Input
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Confirm Password',
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 30),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUpWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: kWhiteColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sign Up'),
                    ),

                    const SizedBox(height: 30),
                    const Center(child: Text('OR', style: kBodyTextStyle)),
                    const SizedBox(height: 30),

                    // ✅ Google Sign-Up Button
                    _buildSocialButton(
                      text: 'Sign up with Google',
                      color: kCardColor,
                      textColor: kBlackColor,
                      icon: Icons.g_mobiledata,
                      onTap: _signUpWithGoogle,
                    ),

                    const SizedBox(height: 20),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: kBodyTextStyle,
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
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