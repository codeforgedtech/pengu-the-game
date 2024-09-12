import 'package:falling_objects_game/splash_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; // Importera audioplayers

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengu the Game',
      home: SplashScreen(),
    );
  }
}

class FallingObjectsGame extends StatefulWidget {
  final String difficulty;
  final bool musicOn;
  final bool soundEffectsOn;
  FallingObjectsGame({
    required this.difficulty,
    required this.musicOn,
    required this.soundEffectsOn,
  });

  @override
  _FallingObjectsGameState createState() => _FallingObjectsGameState();
}

class _FallingObjectsGameState extends State<FallingObjectsGame> {
  double playerX = 0;
  List<FallingObject> fallingObjects = [];
  int score = 0;
  int lives = 3;
  bool gameOver = false;
  bool isPaused = false;
  String playerDirection = 'right';
  Timer? _gameTimer;
  Timer? _moveTimer; // Ny timer för rörelse
  double _playerSpeed = 0.01; // Normal hastighet
  double _speedIncrease = 0.005;

  double _minObjectFallSpeed = 0.002;
  double _maxObjectFallSpeed = 0.005;
  int _maxObjects = 2;
  int broccoliPenalty = 10;

  // Ljudspelare
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _setDifficulty(widget.difficulty);
    if (widget.musicOn) {
      _playBackgroundMusic();
    }

    startGame();
  }

  void _setDifficulty(String difficulty) {
    if (difficulty == 'easy') {
      _minObjectFallSpeed = 0.002;
      _maxObjectFallSpeed = 0.004;
      _maxObjects = 2;
      broccoliPenalty = 5;
    } else if (difficulty == 'medium') {
      _minObjectFallSpeed = 0.004;
      _maxObjectFallSpeed = 0.007;
      _maxObjects = 3;
      broccoliPenalty = 10;
    } else if (difficulty == 'hard') {
      _minObjectFallSpeed = 0.006;
      _maxObjectFallSpeed = 0.010;
      _maxObjects = 4;
      broccoliPenalty = 15;
    }
  }

  void startGame() {
    _spawnInitialObjects();
    _gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (gameOver || isPaused) {
        return;
      }

      setState(() {
        _handleFallingObjects();
        _checkCollisions();
        _spawnNewObjects();
      });
    });
  }

  void _playBackgroundMusic() async {
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _backgroundPlayer.play(AssetSource('backgrund.mp3'));
  }

  void _pauseGame() {
    setState(() {
      isPaused = true;
    });
  }

  void _resumeGame() {
    setState(() {
      isPaused = false;
    });
  }

  void _spawnInitialObjects() {
    for (int i = 0; i < 1; i++) {
      double x = Random().nextDouble() * 2 - 1;
      double y = -1;

      String type = Random().nextBool() ? 'cola' : 'broccoli';

      fallingObjects.add(FallingObject(
        x: x,
        y: y,
        type: type,
        rotation: 0,
        fallSpeed: Random().nextDouble() *
                (_maxObjectFallSpeed - _minObjectFallSpeed) +
            _minObjectFallSpeed,
      ));
    }
  }

  void _handleFallingObjects() {
    for (var object in fallingObjects) {
      object.y += object.fallSpeed;
      object.rotation += 0.05;
    }

    fallingObjects.removeWhere((object) {
      if (object.y > 1.1) {
        if (object.type == 'cola') {
          lives--;
          if (lives == 0) {
            setState(() {
              gameOver = true;
            });
            _showGameOverOverlay();
          }
        }
        return true;
      }
      return false;
    });
  }

  void _playSound(String type) async {
    if (widget.soundEffectsOn) {
      // Kontrollera om ljudet för effekter är på
      print('Playing sound for type: $type'); // Debugging-utskrift
      if (type == 'cola') {
        await _audioPlayer.play(AssetSource('coin.mp3'));
      } else if (type == 'broccoli') {
        await _audioPlayer.play(AssetSource('hurt.mp3'));
      }
    } else {
      print('Sound effects are off'); // Debugging-utskrift
    }
  }

  void _checkCollisions() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double playerWidth = 93 / screenWidth;
    double playerHeight = 115 / screenHeight;

    double objectWidth = 100 / screenWidth;
    double objectHeight = 100 / screenHeight;

    for (var object in fallingObjects) {
      double playerLeft = (playerX - playerWidth / 2) * screenWidth;
      double playerRight = (playerX + playerWidth / 2) * screenWidth;
      double playerTop = (0.8 - playerHeight / 2) * screenHeight;
      double playerBottom = (0.8 + playerHeight / 2) * screenHeight;

      double objectLeft = (object.x - objectWidth / 2) * screenWidth;
      double objectRight = (object.x + objectWidth / 2) * screenWidth;
      double objectTop = (object.y - objectHeight / 2) * screenHeight;
      double objectBottom = (object.y + objectHeight / 2) * screenHeight;

      bool collisionX = playerRight > objectLeft && playerLeft < objectRight;
      bool collisionY = playerBottom > objectTop && playerTop < objectBottom;

      if (collisionX && collisionY) {
        if (object.type == 'cola') {
          score += 10;
        } else if (object.type == 'broccoli') {
          score -= broccoliPenalty;
        }

        _playSound(object.type);
        fallingObjects.remove(object);
        break;
      }
    }
  }
