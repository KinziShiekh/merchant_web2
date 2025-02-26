import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomIconButton extends StatefulWidget {
  final String label; // Button text
  final IconData icon; // Icon for the button
  final VoidCallback onPressed; // Functionality on button press
  final Color backgroundColor; // Background color of the button
  final Color textColor; // Text color
  final Color iconColor; // Icon color
  final double fontSize; // Font size of the label
  final double borderRadius; // Button corner radius
  final double padding; // Padding around the button
  final double? width; // Optional width
  final double? height; // Optional height

  const CustomIconButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFFF6B01),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.fontSize = 14.0,
    this.borderRadius = 12.0,
    this.padding = 16.0,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  _CustomIconButtonState createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> {
  bool _isHovered = false; // Track hover state

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Animation duration
        curve: Curves.easeInOut, // Smooth animation curve
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.backgroundColor
                  .withOpacity(0.9) // Slightly lighter on hover
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.backgroundColor.withOpacity(0.5),
                    offset: const Offset(0, 4), // Hover shadow offset
                    blurRadius: 12, // Blur effect on hover
                  )
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Use the container's color
            shadowColor: Colors.transparent, // Remove button's default shadow
            padding: EdgeInsets.symmetric(vertical: widget.padding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
          icon: Icon(
            widget.icon,
            color: widget.iconColor,
          ),
          label: Text(
            widget.label,
            style: GoogleFonts.poppins(
              color: widget.textColor,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
