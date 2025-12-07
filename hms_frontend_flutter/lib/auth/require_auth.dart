// lib/auth/require_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';

/// Call this before any gated action:
/// await requireAuth(ref, context, () { context.go('/app'); });
Future<void> requireAuth(
  WidgetRef ref,
  BuildContext context,
  Future<void> Function() onAuthed,
) async {
  try {
    final s = ref.read(sessionAtomProvider).value;
    if (s != null) {
      try {
        await onAuthed();
      } catch (e) {
        // Handle errors in the authed callback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
      return;
    }

    // Ask to sign in
    if (!context.mounted) return;
    
    bool? go;
    try {
      go = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Sign in required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Please sign in to continue.'),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign in')),
            ]),
          ]),
        ),
      );
    } catch (e) {
      // Handle modal errors
      return;
    }

    if (go == true && context.mounted) {
      try {
        context.push('/login');
      } catch (e) {
        // Handle navigation errors
      }
    }
  } catch (e) {
    // Handle any unexpected errors
    if (context.mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
          ),
        );
      } catch (_) {
        // Ignore if context is no longer valid
      }
    }
  }
}
