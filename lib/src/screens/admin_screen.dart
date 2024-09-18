import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uzbek_crypto/src/screens/transactions_screen.dart';
import 'profile_screen.dart'; // ProfileScreen sahifasini import qiling

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref("currencies");
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // FirebaseAuth instansiyasini yarating
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  void _addOrUpdateCurrency(String name, String price) {
    if (name.isNotEmpty && price.isNotEmpty && _imageUrl != null) {
      _databaseReference.child(name).set({
        "price": price,
        "image": _imageUrl,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Valyuta muvaffaqiyatli saqlandi')),
        );
        _nameController.clear();
        _priceController.clear();
        setState(() {
          _imageUrl = null;
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iltimos, barcha maydonlarni to\'ldiring')),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      // Upload image to Firebase Storage
      final ref = _storage.ref().child('currency_images/${pickedImage.name}');
      await ref.putFile(File(pickedImage.path));
      String downloadUrl = await ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut(); // Foydalanuvchini tizimdan chiqarish
    // ProfileScreen sahifasiga qaytarish
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Logout funksiyasini chaqirish
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Valyuta nomi',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Valyuta narxi (so\'m)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Rasm yuklash'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                ),
                SizedBox(width: 20),
                if (_imageUrl != null) Image.network(_imageUrl!, width: 50, height: 50),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addOrUpdateCurrency(
                _nameController.text.trim(),
                _priceController.text.trim(),
              ),
              child: Text('Saqlash'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: _databaseReference.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    Map<dynamic, dynamic> currencyMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    List<Widget> currencyList = currencyMap.keys.map((key) {
                      return ListTile(
                        leading: Image.network(
                          currencyMap[key]["image"] ?? 'https://via.placeholder.com/50',
                          width: 50,
                          height: 50,
                        ),
                        title: Text('$key: ${currencyMap[key]["price"]} so\'m'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _databaseReference.child(key).remove();
                          },
                        ),
                      );
                    }).toList();
                    return ListView(children: currencyList);
                  }
                  return Center(child: Text('Hech qanday valyuta mavjud emas'));
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0, // Admin sahifasi uchun tegishli indeksni belgilang
        selectedItemColor: Colors.blue,
        onTap: (index) {
          // Sahifani almashtirish mantiqi
          switch (index) {
            case 0:

              break;
            case 1:
// Replace with the actual wallet address
// Replace with the actual API key
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionScreen(walletAddress: '',


                  ),
                ),
              );
              break;

            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}
