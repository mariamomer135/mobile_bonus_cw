import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Mariam Omer
void main() {
  runApp(AquariumApp());
}

class AquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  double speed = 2.0;
  Color selectedColor = Colors.blue;
  List<Color> availableColors = [Colors.blue, Colors.red, Colors.green, Colors.yellow];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: speed, vsync: this));
      });
    }
  }

  void _removeFish() {
    if (fishList.isNotEmpty) {
      setState(() {
        fishList.last.dispose();
        fishList.removeLast();
      });
    }
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speed', speed);
    await prefs.setInt('color', selectedColor.value);
    await prefs.setInt('fishCount', fishList.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Settings Saved!"), duration: Duration(seconds: 2)),
    );
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedColorValue = prefs.getInt('color');
    int savedFishCount = prefs.getInt('fishCount') ?? 0;
    Color loadedColor = savedColorValue != null ? Color(savedColorValue) : Colors.blue;

    if (!availableColors.contains(loadedColor)) {
      loadedColor = Colors.blue;
    }

    setState(() {
      speed = prefs.getDouble('speed') ?? 2.0;
      selectedColor = loadedColor;
      fishList.clear();
      for (int i = 0; i < savedFishCount; i++) {
        fishList.add(Fish(color: selectedColor, speed: speed, vsync: this));
      }
    });
  }

  @override
  void dispose() {
    for (var fish in fishList) {
      fish.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aquarium Simulator")),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text("🐠 Aquarium", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              border: Border.all(color: Colors.black),
            ),
            child: Stack(
              children: fishList.map((fish) => fish.buildFish()).toList(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Speed: "),
              Slider(
                value: speed,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: speed.toString(),
                onChanged: (value) {
                  setState(() {
                    speed = value;
                    for (var fish in fishList) {
                      fish.updateSpeed(speed);
                    }
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Color: "),
              DropdownButton<Color>(
                value: availableColors.contains(selectedColor) ? selectedColor : Colors.blue,
                items: availableColors.map((color) {
                  return DropdownMenuItem(
                    value: color,
                    child: Container(width: 50, height: 20, color: color),
                  );
                }).toList(),
                onChanged: (color) {
                  if (color != null) {
                    setState(() => selectedColor = color);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _addFish,
                child: Text("Add Fish"),
              ),
              ElevatedButton(
                onPressed: _removeFish,
                child: Text("Remove Fish"),
              ),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text("Save Settings"),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class Fish {
  Color color;
  double speed;
  double top;
  double left;
  Random random;
  late AnimationController _controller;
  late Animation<double> _moveX;
  late Animation<double> _moveY;

  Fish({required this.color, required this.speed, required TickerProvider vsync})
      : random = Random(),
        top = Random().nextDouble() * 250,
        left = Random().nextDouble() * 250 {
    _controller = AnimationController(
      duration: Duration(milliseconds: (3000 ~/ speed).toInt()),
      vsync: vsync,
    )..repeat(reverse: true);

    _moveX = Tween<double>(begin: left, end: left + random.nextDouble() * 50 - 25)
        .animate(_controller);
    _moveY = Tween<double>(begin: top, end: top + random.nextDouble() * 50 - 25)
        .animate(_controller);

    _controller.addListener(() {
      top = _moveY.value;
      left = _moveX.value;
    });

    _controller.forward();
  }

  Widget buildFish() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: top,
          left: left,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  void updateSpeed(double newSpeed) {
    speed = newSpeed;
    _controller.duration = Duration(milliseconds: (3000 ~/ speed).toInt());
    _controller.repeat(reverse: true);
  }

  void dispose() {
    _controller.dispose();
  }
}
