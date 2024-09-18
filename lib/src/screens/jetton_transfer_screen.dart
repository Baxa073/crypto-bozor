import 'dart:convert'; // for hex decoding
import 'dart:typed_data'; // Uint8List
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tonutils/tonutils.dart';

import '../models/jetton_model.dart'; // tonutils kutubxonasi

class JettonTransferPage extends StatefulWidget {
  final String fromWalletAddress; // Foydalanuvchining wallet manzili
  final List<Jetton> jettons; // Foydalanuvchining Jettonlari

  JettonTransferPage({required this.fromWalletAddress, required this.jettons});

  @override
  _JettonTransferPageState createState() => _JettonTransferPageState();
}

class _JettonTransferPageState extends State<JettonTransferPage> {
  final TextEditingController _toWalletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedJetton = ''; // Foydalanuvchi tanlagan jetton
  bool _isLoading = false;
  Uint8List? publicKeyBytes;
  Uint8List? privateKeyBytes;

  @override
  void initState() {
    super.initState();
    if (widget.jettons.isNotEmpty) {
      _selectedJetton = widget.jettons[0].name;
    }
    _generateKeys(); // Mnemonic orqali kalitlarni generatsiya qilish
  }

  Future<void> _generateKeys() async {
    try {
      // Mnemonic orqali kalitlarni generatsiya qilish
      var mnemonic = Mnemonic.generate(); // Har doim mavjud bo'ladi
      var keyPair = Mnemonic.toKeyPair(mnemonic);

      setState(() {
        publicKeyBytes = keyPair.publicKey;
        privateKeyBytes = keyPair.privateKey;
      });

      print('Public Key: ${keyPair.publicKey}');
      print('Private Key: ${keyPair.privateKey}');
    } catch (e) {
      print('Kalitlarni yaratishda xatolik: $e');
    }
  }

  Future<void> _sendJettons() async {
    final toWallet = _toWalletController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (toWallet.isEmpty || amount == null || _selectedJetton.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ma\'lumotlarni to\'ldiring')),
      );
      return;
    }

    if (privateKeyBytes == null || publicKeyBytes == null) {
      print('Public yoki private kalitlar mavjud emas');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TON tarmog'ida tranzaktsiyani amalga oshirish
      final client = TonJsonRpc('https://toncenter.com/api/v2/jsonRPC');

      var wallet = WalletContractV4R2.create(publicKey: publicKeyBytes!); // Wallet yaratish
      var openedContract = client.open(wallet);

      var seqno = await openedContract.getSeqno();

      // Transfer yaratish uchun Jettonni yaratamiz
      var transfer = createWalletTransferV4(
        seqno: seqno,
        sendMode: 3, // Odatda 3 qiymati (barcha qoldiq mablag'ni qaytarish)
        walletId: 0, // Wallet ID odatda 0 bo'ladi
        messages: [
          internal(
            to: SiaString(toWallet), // Qabul qiluvchi wallet manzili
            value: SbiString(amount.toString()), // Jetton miqdori
            body: ScString('Jetton Transfer'), // Tranzaktsiya izohi
          ),
        ],
        privateKey: privateKeyBytes!,
      );

      // Transferni yuborish
      await openedContract.send(transfer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O\'tkazma muvaffaqiyatli amalga oshirildi!')),
      );
    } catch (e) {
      print('Xatolik: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O\'tkazmada xatolik yuz berdi.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jetton O\'tkazish', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jetton tanlang:', style: GoogleFonts.poppins(fontSize: 16)),
            DropdownButton<String>(
              value: _selectedJetton,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedJetton = newValue!;
                });
              },
              items: widget.jettons.map<DropdownMenuItem<String>>((Jetton jetton) {
                return DropdownMenuItem<String>(
                  value: jetton.name,
                  child: Text(jetton.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _toWalletController,
              decoration: InputDecoration(
                labelText: 'Oluvchi Wallet Manzili',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jetton Miqdori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _sendJettons,
              child: Text('Yuborish', style: GoogleFonts.poppins(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
