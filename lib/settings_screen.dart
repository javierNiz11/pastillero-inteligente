// lib/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final List<String> medicationTimes;
  final Function(List<String>) onTimesUpdated;

  const SettingsScreen({Key? key, required this.medicationTimes, required this.onTimesUpdated}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _currentTimes;

  @override
  void initState() {
    super.initState();
    _currentTimes = List.from(widget.medicationTimes);
    _currentTimes.sort();
  }

  void _addTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (newTime != null) {
      final timeString = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
      if (!_currentTimes.contains(timeString)) {
        setState(() {
          _currentTimes.add(timeString);
          _currentTimes.sort();
        });
        widget.onTimesUpdated(_currentTimes);
      }
    }
  }

  void _removeTime(String time) {
    setState(() {
      _currentTimes.remove(time);
    });
    widget.onTimesUpdated(_currentTimes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Configurar Horarios'),
        backgroundColor: Colors.grey[850],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _addTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add_alarm),
              label: const Text('Añadir Horario'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _currentTimes.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay horarios configurados.',
                        style: TextStyle(fontSize: 20, color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _currentTimes.length,
                      itemBuilder: (context, index) {
                        final time = _currentTimes[index];
                        return Card(
                          color: Colors.grey[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              time,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 30),
                              onPressed: () => _removeTime(time),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}