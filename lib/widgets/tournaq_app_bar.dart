import 'package:flutter/material.dart';

class TournaQAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const TournaQAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFFF0D47A),
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF6E7640)),
          Image.asset(
            'assets/tournaq_background.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.10),
          ),
        ],
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFF0D47A),
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
