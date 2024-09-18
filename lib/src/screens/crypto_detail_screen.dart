import 'dart:async';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart'; // Import the candlesticks package
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import the intl package
import '../themes/app_theme.dart'; // HomeScreen background uchun import

class CryptoDetailScreen extends StatefulWidget {
  final String cryptoName;
  final String cryptoPrice;

  CryptoDetailScreen({required this.cryptoName, required this.cryptoPrice});

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  List<Candle> candles = [];
  bool isLoading = true;
  Timer? _timer;
  String currentPrice = ''; // Kriptovalyutaning narxi
  String usdtPrice = 'N/A'; // USDT P2P narxi
  TextEditingController _amountController = TextEditingController(); // Miqdor uchun controller
  double totalSum = 0.0; // Hisoblangan summa
  double serviceFee = 0.0; // Xizmat haqi 10%

  @override
  void initState() {
    super.initState();
    fetchUsdtP2PPrice(); // USDT P2P narxini olish
    fetchKlineData();

    // Timer bilan har 1 soniyada yangilash
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchKlineData(realtimeUpdate: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Timerni to'xtatish
    _amountController.dispose(); // Controllerni tozalash
    super.dispose();
  }

  Future<void> fetchUsdtP2PPrice() async {
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
        setState(() {
          usdtPrice = price; // P2P narxini olish va saqlash
        });
      } else {
        setState(() {
          usdtPrice = 'N/A';
        });
      }
    } else {
      setState(() {
        usdtPrice = 'Error';
      });
    }
  }

  Future<void> fetchKlineData({bool realtimeUpdate = false}) async {
    if (!realtimeUpdate) {
      setState(() {
        isLoading = true;
      });
    }

    String symbol = getCorrectSymbol(widget.cryptoName);
    final String klineApiUrl = 'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1h&limit=1000';
    final String priceApiUrl = 'https://api.binance.com/api/v3/ticker/price?symbol=$symbol'; // Fetch real-time price

    try {
      // Fetch Kline data
      final klineResponse = await http.get(Uri.parse(klineApiUrl));
      if (klineResponse.statusCode == 200) {
        List<dynamic> klineData = json.decode(klineResponse.body);
        List<Candle> formattedData = [];

        double usdtRate = double.tryParse(usdtPrice) ?? 1.0; // USDT to UZS conversion rate

        for (var data in klineData) {
          // Convert each price in the candlestick to UZS by multiplying with the USDT rate
          formattedData.add(Candle(
            date: DateTime.fromMillisecondsSinceEpoch(data[0]),
            high: double.parse(data[2]) * usdtRate, // Convert to UZS
            low: double.parse(data[3]) * usdtRate,  // Convert to UZS
            open: double.parse(data[1]) * usdtRate, // Convert to UZS
            close: double.parse(data[4]) * usdtRate, // Convert to UZS
            volume: double.parse(data[5]),
          ));
        }

        // Fetch current price for the selected cryptocurrency
        final priceResponse = await http.get(Uri.parse(priceApiUrl));
        if (priceResponse.statusCode == 200) {
          final priceData = json.decode(priceResponse.body);
          setState(() {
            currentPrice = priceData['price']; // Update the current price
            candles = formattedData.reversed.toList(); // Use the fetched candles
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load price data');
        }
      } else {
        throw Exception('Failed to load Kline data');
      }
    } catch (e) {
      print('Error fetching Kline data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  String getCorrectSymbol(String cryptoName) {
    // Append USDT to the name if it's a known crypto that uses USDT pair
    Map<String, String> symbolMap = {
      'DOGS': 'DOGSUSDT',
      'BTC': 'BTCUSDT',
      'TON': 'TONUSDT',
      'NOT': 'NOTUSDT',
    };

    return cryptoName == 'USDT' ? 'USDTDAI' : symbolMap[cryptoName] ?? cryptoName;
  }

  /// Narxni dollardan so'mga o'girish funksiyasi
  String convertToUZS(double priceInUSD) {
    if (widget.cryptoName == 'USDT') {
      // Use P2P price for USDT
      return '$usdtPrice UZS';
    }

    // For other cryptos, convert using the real-time price and USDT rate
    if (usdtPrice == 'N/A' || usdtPrice == 'Error' || priceInUSD == 0.0) {
      return 'No Price Available'; // Handle case when price or USDT rate is unavailable
    }

    double usdtRate = double.tryParse(usdtPrice) ?? 0.0; // USDT rate
    double priceInUZS = priceInUSD * usdtRate;
    final formatter = NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS', decimalDigits: 2);
    return formatter.format(priceInUZS);
  }

  /// Inputdagi miqdorni formatlash va summani hisoblash
  void calculateTotal() {
    if (usdtPrice == 'N/A' || usdtPrice == 'Error') {
      setState(() {
        totalSum = 0.0;
        serviceFee = 0.0; // Xizmat haqini nolga tenglash
      });
      return;
    }

    // Foydalanuvchi kiritgan miqdorni olish va formatlash
    String inputAmount = _amountController.text.replaceAll(',', '');
    double amount = double.tryParse(inputAmount) ?? 0.0;

    // USDT kursini olish
    double usdtRate = double.tryParse(usdtPrice) ?? 0.0;

    // Kriptovalyuta narxini olish (USD)
    double cryptoPriceInUSD = double.tryParse(currentPrice) ?? 0.0;

    // Kriptovalyuta narxini so'mga o'girish
    double cryptoPriceInUZS = cryptoPriceInUSD * usdtRate;

    // Miqdor va narxni ko'paytirish va natijani chiqarish
    double totalWithoutServiceFee = amount * cryptoPriceInUZS;

    // 10% xizmat haqini hisoblash
    setState(() {
      serviceFee = totalWithoutServiceFee * 0.1; // 10% xizmat haqi
      totalSum = totalWithoutServiceFee * 0.9; // Jami summadan 10% ayiramiz
    });

    print("Jami summa: $totalSum");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.cryptoName} Details'),
        backgroundColor: AppTheme.backgroundColorStart, // Fon rangini o'zgartirish
        elevation: 0, // AppBar soyasini olib tashlash
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Stack(
        children: [
          // HomeScreen'dagi background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.backgroundColorStart,
                  AppTheme.backgroundColorStart,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${widget.cryptoName}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  'Narx: ${convertToUZS(double.tryParse(currentPrice) ?? 0)}',
                  style: TextStyle(fontSize: 20, color: Colors.greenAccent),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Container(
                    child: Candlesticks(
                      candles: candles,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Miqdor kiritish uchun TextField
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    calculateTotal(); // Miqdor o'zgarganda summani hisoblaymiz
                  },
                  decoration: InputDecoration(
                    labelText: 'Sotish uchun miqdor',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 10),
                // Xizmat haqini ko'rsatish
                Text(
                  'Servis ishi (10%): ${NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS').format(serviceFee)}',
                  style: TextStyle(fontSize: 16, color: Colors.orangeAccent),
                ),
                SizedBox(height: 20),
                // Hisoblangan jami summani chiqarish
                Text(
                  'Jami summa: ${NumberFormat.currency(locale: 'uz_UZ', symbol: 'UZS').format(totalSum)}',
                  style: TextStyle(fontSize: 20, color: Colors.greenAccent),
                ),
                SizedBox(height: 20),
                // Sotish button
                ElevatedButton(
                  onPressed: () {
                    // Sotish funksiyasi uchun event yozilishi mumkin
                    print('Sotish bosildi: ${_amountController.text} USDT');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Qizil rangdagi button
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Sotish',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
