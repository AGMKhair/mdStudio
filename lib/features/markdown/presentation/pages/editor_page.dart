import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/file_history.dart';
import '../providers/editor_provider.dart';
import '../providers/history_provider.dart';
import '../providers/security_provider.dart';
import '../../../../core/utils/exporter.dart';
import '../../../../core/services/ad_service.dart';
import '../providers/subscription_provider.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _gutterScrollController = ScrollController();

  // Search and replace state
  bool _showSearchReplace = false;
  bool _showPreviewOnMobile = false;
  final _searchController = TextEditingController();
  final _replaceController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Synchronize gutter scrolling with editor textfield scrolling
    _scrollController.addListener(() {
      if (_gutterScrollController.hasClients) {
        _gutterScrollController.jumpTo(_scrollController.offset);
      }
    });

    // Load active file content into controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorState = ref.read(editorProvider);
      if (editorState.activeFile != null) {
        _textController.text = editorState.currentContent;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _gutterScrollController.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Insert markdown tag at selection
  void _insertMarkdownTag(String prefix, [String suffix = '']) {
    final text = _textController.text;
    final selection = _textController.selection;
    
    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);
    
    ref.read(editorProvider.notifier).updateContent(newText);
    _textController.value = _textController.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
  }

  void _replaceAll() {
    final search = _searchController.text;
    final replace = _replaceController.text;
    if (search.isEmpty) return;

    final text = _textController.text;
    final newText = text.replaceAll(search, replace);

    ref.read(editorProvider.notifier).updateContent(newText);
    _textController.value = _textController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replaced all matches!')),
    );
  }

  int _calculateWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final file = editorState.activeFile;

    if (file == null) {
      return const Scaffold(
        body: Center(child: Text('No document loaded.')),
      );
    }

    // Recalculate line numbers
    final linesCount = '\n'.allMatches(editorState.currentContent).length + 1;
    final lineNumbersText = List.generate(linesCount, (i) => '${i + 1}').join('\n');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              file.isLocked ? Icons.lock_outline_rounded : Icons.description_outlined,
              color: file.isLocked ? AppColors.grey500 : AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                file.title,
                style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(editorProvider.notifier).closeFile();
            Navigator.of(context).pop();
          },
        ),
        actions: () {
          final isMobile = MediaQuery.of(context).size.width <= 600;
          if (isMobile) {
            return [
              IconButton(
                onPressed: () => setState(() => _showPreviewOnMobile = !_showPreviewOnMobile),
                icon: Icon(_showPreviewOnMobile ? Icons.edit_rounded : Icons.visibility_rounded),
                tooltip: _showPreviewOnMobile ? 'Switch to Editor' : 'Switch to Preview',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More Actions',
                onSelected: (val) async {
                  if (val == 'search_replace') {
                    setState(() => _showSearchReplace = !_showSearchReplace);
                  } else if (val == 'unlock') {
                    await ref.read(securityProvider.notifier).removeFileLock(file.id!);
                    ref.read(editorProvider.notifier).openFile(file.copyWith(isLocked: false, lockType: null));
                  } else if (val == 'lock_password') {
                    _showSetPasswordLockDialog(file.id!);
                  } else if (val == 'lock_biometric') {
                    await ref.read(securityProvider.notifier).lockFileWithBiometrics(file.id!);
                    ref.read(editorProvider.notifier).openFile(file.copyWith(isLocked: true, lockType: 'biometric'));
                  } else if (val == 'history') {
                    Scaffold.of(context).openEndDrawer();
                  } else if (val.startsWith('export_')) {
                    final format = val.substring('export_'.length);
                    final subState = ref.read(subscriptionProvider);

                    Future<void> proceedExport() async {
                      final success = await DocumentExporter.exportFile(
                        title: file.title,
                        content: editorState.currentContent,
                        format: format,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Document exported successfully!' : 'Export failed or cancelled.'),
                            backgroundColor: success ? AppColors.secondary : AppColors.error,
                          ),
                        );
                      }
                    }

                    if (!subState.isSubscribed) {
                      await AdService.showRewardedVideoAd(context, 'Export File', () async {
                        await proceedExport();
                      });
                    } else {
                      await proceedExport();
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'search_replace',
                    child: ListTile(
                      leading: Icon(Icons.find_replace_rounded),
                      title: Text('Search & Replace'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      leading: Icon(Icons.history_rounded),
                      title: Text('Version History'),
                    ),
                  ),
                  if (file.isLocked)
                    const PopupMenuItem(
                      value: 'unlock',
                      child: ListTile(
                        leading: Icon(Icons.lock_open_rounded),
                        title: Text('Remove Security Lock'),
                      ),
                    )
                  else ...[
                    const PopupMenuItem(
                      value: 'lock_password',
                      child: ListTile(
                        leading: Icon(Icons.password_rounded),
                        title: Text('Encrypt with Password'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'lock_biometric',
                      child: ListTile(
                        leading: Icon(Icons.fingerprint_rounded),
                        title: Text('Encrypt with Biometrics'),
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'export_md',
                    child: ListTile(
                      leading: Icon(Icons.description_rounded),
                      title: Text('Export as Markdown'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded),
                      title: Text('Export as PDF'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_html',
                    child: ListTile(
                      leading: Icon(Icons.html_rounded),
                      title: Text('Export as HTML'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_txt',
                    child: ListTile(
                      leading: Icon(Icons.text_fields_rounded),
                      title: Text('Export as Text'),
                    ),
                  ),
                ],
              ),
            ];
          } else {
            return [
              IconButton(
                onPressed: () => setState(() => _showSearchReplace = !_showSearchReplace),
                icon: const Icon(Icons.find_replace_rounded),
                tooltip: 'Search & Replace',
              ),
              IconButton(
                onPressed: () => ref.read(editorProvider.notifier).togglePreviewSplit(),
                icon: Icon(editorState.isPreviewSplit ? Icons.splitscreen_rounded : Icons.view_sidebar_rounded),
                tooltip: 'Toggle Split Preview',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.security_rounded),
                tooltip: 'File Encryption Settings',
                onSelected: (val) async {
                  if (val == 'unlock') {
                    await ref.read(securityProvider.notifier).removeFileLock(file.id!);
                    ref.read(editorProvider.notifier).openFile(file.copyWith(isLocked: false, lockType: null));
                  } else if (val == 'lock_password') {
                    _showSetPasswordLockDialog(file.id!);
                  } else if (val == 'lock_biometric') {
                    await ref.read(securityProvider.notifier).lockFileWithBiometrics(file.id!);
                    ref.read(editorProvider.notifier).openFile(file.copyWith(isLocked: true, lockType: 'biometric'));
                  }
                },
                itemBuilder: (ctx) => [
                  if (file.isLocked)
                    const PopupMenuItem(value: 'unlock', child: Text('Remove Lock Protection'))
                  else ...[
                    const PopupMenuItem(value: 'lock_password', child: Text('Encrypt with Password')),
                    const PopupMenuItem(value: 'lock_biometric', child: Text('Encrypt with Biometrics')),
                  ]
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Export File',
                onSelected: (format) async {
                  final subState = ref.read(subscriptionProvider);

                  Future<void> proceedExport() async {
                    final success = await DocumentExporter.exportFile(
                      title: file.title,
                      content: editorState.currentContent,
                      format: format,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Document exported successfully!' : 'Export failed or cancelled.'),
                          backgroundColor: success ? AppColors.secondary : AppColors.error,
                        ),
                      );
                    }
                  }

                  if (!subState.isSubscribed) {
                    await AdService.showRewardedVideoAd(context, 'Export File', () async {
                      await proceedExport();
                    });
                  } else {
                    await proceedExport();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'md', child: Text('Export as Markdown (.md)')),
                  const PopupMenuItem(value: 'pdf', child: Text('Export as PDF (.pdf)')),
                  const PopupMenuItem(value: 'html', child: Text('Export as HTML (.html)')),
                  const PopupMenuItem(value: 'txt', child: Text('Export as Text (.txt)')),
                ],
              ),
              Builder(
                builder: (context) => IconButton(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: const Icon(Icons.history_rounded),
                  tooltip: 'Version History',
                ),
              ),
            ];
          }
        }(),
      ),
      endDrawer: _VersionHistoryDrawer(fileId: file.id!, fileTitle: file.title),
      body: Column(
        children: [
          // Formatting & Editor Utilities Toolbar
          _buildToolbar(),
          
          if (_showSearchReplace) _buildSearchReplaceBar(),

          // Main Editor Split layout
          Expanded(
            child: () {
              final isMobile = MediaQuery.of(context).size.width <= 600;
              if (isMobile) {
                if (_showPreviewOnMobile) {
                  return Container(
                    color: isDark ? AppColors.darkScaffoldBg : AppColors.scaffoldBg,
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Markdown(
                      data: editorState.currentContent,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: GoogleFonts.saira(fontSize: 14),
                        h1: GoogleFonts.saira(fontSize: 22, fontWeight: FontWeight.bold),
                        h2: GoogleFonts.saira(fontSize: 18, fontWeight: FontWeight.bold),
                        h3: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.bold),
                        code: GoogleFonts.sourceCodePro(fontSize: 12, backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100),
                      ),
                    ),
                  );
                } else {
                  return Container(
                    color: isDark ? const Color(0xFF0F1424) : Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gutter line numbers
                        Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B0E1B) : AppColors.grey50,
                            border: Border(
                              right: BorderSide(
                                color: isDark ? AppColors.grey800 : AppColors.grey200,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: _gutterScrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Text(
                              lineNumbersText,
                              style: GoogleFonts.sourceCodePro(
                                color: AppColors.grey400,
                                fontSize: 13,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Editor TextField
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _textController,
                              scrollController: _scrollController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              expands: true,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (text) {
                                ref.read(editorProvider.notifier).updateContent(text);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: isDark ? const Color(0xFF0F1424) : Colors.white,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0B0E1B) : AppColors.grey50,
                                border: Border(
                                  right: BorderSide(
                                    color: isDark ? AppColors.grey800 : AppColors.grey200,
                                  ),
                                ),
                              ),
                              child: SingleChildScrollView(
                                controller: _gutterScrollController,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Text(
                                  lineNumbersText,
                                  style: GoogleFonts.sourceCodePro(
                                    color: AppColors.grey400,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: _textController,
                                  scrollController: _scrollController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  expands: true,
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: isDark ? Colors.white : AppColors.grey900,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (text) {
                                    ref.read(editorProvider.notifier).updateContent(text);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (editorState.isPreviewSplit) ...[
                      VerticalDivider(
                        width: 1,
                        color: isDark ? AppColors.grey800 : AppColors.grey300,
                      ),
                      Expanded(
                        child: Container(
                          color: isDark ? AppColors.darkScaffoldBg : AppColors.scaffoldBg,
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          child: Markdown(
                            data: editorState.currentContent,
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: GoogleFonts.saira(fontSize: 14),
                              h1: GoogleFonts.saira(fontSize: 22, fontWeight: FontWeight.bold),
                              h2: GoogleFonts.saira(fontSize: 18, fontWeight: FontWeight.bold),
                              h3: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.bold),
                              code: GoogleFonts.sourceCodePro(fontSize: 12, backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }
            }(),
          ),

          // Bottom status bar
          _buildStatusBar(editorState),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      color: isDark ? AppColors.darkCardBg : AppColors.grey100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Editor Stack Undo/Redo
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 18),
            onPressed: () => ref.read(editorProvider.notifier).undo(_textController),
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 18),
            onPressed: () => ref.read(editorProvider.notifier).redo(_textController),
            tooltip: 'Redo',
          ),
          const VerticalDivider(),
          
          // Headings
          IconButton(
            icon: const Icon(Icons.title_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('# '),
            tooltip: 'Heading 1',
          ),
          IconButton(
            icon: const Icon(Icons.format_bold_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('**', '**'),
            tooltip: 'Bold',
          ),
          IconButton(
            icon: const Icon(Icons.format_italic_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('*', '*'),
            tooltip: 'Italic',
          ),
          IconButton(
            icon: const Icon(Icons.format_quote_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('> '),
            tooltip: 'Quote',
          ),
          IconButton(
            icon: const Icon(Icons.code_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('```\n', '\n```'),
            tooltip: 'Code Block',
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('[', '](https://)'),
            tooltip: 'Insert Link',
          ),
          IconButton(
            icon: const Icon(Icons.image_rounded, size: 18),
            onPressed: () => _insertMarkdownTag('![ImageDescription](', ')'),
            tooltip: 'Insert Image',
          ),
          IconButton(
            icon: const Icon(Icons.grid_on_rounded, size: 18),
            onPressed: () => _insertMarkdownTag(
              '| Header 1 | Header 2 |\n| -------- | -------- |\n| Cell 1   | Cell 2   |\n'
            ),
            tooltip: 'Insert Table',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchReplaceBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showRow = MediaQuery.of(context).size.width > 600;

    final searchField = TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search text...',
        prefixIcon: Icon(Icons.search_rounded, size: 16),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );

    final replaceField = TextField(
      controller: _replaceController,
      decoration: const InputDecoration(
        hintText: 'Replace with...',
        prefixIcon: Icon(Icons.find_replace_rounded, size: 16),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    );

    final actionButton = OutlinedButton(
      onPressed: _replaceAll,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(80, 36),
      ),
      child: const Text('Replace All'),
    );

    if (showRow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark ? const Color(0xFF141A2E) : AppColors.grey50,
        child: Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            Expanded(child: replaceField),
            const SizedBox(width: 8),
            actionButton,
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? const Color(0xFF141A2E) : AppColors.grey50,
        child: Column(
          children: [
            searchField,
            const SizedBox(height: 8),
            replaceField,
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: actionButton,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusBar(EditorState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: state.isSaving
          ? AppColors.primary
          : isDark
              ? const Color(0xFF0F172A)
              : AppColors.grey200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                state.isSaving ? Icons.sync_rounded : Icons.check_circle_outline_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                state.isSaving ? 'Saving changes...' : 'Saved',
                style: GoogleFonts.saira(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            'Words: ${_calculateWords(state.currentContent)}  |  Lines: ${'\n'.allMatches(state.currentContent).length + 1}',
            style: GoogleFonts.saira(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSetPasswordLockDialog(int fileId) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encrypt File with Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter encryption password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.length >= 4) {
                Navigator.of(ctx).pop();
                await ref.read(securityProvider.notifier).lockFileWithPassword(fileId, password);
                final currentFile = ref.read(editorProvider).activeFile;
                if (currentFile != null) {
                  ref.read(editorProvider.notifier).openFile(
                    currentFile.copyWith(isLocked: true, lockType: 'password')
                  );
                }
              }
            },
            child: const Text('Lock File'),
          ),
        ],
      ),
    );
  }
}

// ─── END DRAWER VERSION HISTORY COMPONENT ────────────────────────
class _VersionHistoryDrawer extends ConsumerWidget {
  final int fileId;
  final String fileTitle;

  const _VersionHistoryDrawer({required this.fileId, required this.fileTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyProvider(fileId));

    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: Text('Version Control', style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 16)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Select a snapshot of "$fileTitle" to inspect differences or restore.',
              style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
            ),
          ),
          const Divider(),
          Expanded(
            child: historyList.isEmpty
                ? Center(
                    child: Text(
                      'No saved edit snapshots.',
                      style: GoogleFonts.saira(color: AppColors.grey400),
                    ),
                  )
                : ListView.builder(
                    itemCount: historyList.length,
                    itemBuilder: (context, i) {
                      final history = historyList[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary),
                        ),
                        title: Text(
                          history.actionType,
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          DateFormat.yMMMd().add_jm().format(history.createdAt),
                          style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey400),
                        ),
                        onTap: () {
                          _showDiffCompareDialog(context, ref, history);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDiffCompareDialog(BuildContext context, WidgetRef ref, FileHistory history) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Compare Snapshots', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Text(
                'Showing changes made on ${DateFormat.yMMMd().add_jm().format(history.createdAt)}',
                style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    // OLD CONTENT
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131A26) : AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Previous Content',
                              style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.error),
                            ),
                            const Divider(),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  history.oldContent,
                                  style: GoogleFonts.sourceCodePro(fontSize: 11),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // NEW CONTENT
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13261F) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modified Content',
                              style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.secondary),
                            ),
                            const Divider(),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  history.newContent,
                                  style: GoogleFonts.sourceCodePro(fontSize: 11),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close drawer
              final success = await ref.read(historyProvider(fileId).notifier).restoreVersion(history);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Document restored successfully!' : 'Failed to restore.'),
                    backgroundColor: success ? AppColors.secondary : AppColors.error,
                  ),
                );
              }
            },
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: const Text('Restore This Version'),
          ),
        ],
      ),
    );
  }
}
