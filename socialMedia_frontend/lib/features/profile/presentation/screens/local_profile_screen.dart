import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LocalProfileScreen extends ConsumerWidget {
  const LocalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.currentUserId ?? "Unknown ID";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Account Info',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 50, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Personal Information',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Username', value: 'DemoUser'),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _InfoRow(label: 'Email', value: 'demo@spot.com'),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _InfoRow(label: 'User ID', value: userId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
