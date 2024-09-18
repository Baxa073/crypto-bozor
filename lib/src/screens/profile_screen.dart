import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/register_screen.dart';
import 'setting_screen.dart';
import '../themes/app_theme.dart'; // AppTheme import qilish

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? firstName, lastName, phoneNumber, cardNumber, cardHolderName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserDetails();
  }

  void _checkUserDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          firstName = doc['firstName'];
          lastName = doc['lastName'];
          phoneNumber = doc['phoneNumber'];
          cardNumber = doc['cardNumber'];
          cardHolderName = doc['cardHolderName'];
        });
      } else {
        _showRegistrationForm();
      }
    }
  }

  void _showRegistrationForm() {
    // Foydalanuvchi ma'lumotlarini kiritish uchun forma
  }

  void _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RegisterScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chiqish paytida xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Profil', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mening Profilim',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: AppTheme.cardColor.withOpacity(0.8),
                elevation: 5,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text('Ism', style: TextStyle(color: Colors.white)),
                      subtitle: Text(firstName ?? 'Ism mavjud emas', style: TextStyle(color: Colors.white70)),
                    ),
                    Divider(color: Colors.blue),
                    ListTile(
                      leading: Icon(Icons.person_outline, color: Colors.blue),
                      title: Text('Familiya', style: TextStyle(color: Colors.white)),
                      subtitle: Text(lastName ?? 'Familiya mavjud emas', style: TextStyle(color: Colors.white70)),
                    ),
                    Divider(color: Colors.blue),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.blue),
                      title: Text('Telefon raqam', style: TextStyle(color: Colors.white)),
                      subtitle: Text(phoneNumber ?? 'Telefon raqam mavjud emas', style: TextStyle(color: Colors.white70)),
                    ),
                    Divider(color: Colors.blue),
                    ListTile(
                      leading: Icon(Icons.credit_card, color: Colors.blue),
                      title: Text('Karta raqami', style: TextStyle(color: Colors.white)),
                      subtitle: Text(cardNumber ?? 'Karta raqami mavjud emas', style: TextStyle(color: Colors.white70)),
                    ),
                    Divider(color: Colors.blue),
                    ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text('Karta egasi', style: TextStyle(color: Colors.white)),
                      subtitle: Text(cardHolderName ?? 'Karta egasi mavjud emas', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  child: Text('Chiqish', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.blue], // Qora va ko'k rangli gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
