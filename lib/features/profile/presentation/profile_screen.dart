import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/persistent_bottom_nav_bar.dart';

final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();

      String finalUsername;
      final currentUsername = data['username'] as String?;
      if (currentUsername == null || currentUsername.isEmpty) {
        finalUsername = 'user_${userId.substring(0, 8)}';
        await supabase.from('profiles').update({'username': finalUsername}).eq('id', userId);
      } else {
        finalUsername = currentUsername;
      }

      final baseUrl = data['avatar_url'] as String?;
      String? finalAvatarUrl;
      if (baseUrl != null && baseUrl.isNotEmpty) {
        // Add a timestamp to the URL to bypass the cache.
        finalAvatarUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }
      
      if(mounted) {
          setState(() {
            _username = finalUsername;
            _avatarUrl = finalAvatarUrl;
          });
      }

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditUsernameDialog() async {
    final newUsernameController = TextEditingController(text: _username);
    final formKey = GlobalKey<FormState>();
    String? validationError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Username'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: newUsernameController,
                autofocus: true,
                decoration: InputDecoration(hintText: 'Enter new username', errorText: validationError),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Username cannot be empty';
                  if (value.length < 4) return 'Must be at least 4 characters';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final newUsername = newUsernameController.text.trim();
                  if (newUsername == _username) {
                    Navigator.of(context).pop();
                    return;
                  }

                  final userId = supabase.auth.currentUser!.id;
                  // Check if username is taken by ANOTHER user
                  final response = await supabase
                      .from('profiles')
                      .select()
                      .eq('username', newUsername)
                      .neq('id', userId) // Exclude current user from the check
                      .limit(1);

                  if (response.isNotEmpty) {
                    setState(() => validationError = 'Username is already taken');
                    return;
                  }

                  // Username is available, proceed with the update
                  await supabase.from('profiles').update({'username': newUsername}).eq('id', userId);

                  this.setState(() {
                    _username = newUsername;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _onUploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (imageFile == null) return;

    // Cropping step
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioLockEnabled: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(croppedFile.path);
      final fileExt = croppedFile.path.split('.').last;
      final fileName = '$userId/avatar.$fileExt';

      await supabase.storage.from('avatars').upload(fileName, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
      
      // Get the base URL without any timestamps
      final baseUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      
      // Update the profile with the clean base URL
      await supabase.from('profiles').update({'avatar_url': baseUrl}).eq('id', userId);

      if (mounted) {
        // Create a unique URL for display to force the image to reload
        final displayUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        setState(() => _avatarUrl = displayUrl);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading avatar: $error'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkPitch,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _getProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildUserInfoCard(context),
                            const SizedBox(height: 24),
                            _buildStatsSection(context),
                            const SizedBox(height: 24),
                            _buildLogoutButton(context),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
            ),
            const PersistentBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCardSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Avatar(imageUrl: _avatarUrl, onUpload: _onUploadAvatar),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _username ?? '...',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                onPressed: () => _showEditUsernameDialog(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.brightGold, size: 24),
              const SizedBox(width: 8),
              Text(
                '0 Points', // Placeholder
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.brightGold, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.white)),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: _StatChip(icon: Icons.games_rounded, label: 'Games', value: '0', color: AppColors.gameOnGreen)),
            SizedBox(width: 12),
            Expanded(child: _StatChip(icon: Icons.trending_up_rounded, label: 'Wins', value: '0', color: AppColors.brightGold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await supabase.auth.signOut();
          if (mounted) context.go('/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red.withOpacity(0.2),
          foregroundColor: AppColors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.red, width: 2),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded),
            const SizedBox(width: 8),
            Text('Logout', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final void Function() onUpload;

  const Avatar({super.key, this.imageUrl, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gameOnGreen.withOpacity(0.2),
              border: Border.all(color: AppColors.gameOnGreen, width: 3),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      key: ValueKey(imageUrl!), // Add a key to force rebuild
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: AppColors.gameOnGreen),
                    )
                  : const Icon(Icons.person, size: 50, color: AppColors.gameOnGreen),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.darkCard, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.lightGrey)),
        ],
      ),
    );
  }
}
