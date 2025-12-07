import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

class DoctorWorkHoursScreen extends ConsumerStatefulWidget {
  const DoctorWorkHoursScreen({super.key});

  @override
  ConsumerState<DoctorWorkHoursScreen> createState() => _DoctorWorkHoursScreenState();
}

class _DoctorWorkHoursScreenState extends ConsumerState<DoctorWorkHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // 0=Sunday, 1=Monday, ... 6=Saturday
  final List<Map<String, dynamic>> _weeklySchedule = List.generate(7, (index) => {
    'weekday': index,
    'enabled': false,
    'startHour': 9,
    'endHour': 17,
  });

  final List<String> _dayNames = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final session = ref.read(authControllerProvider).session;
      final userId = session?.user['id']?.toString();
      
      if (userId == null) return;

      final service = ref.read(doctorsServiceProvider);
      final availability = await service.getAvailability(userId);

      setState(() {
        // Reset to defaults first
        for (var day in _weeklySchedule) {
          day['enabled'] = false;
          day['startHour'] = 9;
          day['endHour'] = 17;
        }

        // Apply fetched availability
        for (var slot in availability) {
          final weekday = slot['weekday'] as int;
          if (weekday >= 0 && weekday < 7) {
            _weeklySchedule[weekday]['enabled'] = true;
            _weeklySchedule[weekday]['startHour'] = slot['startHour'];
            _weeklySchedule[weekday]['endHour'] = slot['endHour'];
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading availability: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    try {
      final session = ref.read(authControllerProvider).session;
      final userId = session?.user['id']?.toString();
      
      if (userId == null) return;

      final workHours = _weeklySchedule
          .where((day) => day['enabled'] == true)
          .map((day) => {
                'weekday': day['weekday'],
                'startHour': day['startHour'],
                'endHour': day['endHour'],
              })
          .toList();

      final service = ref.read(doctorsServiceProvider);
      await service.setAvailability(userId, workHours);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work hours saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving work hours: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Hours'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveAvailability,
            icon: _isSaving 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                // Adjust index to start from Monday if desired, but backend uses 0=Sunday
                // Let's stick to 0=Sunday for simplicity or map it.
                // Usually apps show Monday first. Let's reorder for display if needed.
                // For now, standard 0=Sunday order.
                final day = _weeklySchedule[index];
                final isEnabled = day['enabled'] as bool;

                return Column(
                  children: [
                    CheckboxListTile(
                      title: Text(
                        _dayNames[index],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: isEnabled,
                      onChanged: (val) {
                        setState(() {
                          day['enabled'] = val ?? false;
                        });
                      },
                    ),
                    if (isEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimeDropdown(
                                label: 'Start',
                                value: day['startHour'],
                                onChanged: (val) {
                                  setState(() {
                                    day['startHour'] = val;
                                    if (day['endHour'] <= val!) {
                                      day['endHour'] = val + 1;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimeDropdown(
                                label: 'End',
                                value: day['endHour'],
                                onChanged: (val) {
                                  setState(() {
                                    day['endHour'] = val;
                                    if (day['startHour'] >= val!) {
                                      day['startHour'] = val - 1;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAvailability,
        label: _isSaving 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            )
          : const Text('Save Work Hours'),
        icon: _isSaving ? null : const Icon(Icons.save),
        backgroundColor: Colors.indigo, // Ensure good visibility
      ),
    );
  }

  Widget _buildTimeDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          items: List.generate(24, (index) {
            final hour = index;
            final suffix = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            return DropdownMenuItem(
              value: index,
              child: Text('$displayHour:00 $suffix'),
            );
          }),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
