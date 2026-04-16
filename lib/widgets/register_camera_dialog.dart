import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../config/locations.dart';

class RegisterCameraDialog extends StatefulWidget {
  const RegisterCameraDialog({super.key});

  @override
  State<RegisterCameraDialog> createState() => _RegisterCameraDialogState();
}

class _RegisterCameraDialogState extends State<RegisterCameraDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cameraNameController = TextEditingController();
  final _ipAddressController = TextEditingController();

  String? _selectedLocation;
  bool _isSubmitting = false;
  String? _error;

  final List<String> _locations = kCameraLocations;

  @override
  void dispose() {
    _cameraNameController.dispose();
    _ipAddressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final camera = await ApiService.registerCamera(
      cameraName: _cameraNameController.text.trim(),
      location: _selectedLocation!,
      ipAddress: _ipAddressController.text.trim(),
      status: 'ONLINE',
    );

    if (!mounted) return;

    if (camera == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to register camera. Please try again.';
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Register Camera',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textMuted,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cameraNameController,
                decoration: const InputDecoration(
                  labelText: 'Camera Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Camera name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
                items:
                    _locations
                        .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                        .toList(),
                onChanged:
                    _isSubmitting ? null : (value) => setState(() => _selectedLocation = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipAddressController,
                decoration: const InputDecoration(
                  labelText: 'Camera IP / Stream Source',
                  hintText: 'e.g. 0 or rtsp://...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'IP/stream source is required';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.alertHigh, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
