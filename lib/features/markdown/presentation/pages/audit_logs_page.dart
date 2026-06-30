import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/audit_log.dart';
import '../providers/markdown_file_provider.dart';

final auditLogsFutureProvider = FutureProvider<List<AuditLog>>((ref) async {
  final repo = ref.watch(auditLogRepositoryProvider);
  return await repo.getLogs();
});

class AuditLogsPage extends ConsumerWidget {
  const AuditLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogsAsync = ref.watch(auditLogsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Security Audit Trail', style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(auditLogsFutureProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cryptographically tracks file creation, unlocks, edits, and backups.',
              style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey400),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Expanded(
              child: auditLogsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('Failed to load logs: $err', style: GoogleFonts.saira())),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        'No logs saved.',
                        style: GoogleFonts.saira(color: AppColors.grey400),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActionColor(log.action).withOpacity(0.1),
                          child: Icon(_getActionIcon(log.action), color: _getActionColor(log.action)),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                log.action,
                                style: GoogleFonts.saira(fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat.yMMMd().add_jm().format(log.createdAt),
                              style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey400),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(log.description, style: GoogleFonts.saira(fontSize: 13)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.devices_rounded, size: 12, color: AppColors.grey400),
                                const SizedBox(width: 4),
                                Text(log.deviceInfo, style: GoogleFonts.saira(fontSize: 10, color: AppColors.grey500)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('Created')) return AppColors.primary;
    if (action.contains('Deleted')) return AppColors.error;
    if (action.contains('Locked')) return AppColors.grey500;
    if (action.contains('Unlocked')) return AppColors.grey500;
    return AppColors.warning;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('Created')) return Icons.add_circle_outline_rounded;
    if (action.contains('Deleted')) return Icons.delete_sweep_rounded;
    if (action.contains('Locked')) return Icons.lock_rounded;
    if (action.contains('Unlocked')) return Icons.lock_open_rounded;
    return Icons.settings_backup_restore_rounded;
  }
}
