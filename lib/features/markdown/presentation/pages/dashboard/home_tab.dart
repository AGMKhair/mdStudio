import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/services/ad_service.dart';
import '../../../domain/entities/markdown_file.dart';
import '../../providers/markdown_file_provider.dart';
import 'security_helpers.dart';

class HomeTab extends ConsumerWidget {
  final Function(ExplorerFilter?) onNavigateToExplorer;
  const HomeTab({super.key, required this.onNavigateToExplorer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(markdownFileProvider);
    final stats = state.statistics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter files
    final recentFiles = state.allFiles.take(5).toList();
    final lockedFiles = state.allFiles.where((f) => f.isLocked).take(5).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(markdownFileProvider.notifier).loadAll(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.saira(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              Text(
                'Here is your secure document vault status overview.',
                style: GoogleFonts.saira(fontSize: 13, color: AppColors.grey400),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Statistics Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    'Total Files',
                    '${stats['totalFiles'] ?? 0}',
                    Icons.description_rounded,
                    AppColors.primary,
                    onTap: () => onNavigateToExplorer(ExplorerFilter.all),
                  ),
                  _buildStatCard(
                    context,
                    'Locked Files',
                    '${stats['lockedFiles'] ?? 0}',
                    Icons.lock_rounded,
                    AppColors.grey500,
                    onTap: () => onNavigateToExplorer(ExplorerFilter.locked),
                  ),
                  _buildStatCard(
                    context,
                    'Total Edits',
                    '${stats['totalEdits'] ?? 0}',
                    Icons.edit_note_rounded,
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    context,
                    'Total Words',
                    '${stats['totalWords'] ?? 0}',
                    Icons.abc_rounded,
                    AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              // Activity overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.flash_on_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Security Audit Event',
                              style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              stats['lastActivity'] ?? 'No recent logs recorded.',
                              style: GoogleFonts.saira(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.grey800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              // Recent Documents & Locked Documents split Row/Column
              () {
                final showSplit = MediaQuery.of(context).size.width > 600;
                final recentListWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently Modified',
                      style: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (recentFiles.isEmpty)
                      _buildEmptyList('No files in this folder.')
                    else
                      Column(
                        children: () {
                          final List<Widget> items = [];
                          for (int i = 0; i < recentFiles.length; i++) {
                            items.add(_buildFileItem(context, ref, recentFiles[i]));
                            if ((i + 1) % 4 == 0) {
                              items.add(const MockBannerAdCard());
                            }
                          }
                          return items;
                        }(),
                      ),
                  ],
                );

                final lockedListWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locked Crypt Vaults',
                      style: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (lockedFiles.isEmpty)
                      _buildEmptyList('No locked documents.')
                    else
                      Column(
                        children: () {
                          final List<Widget> items = [];
                          for (int i = 0; i < lockedFiles.length; i++) {
                            items.add(_buildFileItem(context, ref, lockedFiles[i]));
                            if ((i + 1) % 4 == 0) {
                              items.add(const MockBannerAdCard());
                            }
                          }
                          return items;
                        }(),
                      ),
                  ],
                );

                if (showSplit) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recentListWidget),
                      const SizedBox(width: 16),
                      Expanded(child: lockedListWidget),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      recentListWidget,
                      const SizedBox(height: 24),
                      lockedListWidget,
                    ],
                  );
                }
              }(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap ?? () => onNavigateToExplorer(null),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.saira(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.saira(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyList(String text) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.grey200, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.saira(color: AppColors.grey400, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, WidgetRef ref, MarkdownFile file) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          file.isLocked ? Icons.lock_outline_rounded : Icons.description_outlined,
          color: file.isLocked ? AppColors.grey500 : AppColors.primary,
        ),
        title: Text(
          file.title,
          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Updated: ${DateFormat.yMMMd().add_jm().format(file.updatedAt)}',
          style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey400),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
        onTap: () => openSecuredFile(context, ref, file),
      ),
    );
  }
}
