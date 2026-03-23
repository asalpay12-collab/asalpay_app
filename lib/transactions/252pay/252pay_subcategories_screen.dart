import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/Constant.dart';
import '../../models/category.dart';
import '../../services/252pay_api_service.dart';
import '252pay_search_bar.dart';
import '252pay_screen_background.dart';
import '252pay_products_screen.dart';

class Pay252SubcategoriesScreen extends StatefulWidget {
  const Pay252SubcategoriesScreen({
    super.key,
    required this.walletAccountId,
    required this.selectedCategory,
  });

  final String? walletAccountId;
  final Category selectedCategory;

  @override
  State<Pay252SubcategoriesScreen> createState() =>
      _Pay252SubcategoriesScreenState();
}

class _Pay252SubcategoriesScreenState extends State<Pay252SubcategoriesScreen> {
  final BorderRadius br12 = BorderRadius.circular(12);
  final api = ApiService();
  static String get baseUrl => ApiService.imgURL;

  List<Category> subCategories = [];
  List<Category> filteredSubCategories = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
    searchController.addListener(_applyFilter);
  }

  void _applyFilter() {
    setState(() {
      final q = searchController.text.trim().toLowerCase();
      if (q.isEmpty) {
        filteredSubCategories = List.from(subCategories);
      } else {
        filteredSubCategories = subCategories
            .where((c) => c.subCategoryName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _loadSubCategories() async {
    setState(() => isLoading = true);
    try {
      final fetched =
          await api.fetchSubCategories(widget.selectedCategory.categoryId);
      if (mounted) {
        setState(() {
          subCategories = fetched;
          _applyFilter();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subcategories: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilter);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondryColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: pay252AppBarGradient(),
        ),
        foregroundColor: pureWhite,
        title: Text(
          widget.selectedCategory.categoryName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: pureWhite,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Pay252ScreenBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pay252SearchBar(
                        controller: searchController,
                        hint: 'Search subcategories…',
                        onChanged: (_) => _applyFilter(),
                      ),
                      const SizedBox(height: 16),
                      Pay252SectionHeader(
                        text: 'Subcategories – ${widget.selectedCategory.categoryName}',
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildSubCategoryGrid()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 600 ? 2 : 3;
    if (filteredSubCategories.isEmpty) {
      return Center(
        child: Text(
          subCategories.isEmpty
              ? 'No subcategories available.'
              : 'No subcategories match your search.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: filteredSubCategories.length,
      itemBuilder: (_, idx) {
        final subcat = filteredSubCategories[idx];
        return InkWell(
          borderRadius: br12,
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Pay252ProductsScreen(
                  walletAccountId: widget.walletAccountId,
                  selectedCategory: widget.selectedCategory,
                  selectedSubCategory: subcat,
                ),
              ),
            );
          },
          child: Container(
            decoration: pay252CardDecoration(),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    '$baseUrl/${subcat.imagePath}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image,
                      size: 40,
                      color: secondryColor.withValues(alpha: 0.6),
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: secondryColor,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subcat.subCategoryName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
