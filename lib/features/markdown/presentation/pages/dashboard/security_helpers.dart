import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/ad_service.dart';
import '../../../domain/entities/markdown_file.dart';
import '../../../domain/entities/folder.dart';
import '../../providers/security_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/editor_provider.dart';
import '../../providers/markdown_file_provider.dart';
import '../editor_page.dart';

Future<bool> authenticateItem(
  BuildContext context,
  WidgetRef ref, {
  required bool isLocked,
  required String? lockType,
  required int id,
  required String name,
  required bool isFolder,
}) async {
  if (!isLocked) return true;

  final subState = ref.read(subscriptionProvider);
  bool adCompleted = true;

  if (!subState.isSubscribed) {
    adCompleted = false;
    await AdService.showRewardedVideoAd(
      context,
      'Unlock ${isFolder ? "Folder" : "File"}',
      () => adCompleted = true,
    );
  }

  if (!adCompleted) return false;

  if (lockType == 'password') {
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isFolder ? 'Decrypt Folder' : 'Decrypt File', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter password to authorize action on "$name".',
              style: GoogleFonts.saira(fontSize: 13, color: AppColors.grey500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter password',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              final verified = isFolder
                  ? await ref.read(securityProvider.notifier).unlockFolderWithPassword(id, password)
                  : await ref.read(securityProvider.notifier).unlockFileWithPassword(id, password);
              if (verified) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid password. Access Denied.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Unlock'),
          )
        ],
      ),
    );
    return result ?? false;
  } else if (lockType == 'biometric') {
    final authenticated = await ref
        .read(securityProvider.notifier)
        .authenticateBiometrics('Unlock ${isFolder ? "folder" : "file"} "$name"');
    if (!authenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    return authenticated;
  }
  return true;
}

Future<void> openSecuredFile(BuildContext context, WidgetRef ref, MarkdownFile file) async {
  final authenticated = await authenticateItem(
    context,
    ref,
    isLocked: file.isLocked,
    lockType: file.lockType,
    id: file.id!,
    name: file.title,
    isFolder: false,
  );
  if (authenticated) {
    ref.read(editorProvider.notifier).openFile(file);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorPage()));
    }
  }
}

Future<void> openSecuredFolder(BuildContext context, WidgetRef ref, Folder folder) async {
  final authenticated = await authenticateItem(
    context,
    ref,
    isLocked: folder.isLocked,
    lockType: folder.lockType,
    id: folder.id!,
    name: folder.name,
    isFolder: true,
  );
  if (authenticated) {
    ref.read(markdownFileProvider.notifier).setCurrentFolder(folder.id);
  }
}
