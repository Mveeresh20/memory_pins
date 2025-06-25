import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
import 'package:memory_pins_app/presentation/Pages/home_screen.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding3.dart';
import 'package:memory_pins_app/presentation/Widgets/sign_in_button.dart';
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      print("Form is valid");

      try {
        final user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
        print("Trying to sign up with: ${_emailController.text.trim()}");
        print("Password: ${_passwordController.text.trim()}");

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          print("User signed up: ${user.email}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sign-up failed. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(pattern);
    if (value == null || value.isEmpty) return "Email is required";
    if (!regex.hasMatch(value)) return "Enter a valid email address";
    return null;
  }

  String? _validatePassword(String? value) {
    const pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    final regex = RegExp(pattern);
    if (value == null || value.isEmpty) return "Password is required";
    if (!regex.hasMatch(value)) {
      return "Password must be 8 characters length";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return "Passwords do not match";
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return "Name is required";
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                        "Sign up",
                        style: GoogleFonts.kanit(
                          color: Color(0xFFEBA145),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Image.network(Images.signUpImg, fit: BoxFit.contain),
                  ],
                ),
              ),

              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    labelText: 'Name',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintText: 'Enter your Name...',
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
                  validator: _validateName,
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
                  validator: _validateEmail,
                ),
              ),
              SizedBox(height: 16),

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
                  validator: _validatePassword,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _confirmPasswordController,

                  obscureText: !isPasswordVisible, // Toggle visibility
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintText: 'Re-Enter your Password',
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
                  validator: _validateConfirmPassword,
                ),
              ),
              SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      _handleSignUp();
                    }
                  },
                  child: SignInButton(
                    text: "Sign up",
                    icon: Icons.arrow_forward_sharp,
                  ),
                ),
              ),
              SizedBox(height: 18),

              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        _authService.signInWithApple();
                      },
                      child: SignInButton(
                        iconFirst: true,
                        icon: Icons.apple_sharp,
                        text: "Sign up with Apple",
                        isWhiteBackground: true,
                      ),
                    ),
                  ),

              SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await _authService.signInAnonymously(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("An error occurred: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: SignInButton(
                    icon: Icons.arrow_forward_sharp,
                    text: "Continue as Guest",
                    isWhiteBackground: true,
                  ),
                ),
              ),

              SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t have an account?",
                    style: GoogleFonts.nunitoSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(width: 4),

                  GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/login');
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
