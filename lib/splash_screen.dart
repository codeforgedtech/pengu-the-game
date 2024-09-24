import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:falling_objects_game/falling_object_game.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String hoveredItem = '';
  final AudioPlayer _player = AudioPlayer();
  bool _musicOn = true;
  bool _soundEffectsOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Ladda inställningar från SharedPreferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicOn = prefs.getBool('musicOn') ?? true;
      _soundEffectsOn = prefs.getBool('soundEffectsOn') ?? true;
    });
    print(
        'Loaded Settings - Music On: $_musicOn, Sound Effects On: $_soundEffectsOn');
    if (_musicOn) {
      _playBackgroundMusic();
    } else {
      _stopBackgroundMusic();
    }
  }

  // Spela bakgrundsmusik
  Future<void> _playBackgroundMusic() async {
    try {
      if (_musicOn) {
        // Check if music is supposed to be on
        _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('backgrund.mp3'));
        print('Background music started');
      }
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  Future<void> _stopBackgroundMusic() async {
    try {
      if (!_musicOn) {
        // Check if music is supposed to be off
        await _player.stop();
        print('Background music stopped');
      }
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // Visa inställningar som en popup
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSwitchRow(
                    title: 'Background Music',
                    value: _musicOn,
                    onChanged: (bool value) {
                      setState(() {
                        _musicOn = value;
                        _saveSettings();
                        if (_musicOn) {
                          _playBackgroundMusic();
                        } else {
                          _stopBackgroundMusic();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  _buildSwitchRow(
                    title: 'Sound Effects',
                    value: _soundEffectsOn,
                    onChanged: (bool value) {
                      setState(() {
                        _soundEffectsOn = value;
                        _saveSettings();
                      });
                    },
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              backgroundColor: Colors.white,
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'PatrickHand',
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            Text(
              value ? 'ON' : 'OFF',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 20,
                color: value ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 10), // Litet avstånd mellan text och switch
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicOn', _musicOn);
    await prefs.setBool('soundEffectsOn', _soundEffectsOn);
  }

  Widget buildHoverText(String text, Color color, VoidCallback onTap) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          hoveredItem = text;
        });
      },
      onExit: (event) {
        setState(() {
          hoveredItem = '';
        });
      },
      child: GestureDetector(
        onTap: () async {
          if (_soundEffectsOn) {
            try {
              await _player.play(AssetSource('click.mp3'));
            } catch (e) {
              print('Error playing sound: $e');
            }
          }
          onTap();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0,
            hoveredItem == text ? -10 : 0,
            0,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'PatrickHand',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: hoveredItem == text
                  ? [Shadow(blurRadius: 10, color: Colors.black)]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  // Visa instruktionsdialog
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Play',
          style: TextStyle(
            fontFamily: 'PatrickHand',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                'Welcome to Pengu the Game!',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Objective: Catch the falling cola cans and avoid the broccoli.',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Controls:',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '  - Use the left and right arrow buttons to move Pengu.',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                '  - Catch cola cans to earn points.',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                '  - Avoid broccoli to prevent losing points.',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Have fun and good luck!',
                style: TextStyle(
                  fontFamily: 'PatrickHand',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          TextButton(
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Navigera till spelskärmen
  void navigateToGame(String difficulty) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => FallingObjectsGame(
          difficulty: difficulty,
          musicOn: _musicOn,
          soundEffectsOn: _soundEffectsOn,
        ),
        transitionsBuilder: (context, animation1, animation2, child) {
          return FadeTransition(opacity: animation1, child: child);
        },
        transitionDuration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[200]!, Colors.blue[700]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 258,
                  width: 350,
                ),
                SizedBox(height: 40),
                buildHoverText(
                  'Easy',
                  Colors.black,
                  () {
                    navigateToGame('easy');
                  },
                ),
                SizedBox(height: 20),
                buildHoverText(
                  'Medium',
                  Colors.black,
                  () {
                    navigateToGame('medium');
                  },
                ),
                SizedBox(height: 20),
                buildHoverText(
                  'Hard',
                  Colors.black,
                  () {
                    navigateToGame('hard');
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _showInstructions,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text('How to Play'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showSettings,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text('Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
