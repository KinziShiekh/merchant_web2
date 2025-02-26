import 'package:flutter/material.dart';

class SidebarItem extends StatefulWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const SidebarItem({
    Key? key,
    required this.title,
    required this.image,
    required this.onTap,
  }) : super(key: key);

  @override
  _SidebarItemState createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _isHovered = false; // Tracks hover state

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true; // When the mouse enters
      }),
      onExit: (_) => setState(() {
        _isHovered = false; // When the mouse exits
      }),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 300), // Smooth animation duration
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovered
                ? Colors.white.withOpacity(0.1) // Background color on hover
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Animated Icon Scale on Hover
              AnimatedScale(
                scale: _isHovered ? 1.2 : 1.0, // Slightly enlarge on hover
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  widget.image,
                  height: 30,
                  width: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Animated Text Style and Opacity
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.8, // Adjust opacity on hover
                duration: const Duration(milliseconds: 300),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: _isHovered
                        ? Colors.orange
                        : Colors.white, // Change color on hover
                    fontSize: 18,
                    fontWeight: _isHovered
                        ? FontWeight.bold
                        : FontWeight.normal, // Change weight on hover
                  ),
                  child: Text(widget.title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
