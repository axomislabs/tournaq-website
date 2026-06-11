import 'package:flutter/material.dart';
import '../app/app_assets.dart';
import '../app/app_colors.dart';

class TournaQAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const TournaQAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? kToolbarHeight + 18 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final toolbarH = subtitle != null ? kToolbarHeight + 18 : kToolbarHeight;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.goldLight,
      toolbarHeight: toolbarH,
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
      centerTitle: true,
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.goldCream,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Text(
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
