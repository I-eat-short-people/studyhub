import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cashew_bottom_sheet.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../documents/widgets/add_edit_document_sheet.dart';
import '../../subjects/widgets/add_edit_subject_sheet.dart';
import '../../borrow/presentation/borrow_management_screen.dart';
import '../../borrow/presentation/borrow_catalog_screen.dart';
import '../../map/presentation/document_map_screen.dart';
import '../../notifications/presentation/notifications_sheet.dart';
import '../../profile/widgets/user_avatar_menu_button.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.currentThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _borrowSubTab = 0;

  final List<String> _titles = const [
    'Tài liệu',
    'Quản lý mượn',
    'Mượn tài liệu',
    'Bản đồ tài liệu',
  ];

  void _showAddDialog() {
    showCashewModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CashewSheetHandle(),
            const SizedBox(height: 8),
            const Text(
              'Tạo mới',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.note_add_rounded,
                    color: Color(0xFF3F51B5)),
              ),
              title: const Text('Thêm tài liệu mới',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('PDF, Word, PowerPoint hoặc liên kết web'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onTap: () {
                Navigator.pop(ctx);
                showCashewModalBottomSheet(
                  context: context,
                  builder: (_) => const AddEditDocumentSheet(),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Color(0xFF43A047)),
              ),
              title: const Text('Thêm môn học mới',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Tạo danh mục để phân loại tài liệu'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onTap: () {
                Navigator.pop(ctx);
                showCashewModalBottomSheet(
                  context: context,
                  builder: (_) => const AddEditSubjectSheet(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const DocumentsScreen(showAppBar: false);
      case 1:
        return BorrowManagementScreen(
          key: ValueKey('borrow_mgmt_$_borrowSubTab'),
          showAppBar: false,
          initialSubTab: _borrowSubTab,
        );
      case 2:
        return const BorrowCatalogScreen(showAppBar: false);
      case 3:
        return const DocumentMapScreen(showAppBar: false);
      default:
        return const DocumentsScreen(showAppBar: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final isDark = widget.currentThemeMode == ThemeMode.dark ||
        (widget.currentThemeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Top AppBar thống nhất: Chỉ có Thông báo và Avatar
    final topAppBar = AppBar(
      title: Text(
        _titles[_currentIndex],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        NotificationBellButton(
          onNavigateToTab: (targetTab, subTab) {
            setState(() {
              _currentIndex = targetTab;
              _borrowSubTab = subTab ?? 0;
            });
          },
        ),
        const UserAvatarMenuButton(),
        const SizedBox(width: 8),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        appBar: topAppBar,
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF3F51B5),
                foregroundColor: Colors.white,
                onPressed: _showAddDialog,
                tooltip: 'Thêm tài liệu',
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm tài liệu'),
              )
            : null,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) {
                setState(() {
                  _currentIndex = idx;
                  _borrowSubTab = 0;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_library_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'StudyHub',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      ),
                      tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                      onPressed: widget.onToggleTheme,
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder_rounded),
                  label: Text('Tài liệu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake_rounded),
                  label: Text('Quản lý mượn'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: Text('Mượn tài liệu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: Text('Bản đồ'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _buildCurrentPage()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: topAppBar,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm tài liệu'),
              onPressed: _showAddDialog,
            )
          : null,
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
              _borrowSubTab = 0;
            });
          },
          backgroundColor: getColor(context, 'lightDarkAccent'),
          elevation: 2,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: 'Tài liệu',
            ),
            NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake_rounded),
              label: 'Quản lý mượn',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Mượn tài liệu',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map_rounded),
              label: 'Bản đồ',
            ),
          ],
        ),
      ),
    );
  }
}
