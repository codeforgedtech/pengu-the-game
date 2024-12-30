import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:falling_objects_game/falling_object_game.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String hoveredItem = '';
  final AudioPlayer _player = AudioPlayer();
  bool _musicOn = true;
  bool _soundEffectsOn = true;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _showMenu = false;

  @override
 void initState() {
  super.initState();
  _loadSettings();
  
  // Minska duration för att göra animationen snabbare
  _animationController =
      AnimationController(vsync: this, duration: Duration(seconds: 4));  // Snabbare tid

  _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear));
  _scaleAnimation =
      Tween<double>(begin: 0.2, end: 1.0).animate(_animationController);

  _animationController.repeat(); // Start rotation and scaling

  // Vänta tills animationen når sitt största mått
  Future.delayed(Duration(seconds: 4), () {  // Anpassa för snabbare tid
    // Pausa animationen när den har nått sitt största mått
    _animationController.stop();
    
    // Vänta i 1 sekund innan vi slungas vidare till menyn
    Future.delayed(Duration(seconds: 3), () {  // Snabbare fördröjning
      setState(() {
        _showMenu = true;
      });
    });
  });
}

  @override
  void dispose() {
    _player.dispose();
    _animationController.dispose();
    super.dispose();
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
        await _player.stop();
        print('Background music stopped');
      }
    } catch (e) {
      print('Error stopping background music: $e');
    }
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
            SizedBox(width: 10),
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
              'Special Items:',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '  - Bottles give you an extra life.',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Text(
              '  - Catching three balls triggers a rush where cans fall faster.',
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
      body: _showMenu
          ? buildMenu() // Visa menyn efter animationen
          : buildLoadingScreen(), // Visa tidningsanimationen
    );
  }

Widget buildLoadingScreen() {
  return Scaffold(
    body: Center(
      child: Container(
        // Använd en `BoxDecoration` för att sätta bakgrund
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[700]!], // Gradient från ljusblått till mörkblått
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // Om du vill lägga till en skugga på bakgrunden
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
        // Säkerställer att bakgrunden täcker hela skärmen
        width: double.infinity,
        height: double.infinity,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Om animationen är klar (rotationen ska bara vara pågående under animationen)
            if (_animationController.isCompleted) {
              // Stänger av rotation när animationen är klar
              return Transform(
                transform: Matrix4.identity()..scale(_scaleAnimation.value),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/newspaper.png', // Lägg till din tidningsbild här
                  height: MediaQuery.of(context).size.height * 0.8, // Tidningsbilden ska ta 80% av höjden
                  width: MediaQuery.of(context).size.width * 0.8,   // Tidningsbilden ska ta 80% av bredden
                ),
              );
            } else {
              // Under animationen, applicera både rotation och skalning
              return Transform(
                transform: Matrix4.identity()
                  ..scale(_scaleAnimation.value)
                  ..rotateZ(_rotationAnimation.value),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/newspaper.png', // Lägg till din tidningsbild här
                  height: MediaQuery.of(context).size.height * 0.8, // Tidningsbilden ska ta 90% av höjden
                  width: MediaQuery.of(context).size.width * 0.8,   // Tidningsbilden ska ta 90% av bredden
                ),
              );
            }
          },
        ),
      ),
    ),
  );
}



  Widget buildMenu() {
    return Stack(
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
    );
  }
}




