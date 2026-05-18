import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reminder_model.dart';
import 'reminder_card.dart';

class ReminderCarousel extends StatefulWidget {
  final List<ReminderModel> reminders;
  final Function(int) onComplete;
  final Function(ReminderModel)? onView;

  const ReminderCarousel({
    super.key,
    required this.reminders,
    required this.onComplete,
    this.onView,
  });

  @override
  State<ReminderCarousel> createState() => _ReminderCarouselState();
}

class _ReminderCarouselState extends State<ReminderCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.reminders.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 10),
            height: 200,
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            viewportFraction: 1.0,
            onPageChanged: (index, _) => setState(() => _currentPage = index),
          ),
          items: widget.reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            final bool isFocused = _currentPage == index;

            return ReminderCard(
              key: ValueKey(reminder.id),
              reminder: reminder,
              isActive: isFocused,
              onComplete: () => widget.onComplete(reminder.id),
              onView: () => widget.onView?.call(reminder),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.reminders.length, (index) {
        final bool isSelected = _currentPage == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isSelected ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
