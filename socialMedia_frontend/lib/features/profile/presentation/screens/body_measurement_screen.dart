import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BodyMeasurementScreen extends StatefulWidget {
  const BodyMeasurementScreen({super.key});

  @override
  State<BodyMeasurementScreen> createState() => _BodyMeasurementScreenState();
}

class _BodyMeasurementScreenState extends State<BodyMeasurementScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bustCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipsCtrl = TextEditingController();

  bool _isEditing = true;
  bool _hasSavedData = false;

  @override
  void initState() {
    super.initState();
    // Simulate checking if we already have data
    // If we do, we would set _isEditing = false and _hasSavedData = true
  }

  void _save() {
    setState(() {
      _isEditing = false;
      _hasSavedData = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurements saved for AI algorithms!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _delete() {
    setState(() {
      _heightCtrl.clear();
      _weightCtrl.clear();
      _bustCtrl.clear();
      _waistCtrl.clear();
      _hipsCtrl.clear();
      _isEditing = true;
      _hasSavedData = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurements deleted.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force dark background always as requested
    const bgColor = Color(0xFF121212);
    const surfaceColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('Body Measurements',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_hasSavedData && !_isEditing)
            IconButton(
              icon:
                  const Icon(Icons.edit_rounded, color: AppTheme.accentViolet),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
          if (_hasSavedData)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorColor),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These details help our AI Stylist and Social Media algorithms recommend the best outfits for your unique body shape.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildField(
                'Height (cm)', _heightCtrl, Icons.height_rounded, surfaceColor),
            _buildField('Weight (kg)', _weightCtrl,
                Icons.monitor_weight_rounded, surfaceColor),
            _buildField(
                'Bust (cm)', _bustCtrl, Icons.straighten_rounded, surfaceColor),
            _buildField('Waist (cm)', _waistCtrl, Icons.straighten_rounded,
                surfaceColor),
            _buildField(
                'Hips (cm)', _hipsCtrl, Icons.straighten_rounded, surfaceColor),
            const SizedBox(height: 32),
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentViolet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _save,
                  child: const Text('Save Measurements',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      IconData icon, Color surfaceColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          filled: true,
          fillColor: surfaceColor,
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.accentViolet, width: 2),
          ),
        ),
      ),
    );
  }
}
