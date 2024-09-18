import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uzbek_crypto/src/themes/app_theme.dart';

class TransactionScreen extends StatefulWidget {
  final String walletAddress;

  TransactionScreen({required this.walletAddress});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List events = [];
  bool isLoading = true;
  bool hasError = false;

  static const String apiKey = 'YOUR API KEY';

  @override
  void initState() {
    super.initState();
    getAccountEvents(widget.walletAddress);
  }

  Future<void> getAccountEvents(String walletAddress) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final encodedWalletAddress = Uri.encodeComponent(walletAddress);
      final url = Uri.parse('https://tonapi.io/v2/accounts/$encodedWalletAddress/events?limit=50');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          events = data['events'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        print('Xatolik: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Xatolik sodir bo\'ldi: $e');
    }
  }

  // Vaqtni formatlash
  String _formatDate(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  // Miqdorni formatlash
  String _formatAmount(dynamic amount, int decimals) {
    if (amount == null) {
      return 'Noma\'lum';
    }
    return (double.tryParse(amount.toString())! / pow(10, decimals)).toStringAsFixed(2);
  }

  // Wallet manzilini qisqartirish
  String _shortenWalletAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 4)}...${address.substring(address.length - 4)}';
    } else {
      return address;
    }
  }

  // O'tkazilgan yoki qabul qilinganligini aniqlash
  bool _isSentTransaction(Map<String, dynamic> action) {
    if (action.containsKey('JettonTransfer')) {
      return action['JettonTransfer']['sender']['address'] == widget.walletAddress;
    } else if (action.containsKey('TonTransfer')) {
      return action['TonTransfer']['sender']['address'] == widget.walletAddress;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tranzaktsiyalar Tarixi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundColorStart,
              AppTheme.backgroundColorEnd,
            ],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
          child: Text(
            'Ma\'lumotlarni olishda xatolik yuz berdi.',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        )
            : events.isEmpty
            ? Center(child: Text('Hech qanday event topilmadi.'))
            : ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final timestamp = event['timestamp'] ?? 0;
            final formattedDate = _formatDate(timestamp);
            final actions = event['actions'] ?? [];
            final action = actions.isNotEmpty ? actions[0] : null;

            String jettonName = 'TON';
            String amount = '0';
            String recipient = '';
            bool isSent = false;

            if (action != null) {
              if (action.containsKey('JettonTransfer')) {
                final jettonTransfer = action['JettonTransfer'];
                jettonName = jettonTransfer['jetton']['name'] ?? 'Noma\'lum';
                amount = _formatAmount(jettonTransfer['amount'], jettonTransfer['jetton']['decimals']);
                recipient = jettonTransfer['recipient']['address'] ?? 'Noma\'lum';
                isSent = _isSentTransaction(action);
              } else if (action.containsKey('TonTransfer')) {
                final tonTransfer = action['TonTransfer'];
                amount = _formatAmount(tonTransfer['amount'], 9);
                recipient = tonTransfer['recipient']['address'] ?? 'Noma\'lum';
                isSent = _isSentTransaction(action);
              }
            }

            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: AppTheme.cardColor,
              child: ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSent ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  ),
                  child: Icon(
                    isSent ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isSent ? Colors.blue : Colors.green,
                    size: 30,
                  ),
                ),
                title: Text(
                  isSent ? 'O\'tkazilgan' : 'Qabul qilingan',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSent ? Colors.white : Colors.greenAccent,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Manzil: ${_shortenWalletAddress(recipient)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'O\'tkazma miqdori: $amount $jettonName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSent ? Colors.white70 : Colors.greenAccent,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vaqt: $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

              ),
            );
          },
        ),
      ),
    );
  }
}
