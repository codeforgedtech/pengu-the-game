import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicOn = true;
  bool _soundEffectsOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicOn = prefs.getBool('musicOn') ?? true; // Standardvärde: true
      _soundEffectsOn = prefs.getBool('soundEffectsOn') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicOn', _musicOn);
    await prefs.setBool('soundEffectsOn', _soundEffectsOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwitchListTile(
            title: Text('Background Music'),
            value: _musicOn,
            onChanged: (bool value) {
              setState(() {
                _musicOn = value;
                _saveSettings();
              });
            },
          ),
          SwitchListTile(
            title: Text('Sound Effects'),
            value: _soundEffectsOn,
            onChanged: (bool value) {
              setState(() {
                _soundEffectsOn = value;
                _saveSettings();
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Gå tillbaka till förra skärmen
            },
            child: Text('Back'),
          ),
        ],
      ),
    );
  }
}
