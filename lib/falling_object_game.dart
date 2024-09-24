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
  List<bool> collectedBalls = [];
  int score = 0;
  int lives = 3;
  int ballCount = 0;
  bool gameOver = false;
  bool isPaused = false;
  int _bonusTimeLeft = 0;
  int bonusCollected = 0;
int bonusScore = 0;
  bool inBonusLevel = false;  // Håller reda på om bonusnivån är aktiv
Timer? _bonusTimer;  // Timer för bonusnivån
  String playerDirection = 'right';
  Timer? _gameTimer;
  Timer? _moveTimer; // Ny timer för rörelse
  double _playerSpeed = 0.005; // Normal hastighet
  double _speedIncrease = 0.02;

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
void _collectBall() {
  if (ballCount < 3) { // Maximalt 3 bollar
    collectedBalls.add(true);
    ballCount++;
    setState(() {});
  }
}


String currentDifficulty = 'easy';
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
void _startBonusLevel() {
  setState(() {
    inBonusLevel = true; // Aktivera bonusnivå
    fallingObjects.clear(); // Rensa alla objekt
  _startBonusTimer();
  });

  // Återställ antalet bollar och andra bonusinställningar
  ballCount = 0;
  _minObjectFallSpeed = 0.008;  
  _maxObjectFallSpeed = 0.020;
  _maxObjects = 8;
}
  void _startBonusTimer() {
  _bonusTimeLeft = 20; // Sätt bonusnedräkning till 20 sekunder

  // Om en gammal timer finns, avbryt den
  _bonusTimer?.cancel();

  // Starta den nya timern
  _bonusTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      _bonusTimeLeft--; // Minska tiden med 1 sekund per gång

      if (_bonusTimeLeft <= 0) {
        _bonusTimer?.cancel(); // Stoppa timern när tiden är slut
        inBonusLevel = false;
        _endBonusLevel(); // Visa resultatmodal för bonusnivån
      }
    });
  });
}
void _endBonusLevel() {
  setState(() {
    print('Before clear: ${fallingObjects.length}'); // Debugging
    fallingObjects.clear();  // Rensa alla fallande objekt
    print('After clear: ${fallingObjects.length}'); // Debugging
    
    // Återställ svårighetsgrad
    if (currentDifficulty == 'hard') {
      currentDifficulty = 'medium'; // Sänk svårighetsgraden
    } else {
      currentDifficulty = 'easy'; // Sätt till easy
    }
    
    // Ställ in svårighetsgrad baserat på currentDifficulty
    _setDifficulty(currentDifficulty);

    _spawnInitialObjects();  // Spawn nya objekt baserat på den aktuella svårighetsgraden
    
  });
}
  void _spawnInitialObjects() {
  int objectCount = (currentDifficulty == 'easy') ? 1 : 3; // Fler objekt på medium

  for (int i = 0; i < objectCount; i++) {
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
  if (isPaused) return; // Om spelet är pausat, gör inget

  List<FallingObject> objectsToRemove = [];

  for (var object in fallingObjects) {
    object.y += object.fallSpeed; 
    object.rotation += 0.05; 

    // Kontrollera om objektet har nått botten av skärmen
    if (object.y > 1.1) {
      if (object.type == 'cola') {
        // Om det är bonusnivå, uppdatera poäng och ta bort objekt
        if (inBonusLevel) {
          setState(() {
            score += 1;  // Uppdatera poängen för colaburk
          });
        } else {
          // Hantera livsförlust om det inte är bonusnivå
          setState(() {
            lives--;
            if (lives == 0) {
              gameOver = true;
              _showGameOverOverlay();
            }
          });
        }
      }
      objectsToRemove.add(object); // Markera objekt för borttagning
    }
  }

  // Ta bort alla objekt utanför loopen för att undvika att låsa spelet
  fallingObjects.removeWhere((object) => objectsToRemove.contains(object));
}

  void _playSound(String type) async {
    if (widget.soundEffectsOn) {
      // Kontrollera om ljudet för effekter är på
      print('Playing sound for type: $type'); // Debugging-utskrift
      if (type == 'cola') {
        await _audioPlayer.play(AssetSource('coin.mp3'));
      } else if (type == 'broccoli') {
         await _audioPlayer.play(AssetSource('hurt.mp3'));
   } else if (type == 'ball') {
      // Lägg till ljud för bollen
      await _audioPlayer.play(AssetSource('ball.mp3'));
    }
  } else {
    print('Sound effects are off'); // Debugging-utskrift
  }
}


void _checkCollisions() {
  if (isPaused) return;  // Gör inget om spelet är pausat

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
        if (!inBonusLevel) {
          score -= broccoliPenalty;
        }
      } else if (object.type == 'ball') { // Handle the ball case
        ballCount++;
        if (ballCount >= 3) {
          _startBonusLevel(); // Start bonus level after collecting 3 balls
        }
      }

      _playSound(object.type);
      fallingObjects.remove(object);
      break;
    }
  }
}

  
  void _movePlayer(double direction) {
    setState(() {
      double playerWidth = 93 / MediaQuery.of(context).size.width;
      double playerHalfWidth = playerWidth / 2;

      // Uppdatera spelarens position baserat på riktningen
      playerX += direction;

      // Säkerställ att spelaren inte kan gå utanför skärmens vänstra eller högra kant
      if (playerX < -1 + playerHalfWidth) {
        playerX = -1 + playerHalfWidth; // Justera så att Pengu når precis kanten men inte längre
      } else if (playerX > 1 - playerHalfWidth) {
        playerX = 1 - playerHalfWidth; // Justera så att Pengu når precis kanten men inte längre
      }
    });
  }
