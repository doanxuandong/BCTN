import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating; // 0-5
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool editable;
  final Function(double)? onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 24,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.editable = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: editable && onRatingChanged != null
              ? () => onRatingChanged!(starValue.toDouble())
              : null,
          child: Icon(
            _getStarIcon(starValue),
            size: size,
            color: starValue <= rating ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(int starValue) {
    if (starValue <= rating) {
      return Icons.star;
    } else if (starValue - 0.5 <= rating) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }
}

/// Widget chọn số sao với animation
class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final double size;
  final Function(double) onRatingChanged;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    this.size = 40,
    required this.onRatingChanged,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = starValue.toDouble();
                });
                widget.onRatingChanged(_currentRating);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  starValue <= _currentRating ? Icons.star : Icons.star_border,
                  size: widget.size,
                  color: starValue <= _currentRating ? Colors.amber : Colors.grey,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_currentRating),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Tốt';
      case 5:
        return 'Rất tốt';
      default:
        return 'Chọn đánh giá';
    }
  }
}