void _movePlayer(double direction) {
  setState(() {
    double playerHalfWidth = (93 / MediaQuery.of(context).size.width) / 2;

    playerX += direction;

    // Se till att hela Pengu kan nå kanten
    if (playerX < -1) {
      playerX = -1; // Stoppa vänster rörelse vid skärmens vänstra kant
    } else if (playerX > 1) {
      playerX = 1; // Stoppa höger rörelse vid skärmens högra kant
    }
  });
}
 void _startMoving(double direction) {
    _movePlayer(direction);  // Gör en initial rörelse omedelbart
    _moveTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _movePlayer(direction);
    });
  }

  // Stoppa rörelsen när knappen släpps
  void _stopMoving() {
    if (_moveTimer != null) {
      _moveTimer!.cancel();
      _moveTimer = null;
    }
  }
  void _spawnNewObjects() {
    if (fallingObjects.length < _maxObjects) {
      for (int i = fallingObjects.length; i < _maxObjects; i++) {
        double x = Random().nextDouble() * 2 - 1;
        double y = -1;

        String type = Random().nextBool() ? 'cola' : 'broccoli';

        double baseSpeed = Random().nextDouble() * 0.002 + 0.002;
        double fallSpeed = baseSpeed + Random().nextDouble() * 0.002;

        fallingObjects.add(FallingObject(
          x: x,
          y: y,
          type: type,
          rotation: 0,
          fallSpeed: fallSpeed,
        ));
      }
    }
  }

  void _showGameOverOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game Over',
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Your Score: $score',
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 24,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: TextStyle(
                        fontFamily: 'PatrickHand',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('Exit'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: TextStyle(
                        fontFamily: 'PatrickHand',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => SplashScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('Restart'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[200]!, Colors.blue[700]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/floor.png',
              fit: BoxFit.cover,
              height: 100,
            ),
          ),
          ...fallingObjects.map((object) {
            return Align(
              alignment: Alignment(object.x, object.y),
              child: Transform.rotate(
                angle: object.rotation,
                child: Image.asset(
                  object.type == 'cola'
                      ? 'assets/cola.png'
                      : 'assets/brocoli.png',
                  height: 50,
                  width: 30,
                ),
              ),
            );
          }).toList(),
          Align(
            alignment: Alignment(playerX, 0.8),
            child: Image.asset(
              playerDirection == 'left'
                  ? 'assets/left.png'
                  : 'assets/right.png',
              height: 115,
              width: 93,
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              'Score: $score',
              style: TextStyle(
                fontFamily: 'PatrickHand',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    offset: Offset(2, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: List.generate(
                lives,
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset(
                    'assets/cola.png',
                    height: 40,
                    width: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
     floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Stack(
        children: [
          // Vänster knapp
          Positioned(
            bottom: 40,
            left: 20,
            child: GestureDetector(
              onTapDown: (_) {
                _startMoving(-_playerSpeed - _speedIncrease); // Flytta vänster
                playerDirection = 'left';
              },
              onTapUp: (_) {
                _stopMoving(); // Stoppa rörelsen
              },
              onTapCancel: () {
                _stopMoving(); // Stoppa rörelsen om användaren drar fingret från knappen
              },
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: null, // Tom eftersom vi använder GestureDetector
                child: Icon(
                  Icons.arrow_left,
                  size: 50,
                ),
              ),
            ),
          ),
          // Höger knapp
          Positioned(
            bottom: 40,
            right: 20,
            child: GestureDetector(
              onTapDown: (_) {
                _startMoving(_playerSpeed + _speedIncrease); // Flytta höger
                playerDirection = 'right';
              },
              onTapUp: (_) {
                _stopMoving(); // Stoppa rörelsen
              },
              onTapCancel: () {
                _stopMoving(); // Stoppa rörelsen om användaren drar fingret från knappen
              },
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: null, // Tom eftersom vi använder GestureDetector
                child: Icon(
                  Icons.arrow_right,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();  // Avsluta flytt-timer när spelet avslutas
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    super.dispose();
  }
}

class FallingObject {
  double x;
  double y;
  final String type;
  double rotation;
  final double fallSpeed;

  FallingObject({
    required this.x,
    required this.y,
    required this.type,
    required this.rotation,
    required this.fallSpeed,
  });
}
