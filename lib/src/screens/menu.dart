import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uzbek_crypto/src/themes/app_theme.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Ekran kichikligini aniqlash

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Sozlamalar',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24, // Kichik ekranda kichikroq matn
            ),
          ).tr(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Ekran chetlari uchun padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSection(
                  title: 'Hisob'.tr(),
                  tiles: [
                    SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Profilni tahrirlash'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                    ),
                    SettingsTile(
                      icon: Icons.security_outlined,
                      title: 'Xavfsizlik'.tr(),
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Bildirishnomalar'.tr(),
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Maxfiylik'.tr(),
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 16), // Moslashuvchan masofa

                SettingsSection(
                  title: 'Tilni tanlang'.tr(),
                  tiles: [
                    SettingsTile(
                      icon: Icons.language,
                      title: 'Til'.tr(),
                      onTap: () {
                        _showLanguageDialog(context);
                      },
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 16), // Kichik ekranda kichikroq bo'sh joy

                SettingsSection(
                  title: 'Yordam va Haqida'.tr(),
                  tiles: [
                    SettingsTile(
                      icon: Icons.subscriptions_outlined,
                      title: 'Mening obunam'.tr(),
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Yordam va Qo\'llab-quvvatlash'.tr(),
                      onTap: () {},
                    ),
                    SettingsTile(
                      icon: Icons.info_outline,
                      title: 'Shartlar va Siyosatlar'.tr(),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;

        return AlertDialog(
          backgroundColor: Color(0xFF2C2C2E),
          title: Text(
            'Tilni tanlang'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20, // Ekranga mos matn hajmi
            ),
          ),
          content: Container(
            color: Color(0xFF2C2C2E),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                    'assets/icons/uz.png', 'O\'zbekcha', context, Locale('uz')),
                _buildLanguageOption(
                    'assets/icons/us.png', 'English', context, Locale('en')),
                _buildLanguageOption(
                    'assets/icons/ru.png', 'Русский', context, Locale('ru')),
                _buildLanguageOption(
                    'assets/icons/tr.png', 'Türkçe', context, Locale('tr')),
                _buildLanguageOption(
                    'assets/icons/ar.png', 'العربية', context, Locale('ar')),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String flagAsset, String languageName,
      BuildContext context, Locale locale) {
    return ListTile(
      leading: Image.asset(
        flagAsset,
        width: 30,
      ),
      title: Text(
        languageName.tr(),
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        context.setLocale(locale);
        Navigator.of(context).pop();
      },
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsTile> tiles;

  SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor.withOpacity(0.8),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Column(
              children: tiles,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.white),
      onTap: onTap,
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
          colors: [
            Colors.black,
            Colors.blue,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