Timer? _movementTimer;

void _startMoving(double speed) {
  _movementTimer?.cancel(); // Avbryt tidigare timer
  _movementTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
    // Uppdatera spelarens position baserat på hastighet
    double newPlayerX = playerX + speed;

    // Kontrollera gränser
    if (newPlayerX < leftBoundary) {
      playerX = leftBoundary; // Sätt till vänster gräns
    } else if (newPlayerX > rightBoundary) {
      playerX = rightBoundary; // Sätt till höger gräns
    } else {
      playerX = newPlayerX; // Flytta spelaren
    }

    setState(() {}); // Uppdatera UI
  });
}

void _stopMoving() {
  _movementTimer?.cancel(); // Avbryt rörelsen när knappen släpps
}
void _spawnNewObjects() {
  double screenWidth = MediaQuery.of(context).size.width;
  double playerHalfWidth = (93 / screenWidth) / 2;

  if (fallingObjects.length < _maxObjects) {
    for (int i = fallingObjects.length; i < _maxObjects; i++) {
      double x = (Random().nextDouble() * (2 - 2 * playerHalfWidth)) - (1 - playerHalfWidth);
      double y = -1;

      String type;

      // Om vi är i bonusnivå, skapa endast cola-burkar
      if (inBonusLevel) {
        type = 'cola'; // Endast cola-burkar i bonusnivå
      } else {
        // Annars, skapa cola-burkar och broccoli, med en liten chans för bollar
        double chance = Random().nextDouble();
        if (chance < 0.05) {
          type = 'ball'; // 5% chans för bollar
        } else {
          type = Random().nextBool() ? 'cola' : 'broccoli'; // 50% chans för cola eller broccoli
        }
      }

      fallingObjects.add(FallingObject(
        x: x,
        y: y,
        type: type,
        rotation: 0,
        fallSpeed: Random().nextDouble() * (_maxObjectFallSpeed - _minObjectFallSpeed) + _minObjectFallSpeed,
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
final double leftBoundary = -1.0; // Vänster gräns
final double rightBoundary = 1.0; // Höger gräns

Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: <Widget>[
        // Bakgrundsfärg och gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[200]!, Colors.blue[700]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Spelets område
        Positioned(
          top: 0,
          bottom: 100, // Avstånd från botten
          left: 0,
          right: 0,
          child: Container(
            color: Colors.lightGreenAccent.withOpacity(0.2), // Spelets bakgrund
          ),
        ),
        // Golvet längst ner på skärmen
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
        // Fallande objekt
        ...fallingObjects.map((object) {
          return Align(
            alignment: Alignment(object.x, object.y),
            child: Transform.rotate(
              angle: object.rotation,
              child: Image.asset(
                object.type == 'cola'
                    ? 'assets/cola.png'
                    : object.type == 'broccoli'
                        ? 'assets/brocoli.png'
                        : 'assets/boll.png', // Lägg till stöd för bollar här
                height: 50,
                width: 30,
              ),
            ),
          );
        }).toList(),
        // Spelarkaraktären
        Align(
          alignment: Alignment(playerX, 0.9),
          child: Image.asset(
            playerDirection == 'left'
                ? 'assets/left.png'
                : 'assets/right.png',
            height: 115,
            width: 93,
          ),
        ),
        // Poängtext
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
        // Liv-indikator
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
        Positioned(
          top: 100,
          right: 25,
          child: Row(
            children: List.generate(
              ballCount, // Variabel som håller koll på antal bollar
              (index) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Image.asset(
                  'assets/boll.png', // Din bollbild
                  height: 25,
                  width: 25,
                ),
              ),
            ),
          ),
        ),
        // Visa BONUS-text och nedräkning om bonusnivån är aktiv
        if (inBonusLevel)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'BONUS!',
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(2, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_bonusTimeLeft',  // Visar återstående tid
                    style: TextStyle(
                      fontFamily: 'PatrickHand',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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

// Justera spelarens position


  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();  // Avsluta flytt-timer när spelet avslutas
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    _bonusTimer?.cancel();
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

