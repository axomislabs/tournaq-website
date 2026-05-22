import 'package:flutter/material.dart';

class ScrollablePage extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const ScrollablePage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}
