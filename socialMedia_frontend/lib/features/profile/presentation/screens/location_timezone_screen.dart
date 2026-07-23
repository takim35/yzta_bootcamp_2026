import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

class LocationTimezoneScreen extends ConsumerStatefulWidget {
  const LocationTimezoneScreen({super.key});

  @override
  ConsumerState<LocationTimezoneScreen> createState() => _LocationTimezoneScreenState();
}

class _LocationTimezoneScreenState extends ConsumerState<LocationTimezoneScreen> {
  String _selectedCountry = '';
  String _selectedTimezone = '';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(profileProvider).user;
      if (user != null) {
        setState(() {
          _selectedCountry = user.location;
          _selectedTimezone = user.timezone;
        });
      }
    });
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        textStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
        searchTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
        _save();
      },
    );
  }

  void _pickTimezone() {
    final timezones = tz.timeZoneDatabase.locations.keys.toList();
    timezones.sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Timezone',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: timezones.length,
                itemBuilder: (context, index) {
                  final t = timezones[index];
                  return ListTile(
                    title: Text(
                      t,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTimezone = t;
                      });
                      _save();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(profileProvider).updateProfile(
            location: _selectedCountry,
            timezone: _selectedTimezone,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Location & Timezone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us tailor your experience by setting your location and timezone.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            _buildSelectionTile(
              label: 'Country/Location',
              value: _selectedCountry.isEmpty ? 'Select Country' : _selectedCountry,
              icon: Icons.public_rounded,
              onTap: _pickCountry,
            ),
            const SizedBox(height: 16),
            _buildSelectionTile(
              label: 'Timezone',
              value: _selectedTimezone.isEmpty ? 'Select Timezone' : _selectedTimezone,
              icon: Icons.access_time_rounded,
              onTap: _pickTimezone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentViolet, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                 const SizedBox(height: 4),
                 Text(
                   value,
                   style: TextStyle(
                     color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
