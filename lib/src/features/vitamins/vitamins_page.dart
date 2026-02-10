import 'package:flutter/material.dart';
import 'package:med_shakthi/src/features/category/category_products_page.dart';

class VitaminsPage extends StatefulWidget {
  const VitaminsPage({super.key});

  @override
  State<VitaminsPage> createState() => _VitaminsPageState();
}

class _VitaminsPageState extends State<VitaminsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Vitamins & Supplements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF9800),
                      const Color(0xFFFF6F00),
                      Colors.orange.shade700,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    // Sun/Vitamin icon
                    Center(
                      child: Icon(
                        Icons.wb_sunny,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF9800),
                unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                indicatorColor: const Color(0xFFFF9800),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Categories'),
                  Tab(text: 'Benefits'),
                  Tab(text: 'Popular'),
                ],
              ),
            ),
          ),

          // Tab Bar View Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(theme, isDark),
                _buildBenefitsTab(theme, isDark),
                _buildPopularTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Categories Tab
  Widget _buildCategoriesTab(ThemeData theme, bool isDark) {
    final categories = [
      VitaminCategory(
        title: 'Multivitamins',
        icon: Icons.medication,
        color: Colors.orange,
        description: 'Complete daily nutrition',
        productCount: 85,
      ),
      VitaminCategory(
        title: 'Vitamin D',
        icon: Icons.wb_sunny,
        color: Colors.amber,
        description: 'Bone health & immunity',
        productCount: 45,
      ),
      VitaminCategory(
        title: 'Vitamin C',
        icon: Icons.local_drink,
        color: Colors.deepOrange,
        description: 'Immune system support',
        productCount: 60,
      ),
      VitaminCategory(
        title: 'Omega-3',
        icon: Icons.water,
        color: Colors.blue,
        description: 'Heart & brain health',
        productCount: 40,
      ),
      VitaminCategory(
        title: 'Protein Supplements',
        icon: Icons.fitness_center,
        color: Colors.red,
        description: 'Muscle growth & recovery',
        productCount: 95,
      ),
      VitaminCategory(
        title: 'Calcium',
        icon: Icons.health_and_safety,
        color: Colors.teal,
        description: 'Strong bones & teeth',
        productCount: 35,
      ),
      VitaminCategory(
        title: 'Iron',
        icon: Icons.bloodtype,
        color: Colors.redAccent,
        description: 'Energy & blood health',
        productCount: 30,
      ),
      VitaminCategory(
        title: 'B-Complex',
        icon: Icons.energy_savings_leaf,
        color: Colors.green,
        description: 'Energy & metabolism',
        productCount: 50,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, theme, isDark);
      },
    );
  }

  Widget _buildCategoryCard(VitaminCategory category, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductsPage(categoryName: category.title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      category.color.withValues(alpha: 0.8),
                      category.color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  category.icon,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${category.productCount} products',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: category.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.iconTheme.color?.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Benefits Tab
  Widget _buildBenefitsTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Essential Vitamins
          _buildSectionTitle('Essential Vitamins', theme),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Vitamin A',
            'Supports vision, immune function, and skin health',
            Icons.visibility,
            Colors.purple,
            ['Carrots', 'Sweet potatoes', 'Spinach'],
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Vitamin C',
            'Boosts immunity, aids wound healing, antioxidant',
            Icons.shield,
            Colors.orange,
            ['Citrus fruits', 'Berries', 'Bell peppers'],
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Vitamin D',
            'Strengthens bones, supports immune system',
            Icons.wb_sunny,
            Colors.amber,
            ['Sunlight', 'Fatty fish', 'Fortified milk'],
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Vitamin E',
            'Protects cells, supports skin and eye health',
            Icons.favorite,
            Colors.red,
            ['Nuts', 'Seeds', 'Vegetable oils'],
            theme,
            isDark,
          ),
          const SizedBox(height: 24),

          // Minerals
          _buildSectionTitle('Essential Minerals', theme),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Calcium',
            'Builds strong bones and teeth, muscle function',
            Icons.health_and_safety,
            Colors.teal,
            ['Dairy products', 'Leafy greens', 'Fortified foods'],
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Iron',
            'Carries oxygen in blood, prevents anemia',
            Icons.bloodtype,
            Colors.redAccent,
            ['Red meat', 'Beans', 'Fortified cereals'],
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            'Magnesium',
            'Supports muscle and nerve function, energy production',
            Icons.bolt,
            Colors.green,
            ['Nuts', 'Whole grains', 'Dark chocolate'],
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> sources,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.8),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Food Sources:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((source) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  source,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Popular Tab
  Widget _buildPopularTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Trending Supplements', theme),
          const SizedBox(height: 16),
          
          // Grid of popular supplements
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildPopularCard(
                'Multivitamin',
                'Daily Complete',
                Icons.medication,
                Colors.orange,
                '₹599',
                4.8,
                theme,
                isDark,
              ),
              _buildPopularCard(
                'Omega-3',
                'Fish Oil 1000mg',
                Icons.water,
                Colors.blue,
                '₹899',
                4.7,
                theme,
                isDark,
              ),
              _buildPopularCard(
                'Vitamin D3',
                '2000 IU',
                Icons.wb_sunny,
                Colors.amber,
                '₹399',
                4.9,
                theme,
                isDark,
              ),
              _buildPopularCard(
                'Protein Powder',
                'Whey Isolate',
                Icons.fitness_center,
                Colors.red,
                '₹2,499',
                4.6,
                theme,
                isDark,
              ),
              _buildPopularCard(
                'Calcium + D3',
                'Bone Support',
                Icons.health_and_safety,
                Colors.teal,
                '₹499',
                4.5,
                theme,
                isDark,
              ),
              _buildPopularCard(
                'B-Complex',
                'Energy Boost',
                Icons.energy_savings_leaf,
                Colors.green,
                '₹349',
                4.7,
                theme,
                isDark,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Why Choose Supplements?', theme),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Fill Nutritional Gaps',
            'Even with a balanced diet, it can be challenging to get all nutrients',
            Icons.restaurant_menu,
            Colors.green,
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Boost Immunity',
            'Strengthen your immune system with essential vitamins and minerals',
            Icons.shield,
            Colors.blue,
            theme,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Increase Energy',
            'Combat fatigue and maintain optimal energy levels throughout the day',
            Icons.bolt,
            Colors.orange,
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String price,
    double rating,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryProductsPage(categoryName: 'Vitamins'),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 35),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String description,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.1),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.titleLarge?.color,
      ),
    );
  }
}

// Helper class for categories
class VitaminCategory {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final int productCount;

  VitaminCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.productCount,
  });
}

// Custom delegate for pinned tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
