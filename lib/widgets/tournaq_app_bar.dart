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
      titleSpacing: 8,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/tournaq_icon.png',
            height: 28,
            width: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(title, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: actions,
    );
  }
}
