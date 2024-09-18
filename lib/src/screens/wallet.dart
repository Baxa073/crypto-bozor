import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darttonconnect/models/wallet_app.dart';
import 'package:darttonconnect/ton_connect.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uzbek_crypto/src/screens/transactions_screen.dart';

import '../models/jetton_model.dart'; // Jetton model importi
import '../themes/app_theme.dart';
import 'jetton_transfer_screen.dart'; // Jetton transfer page importi

class WalletScreen extends StatefulWidget {
  final Function(bool, String) onWalletConnectionChange;

  WalletScreen({required this.onWalletConnectionChange});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TonConnect connector = TonConnect(
    'https://gist.githubusercontent.com/YOUR_gistfile1.txt',
  );

  bool _isLoading = false;
  String walletAddress = '';
  double balance = 0.0;
  Timer? _bridgeMonitorTimer;
  String currency = 'TON';
  List<Jetton> jettonList = [];

  static const String apiKey = 'YOUR API KEY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!connector.connected) {
        restoreConnection();
      } else {
        loadData();
      }
      _bridgeMonitorTimer = Timer.periodic(Duration(seconds: 20), (timer) {
        if (mounted) {
          monitorBridgeStatus();
        }
      });
    });

    connector.onStatusChange((walletInfo) async {
      if (mounted) {
        setState(() {
          walletAddress = walletInfo.account.address.toString();
        });
        await loadData();
      }
    });
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (walletAddress.isNotEmpty) {
        balance = await fetchWalletBalance(walletAddress);
        jettonList = await fetchJettons(walletAddress);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _bridgeMonitorTimer?.cancel();
    super.dispose();
  }

  Future<List<Jetton>> fetchJettons(String walletAddress) async {
    try {
      final response = await http.get(
        Uri.parse('https://tonapi.io/v2/accounts/$walletAddress/jettons'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Jetton> jettonList = [];

        if (data is Map && data.containsKey('balances')) {
          List balances = data['balances'];
          for (var balanceItem in balances) {
            var jetton = balanceItem['jetton'];
            var balance = balanceItem['balance'];
            if (jetton != null && jetton.containsKey('name')) {
              double balanceInJetton = double.tryParse(balance.toString()) ?? 0.0;
              balanceInJetton /= 1e9; // Convert balance from nanoJetton to Jetton
              jettonList.add(Jetton(
                name: jetton['name'],
                balance: balanceInJetton,
                walletAddress: walletAddress,
              ));
            }
          }
        }
        return jettonList;
      } else {
        print('Jettonlarni olishda xatolik: ${response.reasonPhrase}');
        return [];
      }
    } catch (e) {
      print('Jettonlarni olishda ulanish xatosi: $e');
      return [];
    }
  }

  Future<double> fetchWalletBalance(String walletAddress) async {
    try {
      final response = await http.get(
        Uri.parse('https://tonapi.io/v2/accounts/$walletAddress'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('balance')) {
          double balance = double.tryParse(data['balance'].toString()) ?? 0.0;
          return balance / 1e9; // Convert balance from nanoton to TON
        } else {
          print('Balans ma\'lumotlari topilmadi.');
          return 0.0;
        }
      } else {
        print('Balansni olishda xatolik: ${response.reasonPhrase}');
        return 0.0;
      }
    } catch (e) {
      print('Balansni olishda ulanish xatosi: $e');
      return 0.0;
    }
  }

  void restoreConnection() async {
    if (!mounted) return;

    try {
      await connector.restoreConnection();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        print('Ulanishni tiklashda xatolik: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ulanishni tiklashda xatolik: $e')),
        );
      }
    }
  }

  void monitorBridgeStatus() {
    if (mounted && !connector.connected) {
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          restoreConnection();
        }
      });
    }
  }

  void disconnectWallet() {
    if (connector.connected) {
      connector.disconnect();
      setState(() {
        walletAddress = '';
        balance = 0.0;
        jettonList = [];
      });
      widget.onWalletConnectionChange(false, '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hamyon o\'chirilgan')),
      );
    }
  }

  Future<void> connectWallet() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final walletApp = WalletApp(
      universalUrl: 'https://app.tonkeeper.com/ton-connect',
      bridgeUrl: 'https://bridge.tonapi.io/bridge',
      name: 'Tonkeeper',
      image: 'https://tonkeeper.com/favicon.ico',
      aboutUrl: 'https://tonkeeper.com',
    );

    try {
      final universalLink = await connector.connect(walletApp);
      if (await canLaunch(universalLink)) {
        await launch(universalLink);
      } else {
        throw 'URL ochib bo\'lmadi: $universalLink';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ulanish muvaffaqiyatli amalga oshirildi!')),
      );
    } catch (e) {
      print('Ulanish jarayonida xatolik: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ulanish muvaffaqiyatsiz tugadi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBalanceCard(double screenWidth) {
    double fontSize = screenWidth > 600 ? 28 : 24;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAddressInfo(),
              const SizedBox(height: 20),
              Text(
                'Balans: ${balance.toStringAsFixed(2)} $currency',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
          const SizedBox(width: 10),
          Text(
            'Manzil: ${getShortWalletAddress(walletAddress)}',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    double buttonWidth = screenWidth > 600 ? 150 : 100;  // Responsive width
    double buttonHeight = screenWidth > 600 ? 140 : 120;  // Responsive height

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center alignment
        children: <Widget>[
          Expanded(
            child: _buildCardButton(
              Icons.send,
              'Yuborish',
              Colors.blueAccent,
              _onSendPressed,
              buttonWidth,
              buttonHeight,
              textSize: 10.0, // Shrift o'lchamini o'zgartirish
            ),
          ),
          SizedBox(width: 10), // Space between buttons
          Expanded(
            child: _buildCardButton(
              Icons.qr_code,
              'To\'ldirish',
              Colors.blueAccent,
              _onFillPressed,
              buttonWidth,
              buttonHeight,
              textSize: 12.0, // Shrift o'lchamini o'zgartirish
            ),
          ),
          SizedBox(width: 10), // Space between buttons
          Expanded(
            child: _buildCardButton(
              Icons.history,
              'Tarix',
              Colors.blueAccent,
              _onTransactionHistoryPressed,
              buttonWidth,
              buttonHeight,
              textSize: 12.0, // Shrift o'lchamini o'zgartirish
            ),
          ),
        ],
      ),
    );
  }

  void _onSendPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JettonTransferPage(
          fromWalletAddress: walletAddress, // Foydalanuvchi wallet manzili
          jettons: jettonList, // Jettonlar ro'yxati
        ),
      ),
    );
  }
 

  void _onFillPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('To\'ldirish tugmasi bosildi')),
    );
  }

  void _onTransactionHistoryPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionScreen(walletAddress: walletAddress),
      ),
    );
  }

  Widget _buildCardButton(IconData icon, String label, Color color, Function onPressed, double width, double height, {required double textSize}) {
    return Card(
      color: AppTheme.cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => onPressed(),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color), // Icon hajmi kichikroq
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15, // Tugmalar uchun matn hajmi kichikroq
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJettonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Tokenlar:',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${balance.toStringAsFixed(2)} \$',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              jettonList.isNotEmpty
                  ? Column(
                children: jettonList.map((jetton) {
                  return ListTile(
                    leading: Image.asset(
                      'assets/icons/${jetton.name.toLowerCase()}.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.money);
                      },
                    ),
                    title: Text(
                      jetton.name,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${jetton.balance.toStringAsFixed(2)} ${jetton.name.substring(0, 4).toUpperCase()}',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                    ),
                  );
                }).toList(),
              )
                  : Text(
                'Jettonlar yo\'q',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterOrConnectWidget() {
    return connector.connected
        ? Container()
        : Column(
        children: [
          _isLoading
              ? Lottie.asset('assets/animations/loading.json', width: 100, height: 100)
              : ElevatedButton(
            onPressed: connectWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Tonkeeper orqali ulash',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Ton Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C2C2E), // backgroundColorStart
              Color(0xFF0A84FF), // backgroundColorEnd
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 20),
                        _buildBalanceCard(screenWidth),
                        const SizedBox(height: 20),
                        _buildActionButtons(screenWidth),
                        _buildJettonList(),
                        const SizedBox(height: 20),
                        _buildRegisterOrConnectWidget(), // Wallet ulanish yoki ro'yxatdan o'tish bo'limi
                        if (connector.connected) _buildDisconnectButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return ElevatedButton(
      onPressed: connector.connected ? disconnectWallet : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.errorColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        'Hamyonni uzish',
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  String getShortWalletAddress(String? address) {
    if (address == null || address.length < 8) return 'Ulanmagan';
    return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
  }
}
