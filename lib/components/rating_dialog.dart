import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingDialog extends StatefulWidget {
  final String ratedUserName;
  final String ratedUserAvatar;
  final Function(int) onRate;

  const RatingDialog({
    super.key,
    required this.ratedUserName,
    required this.ratedUserAvatar,
    required this.onRate,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Center(
        child: Text(
          'Rate Experience',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.ratedUserAvatar.isNotEmpty 
                ? NetworkImage(widget.ratedUserAvatar) 
                : null,
            child: widget.ratedUserAvatar.isEmpty 
                ? Text(widget.ratedUserName.isNotEmpty ? widget.ratedUserName[0] : '?') 
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'How was your experience with ${widget.ratedUserName}?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          // Custom Star Rating Row since we might not have flutter_rating_bar package installed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1.0;
                  });
                },
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _rating > 0 
              ? () {
                  widget.onRate(_rating.toInt());
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }
}
