import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/reminders_service.dart';
import '../../core/theme_provider.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reminders = await ref.read(remindersServiceProvider).getMyReminders();
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addReminder() async {
    final medCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final durationCtrl = TextEditingController(); // Days
    
    // Store selected times. Key: index, Value: TimeOfDay
    final Map<int, TimeOfDay> timeSlots = {};
    
    int frequency = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInnerState) {
          
          void updateFrequency(String val) {
            final n = int.tryParse(val);
            if (n != null && n > 0 && n <= 10) { // Limit to 10 for sanity
               setInnerState(() {
                 frequency = n;
                 // Initialize missing slots with default or clear excess
               });
            } else {
              setInnerState(() => frequency = 0);
            }
          }

          return AlertDialog(
            title: Text('Add Medicine Reminder', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: medCtrl,
                      decoration: const InputDecoration(labelText: 'Medicine Name', hintText: 'e.g. Paracetamol'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: freqCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Times per Day', hintText: 'e.g. 3'),
                            onChanged: updateFrequency,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Duration (Days)', hintText: 'e.g. 5'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (frequency > 0) ...[
                      Text('Set Times:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...List.generate(frequency, (index) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dose ${index + 1}'),
                          trailing: TextButton.icon(
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text(timeSlots[index] == null 
                                ? 'Select Time' 
                                : timeSlots[index]!.format(context)),
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (t != null) {
                                setInnerState(() => timeSlots[index] = t);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (medCtrl.text.isNotEmpty && 
                      frequency > 0 && 
                      durationCtrl.text.isNotEmpty &&
                      timeSlots.length == frequency) {
                        
                    final duration = int.tryParse(durationCtrl.text) ?? 1;
                    
                    final slots = timeSlots.values.map((t) => 
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
                    ).toList();

                    Navigator.pop(context);
                    setState(() => _loading = true);
                    try {
                      await ref.read(remindersServiceProvider).createReminder(
                        medicineName: medCtrl.text, 
                        frequency: frequency, 
                        timeSlots: slots, 
                        duration: duration
                      );
                      await _load();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      // Re-load to stop loading state
                      _load();
                    }
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and set all times.')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _delete(String id) async {
    setState(() => _loading = true);
    await ref.read(remindersServiceProvider).deleteReminder(id);
    await _load();
  }

  Future<void> _toggle(String id, bool val) async {
    // Optimistic updat
    final idx = _reminders.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      setState(() {
        _reminders[idx]['isEnabled'] = val;
      });
    }
    try {
      await ref.read(remindersServiceProvider).updateReminder(id, val);
    } catch (_) {
      _load(); // Revert on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Reminders', style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        label: const Text('Add Reminder'),
        icon: const Icon(Icons.add_alarm_rounded),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No reminders set', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final item = _reminders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medication_rounded, color: Color(0xFF6366F1)),
                        ),
                        title: Text(
                          item['medicineName'],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor),
                        ),
                        subtitle: Text(
                          '${item['frequency']}x daily • ${(item['timeSlots'] as List).join(', ')}',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: item['isEnabled'] ?? true,
                              onChanged: (val) => _toggle(item['id'], val),
                              activeColor: const Color(0xFF6366F1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _delete(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

