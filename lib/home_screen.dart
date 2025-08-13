// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'settings_screen.dart'; // Importamos la pantalla de ajustes

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAlarmActive = false;
  List<Map<String, String>> _medicationLog = [];
  List<String> _medicationTimes = [];
  final player = AudioPlayer();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadMedicationTimes();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    player.dispose();
    super.dispose();
  }

  // Carga los horarios guardados de SharedPreferences
  void _loadMedicationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _medicationTimes = prefs.getStringList('medicationTimes') ?? [];
    });
  }

  // Guarda los horarios en SharedPreferences
  void _saveMedicationTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('medicationTimes', _medicationTimes);
  }

  // Inicia un temporizador para chequear si es hora de la medicación
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (_medicationTimes.contains(currentTime)) {
        if (!_isAlarmActive) {
          _activateAlarm();
        }
      }
    });
  }

  void _activateAlarm() async {
    setState(() {
      _isAlarmActive = true;
    });

    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/alarm.mp3'));
    _showCustomAlert(context, '¡ES HORA! Toma tu medicación.', isAlarm: true);
    print('Alarma activada. Reproduciendo sonido...');
  }

  void _onMedicationTaken() async {
    setState(() {
      _isAlarmActive = false;
      final now = DateTime.now();
      _medicationLog.add({
        'date': now.toIso8601String().substring(0, 10),
        'time': now.toIso8601String().substring(11, 19),
      });
    });

    player.stop();
    print('Medicamento registrado en el log. Deteniendo sonido...');

    final message = "Hola, la persona mayor acaba de tomar su medicación. Registro: ${DateTime.now().toString()}";
    final whatsappUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      _showCustomAlert(context, 'Error al abrir WhatsApp. Por favor, revisa la configuración.');
    }

    _showCustomAlert(context, '¡Medicamento registrado! Se ha enviado una notificación al familiar.');
  }

  void _showCustomAlert(BuildContext context, String message, {bool isAlarm = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isAlarm ? Colors.red[800] : Colors.grey[850],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isAlarm ? '¡ES HORA!' : 'Alerta',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlarm ? Colors.green : Colors.indigoAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  isAlarm ? 'TOMADA ✅' : 'OK',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (isAlarm) {
                    _onMedicationTaken();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          medicationTimes: _medicationTimes,
          onTimesUpdated: (newTimes) {
            setState(() {
              _medicationTimes = newTimes;
            });
            _saveMedicationTimes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Pastillero Inteligente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isAlarmActive
                      ? MedicationAlarmView(onMedicationTaken: _onMedicationTaken)
                      : HomeView(medicationTimes: _medicationTimes),
                ),
              ),
              const SizedBox(height: 24),
              MedicationLogView(medicationLog: _medicationLog),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  final List<String> medicationTimes;

  const HomeView({Key? key, required this.medicationTimes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Todo en orden',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          medicationTimes.isEmpty
              ? 'No hay horarios configurados.'
              : 'Próximas tomas:\n${medicationTimes.join(', ')}',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Text(
          'Configura los horarios en el botón de ajustes.',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class MedicationAlarmView extends StatelessWidget {
  final VoidCallback onMedicationTaken;

  const MedicationAlarmView({Key? key, required this.onMedicationTaken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¡ES HORA!',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Toma tu medicación de la tarde.',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Image.network(
                'https://placehold.co/300x150/ffffff/000000?text=IMAGEN+DE+PASTILLAS',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.medication,
                  size: 150,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Medicación de la tarde (2 pastillas blancas)',
                style: TextStyle(fontSize: 20, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onMedicationTaken,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            textStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            elevation: 10,
          ),
          child: const Text('TOMADA ✅'),
        ),
      ],
    );
  }
}

class MedicationLogView extends StatelessWidget {
  final List<Map<String, String>> medicationLog;

  const MedicationLogView({Key? key, required this.medicationLog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Registro de tomas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          medicationLog.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'No hay tomas registradas aún.',
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: medicationLog.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = medicationLog.length - 1 - index;
                    final entry = medicationLog[reversedIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry['date']!,
                            style: const TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                          Text(
                            entry['time']!,
                            style: const TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}