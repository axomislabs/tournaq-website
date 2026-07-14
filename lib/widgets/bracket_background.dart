import 'package:flutter/material.dart';
import '../app/app_assets.dart';

/// Wraps [child] in the subtle bracket texture used across TournaQ's tournament
/// surfaces, at the same 6% opacity as [ScrollablePage]. Use this for pages
/// whose body is a sliver/list scroll view (hubs, the Arena) where
/// [ScrollablePage]'s built-in [SingleChildScrollView] doesn't fit.
class BracketBackground extends StatelessWidget {
  final Widget child;

  const BracketBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Fill the available space so the texture always covers the whole body,
    // even when the child (e.g. a short SingleChildScrollView) would otherwise
    // shrink-wrap and leave the lower part of the screen blank.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.background),
          fit: BoxFit.cover,
          opacity: 0.06,
        ),
      ),
      child: child,
    );
  }
}
