import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:merchandiser_web/constant/colors.dart';

class EnhancedSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged; // Callback for text changes

  const EnhancedSearchField({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  _EnhancedSearchFieldState createState() => _EnhancedSearchFieldState();
}

class _EnhancedSearchFieldState extends State<EnhancedSearchField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: 'Search by Name',
        labelStyle: GoogleFonts.poppins(color: AppColors.MainColor),
        hintText: 'Enter name...',
        hintStyle: GoogleFonts.poppins(color: AppColors.MainColor),
        prefixIcon: const Icon(Icons.search, color: AppColors.MainColor),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.MainColor),
                onPressed: () {
                  widget.controller.clear(); // Clear the text
                  widget.onChanged(''); // Trigger onChanged with empty value
                  setState(() {}); // Update the UI
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
          borderSide: const BorderSide(color: AppColors.MainColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.MainColor, width: 2), // Highlighted border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.MainColor, width: 1),
        ),
        filled: true,
        fillColor: Colors.white, // Light background for better visibility
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
      onChanged: widget.onChanged, // Pass text changes to parent widget
    );
  }
}
