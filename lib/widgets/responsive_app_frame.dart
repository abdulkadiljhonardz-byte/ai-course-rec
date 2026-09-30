import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.leading,
    this.bottomNavigationBar,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? leading;
  final Widget? bottomNavigationBar;

  static const double _maxWidth = 520;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        toolbarHeight: 56,
        leading: leading,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppPalette.textSecondary,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Container(
          color: AppPalette.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppPalette.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 14,
                    offset: Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: AppPalette.border),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: bottomNavigationBar!,
                  ),
                ),
              ),
            ),
    );
  }
}
