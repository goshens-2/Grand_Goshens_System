import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../data/admin_service_repository.dart';

class AdminServiceEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? service;

  const AdminServiceEditorScreen({super.key, this.service});

  @override
  ConsumerState<AdminServiceEditorScreen> createState() => _AdminServiceEditorScreenState();
}

class _AdminServiceEditorScreenState extends ConsumerState<AdminServiceEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  bool _isPublished = true;
  bool _isLoading = false;
  String? _serviceId;
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?['name'] ?? '');
    _descController = TextEditingController(text: widget.service?['description'] ?? '');
    _durationController = TextEditingController(text: widget.service?['estimated_duration_minutes']?.toString() ?? '30');
    _isPublished = widget.service?['is_published'] ?? true;
    _serviceId = widget.service?['id'] as String?;
    _imagePaths.addAll(_serviceImagePaths(widget.service ?? {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  List<String> _serviceImagePaths(Map<String, dynamic> service) {
    final paths = <String>[];
    final raw = service['image_paths'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) paths.add(item.trim());
      }
    }
    final cover = service['image_path'] as String?;
    if (cover != null && cover.trim().isNotEmpty && !paths.contains(cover.trim())) {
      paths.insert(0, cover.trim());
    }
    return paths;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    var images = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1600);
    if (images.isEmpty) {
      final single = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
      if (single != null) images = [single];
    }
    if (images.isEmpty) return;

    var serviceId = _serviceId;
    setState(() => _isLoading = true);
    try {
      serviceId ??= await ref.read(adminServiceRepositoryProvider).addService(
            name: _nameController.text.trim().isEmpty ? 'New service' : _nameController.text.trim(),
            description: _descController.text.trim().isEmpty ? 'Description coming soon.' : _descController.text.trim(),
            duration: int.tryParse(_durationController.text) ?? 30,
            isPublished: false,
            imagePaths: _imagePaths,
          );
      _serviceId = serviceId;

      for (final image in images) {
        final bytes = await image.readAsBytes();
        final path = await ref.read(adminServiceRepositoryProvider).uploadServiceImage(
              serviceId: serviceId,
              bytes: Uint8List.fromList(bytes),
              contentType: image.mimeType ?? 'image/jpeg',
            );
        _imagePaths.add(path);
      }
      await ref.read(adminServiceRepositoryProvider).updateService(
            id: serviceId,
            name: _nameController.text.trim().isEmpty ? 'New service' : _nameController.text.trim(),
            description: _descController.text.trim().isEmpty ? 'Description coming soon.' : _descController.text.trim(),
            duration: int.tryParse(_durationController.text) ?? 30,
            isPublished: _isPublished,
            imagePaths: _imagePaths,
          );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload images.\n$error'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_serviceId == null) {
        _serviceId = await ref.read(adminServiceRepositoryProvider).addService(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              duration: int.tryParse(_durationController.text) ?? 30,
              isPublished: _isPublished,
              imagePaths: _imagePaths,
            );
      } else {
        await ref.read(adminServiceRepositoryProvider).updateService(
              id: _serviceId!,
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              duration: int.tryParse(_durationController.text) ?? 30,
              isPublished: _isPublished,
              imagePaths: _imagePaths,
            );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminServiceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add service' : 'Edit service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Estimated Duration (minutes)'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Text('Service images', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._imagePaths.map((path) {
                    final url = repo.publicImageUrl(path);
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: url == null
                              ? Container(width: 88, height: 88, color: AppColors.surfaceVariant)
                              : Image.network(url, width: 88, height: 88, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(Icons.cancel, color: AppColors.error),
                            onPressed: () => setState(() => _imagePaths.remove(path)),
                          ),
                        ),
                      ],
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickImages,
                    icon: Icon(Icons.add_photo_alternate_outlined),
                    label: Text('Add images'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text('Published (Visible to patients)'),
                value: _isPublished,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _isPublished = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveService,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : Text('Save Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
