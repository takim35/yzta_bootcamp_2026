import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../wardrobe/presentation/screens/ai_stylist_screen.dart';
import '../../../wardrobe/presentation/screens/add_item_screen.dart';

class DashboardScreen extends ConsumerWidget {
  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Good morning, Demo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Here's your outfit summary",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  fontSize: 14,
                ),
              ),
              
              SizedBox(height: 24),

              // AI Stylist Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AiStylistScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Stylist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Get an instant outfit recommendation',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Weather Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '32°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Mostly Sunny',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'feels 31°',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '2% chance of rain',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Pending Outfits Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Outfits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '0 total',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Placeholder for empty outfits
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.checkroom_rounded, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, size: 40),
                    SizedBox(height: 12),
                    Text(
                      "No pending outfits",
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Explore / Social Feed
              Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ExploreCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Add Item',
                      subtitle: 'Add clothes to wardrobe',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddItemScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _ExploreCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Analytics',
                      subtitle: 'Your style stats',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
