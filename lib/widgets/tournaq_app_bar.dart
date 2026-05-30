import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';

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
      foregroundColor: AppColors.goldLight,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.oliveMedium),
          Image.asset(
            AppAssets.background,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.10),
          ),
        ],
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.goldLight,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
    );
  }
}
