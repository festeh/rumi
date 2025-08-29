import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notes_provider.dart';

class DatePickerWidget extends StatelessWidget {
  const DatePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final selectedDate = notesProvider.selectedDate;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 60,
          child: Row(
            children: [
              // Previous day button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final previousDay = selectedDate.subtract(const Duration(days: 1));
                  notesProvider.setSelectedDate(previousDay);
                },
              ),
              
              // Date display and picker
              Expanded(
                child: InkWell(
                  onTap: () => _showDatePicker(context, notesProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatSelectedDate(selectedDate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isToday(selectedDate))
                          Text(
                            'Today',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Next day button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextDay = selectedDate.add(const Duration(days: 1));
                  notesProvider.setSelectedDate(nextDay);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return DateFormat('EEEE, MMM dd').format(date);
    } else if (difference == -1) {
      return 'Yesterday, ${DateFormat('MMM dd').format(date)}';
    } else if (difference == 1) {
      return 'Tomorrow, ${DateFormat('MMM dd').format(date)}';
    } else {
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  Future<void> _showDatePicker(BuildContext context, NotesProvider notesProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: notesProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != notesProvider.selectedDate) {
      notesProvider.setSelectedDate(picked);
    }
  }
}