import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:easy_localization/easy_localization.dart'; // Easy localization
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth import
import 'package:uzbek_crypto/src/auth/register_screen.dart';
import 'firebase_options.dart';
import 'src/screens/menu.dart';
import 'src/screens/wallet.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/transactions_screen.dart';
import 'src/themes/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase ni izolyatsiyada init qiling
  await Firebase.initializeApp();
  // Izolyatsiyada UI ga to'g'ridan-to'g'ri murojaat qilib bo'lmaydi
  // Bildirishnomani shu yerda ko'rsatish uchun FlutterLocalNotificationsPlugin ni qayta init qilish kerak
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Bildirishnomani ko'rsatish
  await _showNotification(flutterLocalNotificationsPlugin, message);
}

Future<void> _showNotification(
    FlutterLocalNotificationsPlugin plugin, RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  String title = message.notification?.title ?? 'Default Title';
  String body = message.notification?.body ?? 'Default Body';

  await plugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: message.data['route'], // Bildirishnoma bosilganda yo'naltirish uchun
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized(); // Easy localization uchun init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Check if the user is authenticated
  User? user = FirebaseAuth.instance.currentUser;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('uz'),
        Locale('en'),
        Locale('ru'),
        Locale('tr'),
        Locale('ar'),
      ],
      path: 'assets/translations', // Localization fayllar yo'li
      fallbackLocale: const Locale('en'),
      child: MyApp(
        isUserLoggedIn: user != null,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isUserLoggedIn;

  const MyApp({super.key, required this.isUserLoggedIn}); // Passed auth state

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Bozor',
      theme: AppTheme.themeData,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: isUserLoggedIn
          ? const MainScreen()
          : RegisterScreen(), // Show RegisterScreen if not logged in
      routes: {
        '/transaction': (context) => TransactionScreen(
          walletAddress: '',
        ),
      },
    );
  }
}

class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Center(
        child: Text('Welcome to the Admin Page'),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int selectedIndex;
  const MainScreen({this.selectedIndex = 0, super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  bool walletConnected = false;
  String walletAddress = '';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground xabar keldi: ${message.notification?.title}');
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      _showNotification(flutterLocalNotificationsPlugin, message);
    });
  }

  void _onWalletConnectionChange(bool connected, String address) {
    setState(() {
      walletConnected = connected;
      walletAddress = address;
    });
  }

  List<Widget> get _pages => <Widget>[
    HomeScreen(walletConnected: walletConnected),
    TransactionScreen(walletAddress: walletConnected ? walletAddress : ''),
    WalletScreen(onWalletConnectionChange: _onWalletConnectionChange),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) async {
    if (index == 3) {
      User? user = FirebaseAuth.instance.currentUser; // Hozirgi foydalanuvchini olish

      if (user != null && user.email == 'buxorovbahodir11@gmail.com') {
        // Agar foydalanuvchi admin bo'lsa, AdminPage ga olib o'tamiz
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
      } else {
        // Oddiy foydalanuvchi uchun profil sahifasini ko'rsatish
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'transactions'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: 'wallet'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        backgroundColor: AppTheme.cardColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
