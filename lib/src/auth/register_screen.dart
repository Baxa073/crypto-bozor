import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'auth_service.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String? _verificationId;
  bool _isCodeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _registerWithPhone() async {
    setState(() {
      _isLoading = true;
    });

    String phoneNumber = _phoneController.text.trim();

    try {
      await _authService.verifyPhoneNumber(phoneNumber, (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isCodeSent = true;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telefon orqali tizimga kirishda xatolik yuz berdi: $e')),
      );
    }
  }

  void _verifySMSCode() async {
    setState(() {
      _isLoading = true;
    });

    String smsCode = _codeController.text.trim();
    try {
      if (_verificationId != null) {
        await _authService.signInWithPhoneNumber(_verificationId!, smsCode);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(selectedIndex: 2)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kod noto‘g‘ri: $e')),
      );
    }
  }

  void _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(selectedIndex: 2)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google orqali tizimga kirishda xatolik yuz berdi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.backgroundColorStart, // Start color of the gradient
                  AppTheme.backgroundColorEnd,   // End color of the gradient
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Main content with translucent overlay
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Xush kelibsiz!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        _isCodeSent
                            ? 'SMS kodi yuborildi, iltimos, kodni kiriting'
                            : 'Davom etish uchun telefon raqamingizni kiriting',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      if (_isLoading)
                        CircularProgressIndicator()
                      else if (_isCodeSent)
                        _buildTextField(_codeController, 'SMS kodi')
                      else
                        _buildTextField(_phoneController, 'Telefon raqam'),
                      SizedBox(height: 20),
                      _buildSubmitButton(),
                      SizedBox(height: 20),
                      _buildGoogleSignInButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: hintText,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      style: TextStyle(color: Colors.white),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isCodeSent ? _verifySMSCode : _registerWithPhone,
      child: Text(_isCodeSent ? 'Tasdiqlash' : 'Telefon raqam bilan tizimga kirish'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.0), backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ), // Change the button color to match theme
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton.icon(
      onPressed: _registerWithGoogle,
      icon: Image.asset('assets/icons/google.png', height: 24), // Add Google icon
      label: Text('Google bilan tizimga kirish'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
