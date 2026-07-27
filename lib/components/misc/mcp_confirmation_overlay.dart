import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/preferences/app_preferences.dart';
import '../../core/theme/color_tokens.dart';
import '../../server/providers/server_providers.dart';

class McpConfirmationOverlay extends ConsumerStatefulWidget {
  const McpConfirmationOverlay({super.key});

  @override
  ConsumerState<McpConfirmationOverlay> createState() => _McpConfirmationOverlayState();
}

class _McpConfirmationOverlayState extends ConsumerState<McpConfirmationOverlay> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(mcpConfirmationProvider);
    if (request == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark
        ? ColorTokens.darkSurface.withOpacity(0.85)
        : Colors.white.withOpacity(0.85);

    return Material(
      color: Colors.black.withOpacity(0.4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldAlert,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Security Authorization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'An AI Agent (MCP) is requesting permission to execute a control action on your device.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Command: ${request.command.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Payload: ${request.payload}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _dontAskAgain,
                      onChanged: (val) {
                        setState(() {
                          _dontAskAgain = val ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Trust always (disable future security prompts)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (_dontAskAgain) {
                          AppPreferences().set('mcpConfirmationRequired', false);
                        }
                        ref.read(mcpConfirmationProvider.notifier).deny();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Deny Action'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Allow Action'),
                      onPressed: () {
                        if (_dontAskAgain) {
                          AppPreferences().set('mcpConfirmationRequired', false);
                        }
                        ref.read(mcpConfirmationProvider.notifier).approve();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
