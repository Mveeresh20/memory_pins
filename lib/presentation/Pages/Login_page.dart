import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/presentation/Pages/sign_up_page.dart';
import 'package:memory_pins_app/presentation/Widgets/sign_in_button.dart';
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/services/app_integration_service.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';
import 'package:memory_pins_app/eula/eula_content.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final AppIntegrationService _appService = AppIntegrationService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool _isEmailLoading = false;
  bool _isAppleLoading = false;
  bool _isGuestLoading = false;

  void _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isEmailLoading = true;
      });

      try {
        final success = await _appService.signInUser(
          context,
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;
        setState(() {
          _isEmailLoading = false;
        });

        if (success) {
          print("User signed in successfully");
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          if (!mounted) return;
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          final errorMessage =
              userProvider.error ?? 'Invalid credentials. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isEmailLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAppleSignIn() async {
    // Show EULA dialog on every Apple sign-in attempt
    showEulaAgreementDialog(
      context,
      withButtons: true,
      onAgreed: (value) {
        markEualStatusInLocal(agree: value);
        if (value) {
          // Proceed with Apple sign in after EULA agreement
          _performAppleSignIn();
        }
      },
    );
  }

  void _performAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.signInWithApple();

      if (!mounted) return;
      setState(() {
        _isAppleLoading = false;
      });

      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final errorMessage = userProvider.error ?? 'Apple sign in failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAppleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAnonymousSignIn() async {
    // Show EULA dialog on every anonymous sign-in attempt
    showEulaAgreementDialog(
      context,
      withButtons: true,
      onAgreed: (value) {
        markEualStatusInLocal(agree: value);
        if (value) {
          // Proceed with anonymous sign in after EULA agreement
          _performAnonymousSignIn();
        }
      },
    );
  }

  void _performAnonymousSignIn() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.signInAnonymously();

      if (!mounted) return;
      setState(() {
        _isGuestLoading = false;
      });

      if (success) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        final errorMessage = userProvider.error ?? 'Anonymous sign in failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGuestLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF15212F),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 23),
                      child: Text(
                        "Sign in",
                        style: GoogleFonts.kanit(
                          color: Color(0xFFEBA145),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Image.network(Images.signInImg, fit: BoxFit.contain),
                  ],
                ),
              ),

              SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintText: 'Enter your email...',
                    hintStyle: TextStyle(color: Color(0xFF919EAA)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3C495C)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3C495C)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFDAA520)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFDAA520)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorStyle: TextStyle(color: Color(0xFFDAA520)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),

              // Password Text Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !isPasswordVisible, // Toggle visibility
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintText: 'Enter your Password',
                    hintStyle: TextStyle(color: Color(0xFF919EAA)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3C495C)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF3C495C)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFDAA520)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFDAA520)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorStyle: TextStyle(color: Color(0xFFDAA520)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 28),

              _isEmailLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            _handleSignIn();
                          }
                        },
                        child: SignInButton(
                          text: "Sign in",
                          icon: Icons.arrow_forward_sharp,
                        ),
                      ),
                    ),
              SizedBox(height: 24),

              _isAppleLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          _handleAppleSignIn();
                        },
                        child: SignInButton(
                          iconFirst: true,
                          icon: Icons.apple_sharp,
                          text: "Sign in with Apple",
                          isWhiteBackground: true,
                        ),
                      ),
                    ),

              SizedBox(height: 12),

              _isGuestLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          _handleAnonymousSignIn();
                        },
                        child: SignInButton(
                          icon: Icons.arrow_forward_sharp,
                          text: "Continue as Guest",
                          isWhiteBackground: true,
                        ),
                      ),
                    ),
              SizedBox(height: 60),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/signup');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1.5,
                            color: Color(0xFFEBA145),
                          ),
                        ),
                      ),
                      child: Text(
                        "Sign up",
                        style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFFEBA145),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
