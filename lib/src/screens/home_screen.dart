import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'crypto_detail_screen.dart';
import '../themes/app_theme.dart';
import 'package:intl/intl.dart'; // Narxni formatlash uchun intl paketini import qilamiz

class HomeScreen extends StatefulWidget {
  final bool walletConnected;

  HomeScreen({required this.walletConnected});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCryptos = [];
  List<dynamic> _allCryptos = [];
  bool _isLoading = true;
  bool _firstLoad = true;
  Timer? _timer;
  String usdtPrice = 'N/A'; // Initially set to 'N/A'
  double usdtToUzsRate = 12000; // Fallback rate

  @override
  void initState() {
    super.initState();
    fetchUsdtRateAndCryptos(); // Fetch P2P price and cryptos

    // Har 3 soniyada USDT va boshqa kriptolar uchun narxni yangilaymiz
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      fetchUsdtRateAndCryptos(showLoading: false); // Real-time yangilash
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Timer-ni to'xtatamiz
    super.dispose();
  }

  Future<void> fetchUsdtRateAndCryptos({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    // Fetch P2P USDT price
    String newUsdtPrice = await fetchP2PUsdtSellPrice();
    setState(() {
      usdtPrice = newUsdtPrice;
      usdtToUzsRate = double.tryParse(newUsdtPrice) ?? 12000; // fallback if parsing fails
    });

    // Fetch other cryptos
    fetchCryptos(showLoading: false);
  }

  // Fetch P2P USDT price from Binance P2P platform (Prodat - Sell Price)
  Future<String> fetchP2PUsdtSellPrice() async {
    final response = await http.post(
      Uri.parse('https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "asset": "USDT",
        "fiat": "UZS",
        "tradeType": "SELL",
        "page": 1,
        "rows": 1,
        "payTypes": [],
        "publisherType": null,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'].isNotEmpty && data['data'][0]['adv'] != null) {
        final price = data['data'][0]['adv']['price'];
        print('Fetched USDT Price: $price'); // Add print statement for debugging
        return price;
      } else {
        return "N/A";
      }
    } else {
      return "Error";
    }
  }

  // Ma'lumotlarni olish va kerakli koinlarni filtrlaymiz
  void fetchCryptos({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));

      if (response.statusCode == 200) {
        List<dynamic> cryptoData = json.decode(response.body);

        // Binance savdo juftliklarining to'g'ri ro'yxati
        List<String> filterSymbols = [
          'DOGSUSDT',
          'TONUSDT',
          'BTCUSDT',
          'NOTUSDT'
        ];

        List<dynamic> filteredData = cryptoData.where((crypto) {
          return filterSymbols.contains(crypto['symbol']);
        }).toList();

        setState(() {
          _allCryptos = filteredData;
          _filteredCryptos = _allCryptos;
          _isLoading = false;
          _firstLoad = false; // Birinchi yuklanish tugadi
        });
      } else {
        print('Xatolik: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (error) {
      print("Xatolik: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Qidiruv bo'yicha filtr
  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCryptos = _allCryptos;
      });
    } else {
      setState(() {
        _filteredCryptos = _allCryptos
            .where((crypto) =>
            crypto['symbol'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  /// Narxni dollardan so'mga o'girish funksiyasi
  String convertToUZS(double priceInUSD, double usdtToUzsRate) {
    double priceInUZS = priceInUSD * usdtToUzsRate;

    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
    return formatter.format(priceInUZS);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.backgroundColorStart,
                  AppTheme.backgroundColorEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchBar(),
                SizedBox(height: 20),
                _buildBannerSlider(),
                SizedBox(height: 20),
                _isLoading && _firstLoad // Faqat birinchi yuklanishda animatsiya ko'rsatamiz
                    ? Center(
                  child: Lottie.asset(
                    'assets/animations/loading.json', // Yuklanish animatsiyasi
                    width: 150,
                    height: 150,
                  ),
                )
                    : Expanded(
                  child: ListView.builder(
                    itemCount: _filteredCryptos.length + 1, // Add 1 for USDT
                    itemBuilder: (context, index) {
                      if (index == _filteredCryptos.length) {
                        // USDT uchun alohida kartani chiqaramiz
                        return _buildCryptoCard(
                          context,
                          'USDT',
                          double.tryParse(usdtPrice) ?? 0.0,
                          0.0, // USDT uchun priceChangePercent 0 bo'ladi
                          isUsdt: true, // USDT ekanligini ko'rsatish uchun
                        );
                      }
                      var crypto = _filteredCryptos[index];
                      return _buildCryptoCard(
                          context,
                          getCryptoName(crypto['symbol']),
                          double.tryParse(crypto['lastPrice']?.toString() ?? '0'),
                          double.tryParse(crypto['priceChangePercent']?.toString() ?? '0'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: filterSearchResults,
      decoration: InputDecoration(
        hintText: 'Qidirish...',
        hintStyle: TextStyle(color: Colors.white60),
        prefixIcon: Icon(Icons.search, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      style: TextStyle(color: Colors.white),
    );
  }

  Widget _buildBannerSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // No padding for full width
      child: CarouselSlider(
        items: [
          GestureDetector(
            onTap: () {
              // Handle tap for the first banner (if needed)
            },
            child: _buildBannerItem('assets/banner/banner1.png'),
          ),
          GestureDetector(
            onTap: () {
              // Handle tap for the second banner (if needed)
            },
            child: _buildBannerItem('assets/banner/banner2.png'),
          ),
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse('https://t.me/CRYPTOBOZOR_App');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                throw 'Could not launch $url';
              }
            },
            child: _buildBannerItem('assets/banner/banner3.png'),
          ),
        ],
        options: CarouselOptions(
          height: 150.0, // Banner height
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.95, // Almost full-screen width for each banner
          initialPage: 0,
          disableCenter: true, // Prevents centering of the selected banner, making the slider flush with screen edges
        ),
      ),
    );
  }
  Widget _buildBannerItem(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String getCryptoName(String symbol) {
    return symbol.replaceAll('USDT', ''); // Koin nomini USDT dan tozalash
  }

  Widget _buildCryptoCard(BuildContext context, String name, double? price, double? changePercent, {bool isUsdt = false}) {
    Color changeColor = (changePercent ?? 0) >= 0 ? Colors.green : Colors.red;

    // Maxsus ikonlar xaritasi
    Map<String, String> cryptoIcons = {
      'BTC': 'assets/crypto/bitcoin.png',
      'DOGS': 'assets/crypto/dogs.png',
      'TON': 'assets/crypto/ton.png',
      'NOT': 'assets/crypto/not.png',
      'USDT': 'assets/crypto/usdt.png', // USDT uchun ikon qo'shilgan
    };

    // USDT uchun narxni ko'rsatish (p2p'dan olinadigan narxni bevosita chiqarish)
    String displayPrice = isUsdt && usdtPrice != 'N/A' && usdtPrice != 'Error'
        ? '$usdtPrice UZS' // Display P2P USDT price directly
        : price != null ? '${convertToUZS(price, usdtToUzsRate)} UZS' : 'No Price Available';

    return Card(
      color: AppTheme.cardColor, // Use AppTheme's cardColor
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 8,
      child: ListTile(
        leading: cryptoIcons.containsKey(name)
            ? Image.asset(cryptoIcons[name]!, width: 40, height: 40) // Use the custom icon if available
            : CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(name.isNotEmpty ? name[0] : "?", style: TextStyle(color: Colors.white)),
        ),
        title: Text(
          name.isNotEmpty ? name : 'USDT', // Ensuring USDT is displayed
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          displayPrice, // Narxni to'g'ridan-to'g'ri p2p yoki konvertatsiyalangan holda ko'rsatish
          style: TextStyle(color: Colors.greenAccent),
        ),
        trailing: Text(
          changePercent != null ? '${changePercent.toStringAsFixed(2)}%' : 'N/A',
          style: TextStyle(color: changeColor, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CryptoDetailScreen(
                cryptoName: name,
                cryptoPrice: price != null ? price.toString() : '0.0',

              ),
            ),
          );
        },
      ),
    );
  }
}
