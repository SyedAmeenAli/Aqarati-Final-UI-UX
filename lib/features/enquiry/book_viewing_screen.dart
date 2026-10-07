import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../data/models/booking.dart';
import '../../data/models/enums.dart';
import '../../data/models/money.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';

class BookViewingScreen extends ConsumerStatefulWidget {
  final Property property;

  const BookViewingScreen({super.key, required this.property});

  @override
  ConsumerState<BookViewingScreen> createState() => _BookViewingScreenState();
}

class _BookViewingScreenState extends ConsumerState<BookViewingScreen> {
  static const _timeSlots = ['9:00 AM', '10:30 AM', '12:00 PM', '2:00 PM', '3:30 PM', '5:00 PM'];

  late final List<DateTime> _dates = List.generate(
    14,
    (i) => DateTime.now().add(Duration(days: i + 1)),
  );

  DateTime? _selectedDate;
  String? _selectedTime;
  bool _confirmed = false;

  bool get _canConfirm => _selectedDate != null && _selectedTime != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dates.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Viewing')),
      body: _confirmed ? _buildSuccess(theme) : _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.property.title, style: theme.textTheme.titleLarge),
                Text(widget.property.locationLabel, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                Text('Select a date', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final date = _dates[i];
                      final selected = _selectedDate?.day == date.day && _selectedDate?.month == date.month;
                      return _DateChip(
                        date: date,
                        selected: selected,
                        onTap: () => setState(() => _selectedDate = date),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Select a time', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _timeSlots.map((t) {
                    final selected = _selectedTime == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedTime = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.primary, size: AppIconSize.compact),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Viewing location: ${widget.property.locationLabel}', style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AqaratiButton(
            label: 'Confirm booking',
            fullWidth: true,
            onPressed: _canConfirm
                ? () {
                    ref.read(bookingsProvider.notifier).update((state) => [
                          ...state,
                          Booking(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            context: BookingContext.propertyViewing,
                            contextTitle: widget.property.title,
                            date: _selectedDate!,
                            timeSlotLabel: _selectedTime!,
                            locationLabel: widget.property.locationLabel,
                            price: const Money(0),
                            status: BookingStatus.confirmed,
                          ),
                        ]);
                    setState(() => _confirmed = true);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    final date = _selectedDate!;
    final weekday = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    final month = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][date.month - 1];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xl),
          Text('Viewing scheduled', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your viewing for ${widget.property.title} is confirmed.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.property.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: AppIconSize.compact, color: AppColors.slate),
                    const SizedBox(width: AppSpacing.sm),
                    Text('$weekday, ${date.day} $month', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, size: AppIconSize.compact, color: AppColors.slate),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_selectedTime!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(
            label: 'Back to listing',
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: () {}, child: const Text('Add to calendar')),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({required this.date, required this.selected, required this.onTap});

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdays[date.weekday - 1],
              style: theme.textTheme.labelSmall?.copyWith(color: selected ? Colors.white70 : AppColors.slate),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(color: selected ? Colors.white : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
