import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notes_provider.dart';
import '../theme/tokens.dart';

class DatePickerWidget extends StatelessWidget {
  const DatePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final selectedDate = notesProvider.selectedDate;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: IntrinsicHeight(
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
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatSelectedDate(selectedDate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isToday(selectedDate))
                          Text(
                            'Today',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
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
                onPressed: _isToday(selectedDate) ? null : () {
                  final nextDay = selectedDate.add(const Duration(days: 1));
                  notesProvider.setSelectedDate(nextDay);
                },
              ),
            ],
            ),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: notesProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: today,
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