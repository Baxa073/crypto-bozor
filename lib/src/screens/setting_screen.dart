import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../themes/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  String? firstName, lastName, phoneNumber, cardNumber, cardHolderName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Foydalanuvchi ma'lumotlarini yuklash
  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          firstName = doc['firstName'] ?? '';
          lastName = doc['lastName'] ?? '';
          phoneNumber = doc['phoneNumber'] ?? '';
          cardNumber = doc['cardNumber'] ?? '';
          cardHolderName = doc['cardHolderName'] ?? '';
        });
      } else {
        // Foydalanuvchi ma'lumotlari mavjud emas, bo‘sh form ochiladi
        setState(() {
          firstName = '';
          lastName = '';
          phoneNumber = '';
          cardNumber = '';
          cardHolderName = '';
        });
      }
    }
  }

  // Ma'lumotlarni yangilash funksiyasi
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      User? user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'firstName': firstName,
            'lastName': lastName,
            'phoneNumber': phoneNumber,
            'cardNumber': cardNumber,
            'cardHolderName': cardHolderName,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ma\'lumotlar muvaffaqiyatli yangilandi')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik yuz berdi: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // AppBarni fonga kiritish
      appBar: AppBar(
        title: Text('Sozlamalar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // AppBar shaffof bo'lishi uchun
        elevation: 0,
      ),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 100), // AppBar ostida joy ajratish
                  _buildHeaderText('Profil Ma\'lumotlari'),
                  SizedBox(height: 20),
                  _buildUserInfoCard(),
                  SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      color: AppTheme.cardColor.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextFormField('Ism', firstName, (value) => firstName = value),
            Divider(color: Colors.grey[300], height: 40),
            _buildTextFormField('Familiya', lastName, (value) => lastName = value),
            Divider(color: Colors.grey[300], height: 40),
            _buildTextFormField(
              'Telefon raqam',
              phoneNumber,
                  (value) => phoneNumber = value,
              keyboardType: TextInputType.phone,
            ),
            Divider(color: Colors.grey[300], height: 40),
            _buildTextFormField(
              'Karta raqami',
              cardNumber,
                  (value) => cardNumber = value,
              keyboardType: TextInputType.number,
            ),
            Divider(color: Colors.grey[300], height: 40),
            _buildTextFormField('Karta egasi', cardHolderName, (value) => cardHolderName = value),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, String? initialValue, Function(String?) onSaved,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      validator: (value) => value!.isEmpty ? '$label kiriting' : null,
      onSaved: onSaved,
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Ma\'lumotlarni yangilash', style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  GradientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ekranni to'liq egallash
      height: double.infinity, // Ekranni to'liq egallash
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundColorStart, AppTheme.backgroundColorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
