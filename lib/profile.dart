import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<MobileProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AurexApiClient.fetchProfile();
  }

  void _reload() {
    setState(() {
      _profileFuture = AurexApiClient.fetchProfile();
    });
  }

  Future<void> _editProfile(MobileProfile profile) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _ProfileColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProfileSheet(profile: profile),
    );

    if (updated == true) {
      _reload();
    }
  }

  Future<void> _changePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      await AurexApiClient.uploadProfilePhoto(image.path);
      if (!mounted) return;

      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully.')),
      );
    } on AurexApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            FutureBuilder<MobileProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    profile == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _ProfileColors.softGold,
                    ),
                  );
                }

                if (snapshot.hasError && profile == null) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }

                return RefreshIndicator(
                  color: _ProfileColors.gold,
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 54, 24, 126),
                    children: [
                      const _TopBar(),
                      const SizedBox(height: 26),
                      _ProfileHero(
                        profile: profile!,
                        onEdit: () => _editProfile(profile),
                        onPhotoEdit: _changePhoto,
                      ),
                      const SizedBox(height: 28),
                      _ProfileStats(profile: profile),
                      const SizedBox(height: 28),
                      _CompletionCard(percent: profile.completionPercent),
                      const SizedBox(height: 22),
                      _DetailsPanel(profile: profile),
                      const SizedBox(height: 22),
                      _SettingsPanel(onEdit: () => _editProfile(profile)),
                      const SizedBox(height: 22),
                      const _LogoutButton(),
                    ],
                  ),
                );
              },
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(currentIndex: 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Image.asset(
          'assets/images/placeholder.png',
          width: 176,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 31,
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.onEdit,
    required this.onPhotoEdit,
  });

  final MobileProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onPhotoEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _ProfileColors.gold,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _AvatarImage(url: profile.profilePhotoUrl),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: _ProfileColors.softGold,
                child: IconButton(
                  tooltip: 'Edit profile',
                  onPressed: onPhotoEdit,
                  icon: const Icon(Icons.edit, color: Colors.black, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfileColors.muted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _LevelBadge(label: profile.workoutLevel),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _AvatarFallback(),
      );
    }

    return Image.asset(
      'assets/images/profile_avatar.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _AvatarFallback(),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.person, color: _ProfileColors.gold, size: 72),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.accessibility_new_rounded,
            color: _ProfileColors.gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProfileColors.softGold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calendar_month, 'Member Since', _display(profile.memberSince)),
      (Icons.height, 'Height', _unit(profile.heightCm, 'cm')),
      (Icons.monitor_weight_outlined, 'Weight', _unit(profile.weightKg, 'kg')),
      (Icons.track_changes_rounded, 'Goal', _display(profile.fitnessGoal)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 18,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Row(
                  children: [
                    Icon(item.$1, color: _ProfileColors.gold, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ProfileColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: _panelDecoration(highlight: true),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(color: Colors.white, fontSize: 19),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percent% Complete',
                  style: const TextStyle(
                    color: _ProfileColors.softGold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 12,
                backgroundColor: const Color(0xFF313131),
                valueColor: const AlwaysStoppedAnimation(
                  _ProfileColors.softGold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Phone', profile.phone),
      ('Gender', profile.gender),
      ('Date of Birth', profile.dateOfBirth),
      ('Address', profile.address),
      ('Emergency Contact', profile.emergencyName),
      ('Emergency Phone', profile.emergencyPhone),
    ];

    return Container(
      decoration: _panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(label: rows[i].$1, value: _display(rows[i].$2)),
            if (i < rows.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: _ProfileColors.muted, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      child: _SettingsRow(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Update personal details, height, weight and goals',
        onTap: onEdit,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Row(
          children: [
            Icon(icon, color: _ProfileColors.gold, size: 34),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ProfileColors.muted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: _ProfileColors.muted,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final MobileProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _address;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyRelationship;
  late final TextEditingController _emergencyPhone;
  late String _gender;
  late String _goal;
  late String _level;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.fullName);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
    _dob = TextEditingController(text: profile.dateOfBirth);
    _address = TextEditingController(text: profile.address);
    _height = TextEditingController(text: profile.heightCm);
    _weight = TextEditingController(text: profile.weightKg);
    _emergencyName = TextEditingController(text: profile.emergencyName);
    _emergencyRelationship = TextEditingController(
      text: profile.emergencyRelationship,
    );
    _emergencyPhone = TextEditingController(text: profile.emergencyPhone);
    _gender = _option(profile.gender, const ['', 'Male', 'Female']);
    _goal = _option(profile.fitnessGoal, const [
      '',
      'Weight Loss',
      'Muscle Gain',
      'Strength',
      'General Fitness',
    ]);
    _level = _option(profile.workoutLevel, const [
      '',
      'Beginner',
      'Intermediate',
      'Advanced',
    ]);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _height.dispose();
    _weight.dispose();
    _emergencyName.dispose();
    _emergencyRelationship.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _saving = true);

    try {
      await AurexApiClient.updateProfile({
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'gender': _emptyToNull(_gender),
        'date_of_birth': _emptyToNull(_dob.text),
        'address': _emptyToNull(_address.text),
        'height_cm': _intOrNull(_height.text),
        'weight_kg': _intOrNull(_weight.text),
        'fitness_goal': _emptyToNull(_goal),
        'workout_level': _emptyToNull(_level),
        'emergency_contact_name': _emptyToNull(_emergencyName.text),
        'emergency_contact_relationship': _emptyToNull(
          _emergencyRelationship.text,
        ),
        'emergency_contact_phone': _emptyToNull(_emergencyPhone.text),
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } on AurexApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final initialDate = DateTime.tryParse(_dob.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _ProfileColors.softGold,
              onPrimary: Colors.black,
              surface: _ProfileColors.panel,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) {
      return;
    }

    _dob.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Field(controller: _name, label: 'Full Name', required: true),
              _Field(
                controller: _email,
                label: 'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),
              _Field(
                controller: _phone,
                label: 'Phone',
                required: true,
                keyboardType: TextInputType.phone,
              ),
              Row(
                children: [
                  Expanded(
                    child: _MenuField(
                      label: 'Gender',
                      value: _gender,
                      items: const ['', 'Male', 'Female'],
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _dob,
                      label: 'Date of Birth',
                      hint: 'YYYY-MM-DD',
                      readOnly: true,
                      suffixIcon: Icons.calendar_month,
                      onTap: _pickDateOfBirth,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _height,
                      label: 'Height (cm)',
                      keyboardType: TextInputType.number,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _weight,
                      label: 'Weight (kg)',
                      keyboardType: TextInputType.number,
                      numeric: true,
                    ),
                  ),
                ],
              ),
              _MenuField(
                label: 'Fitness Goal',
                value: _goal,
                items: const [
                  '',
                  'Weight Loss',
                  'Muscle Gain',
                  'Strength',
                  'General Fitness',
                ],
                onChanged: (value) => setState(() => _goal = value),
              ),
              _MenuField(
                label: 'Workout Level',
                value: _level,
                items: const ['', 'Beginner', 'Intermediate', 'Advanced'],
                onChanged: (value) => setState(() => _level = value),
              ),
              _Field(controller: _address, label: 'Address', maxLines: 2),
              _Field(
                controller: _emergencyName,
                label: 'Emergency Contact Name',
              ),
              _Field(
                controller: _emergencyRelationship,
                label: 'Emergency Contact Relationship',
              ),
              _Field(
                controller: _emergencyPhone,
                label: 'Emergency Contact Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ProfileColors.softGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _saving ? 'SAVING...' : 'SAVE PROFILE',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.numeric = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool numeric;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) {
            return '$label is required';
          }
          if (numeric && text.isNotEmpty && int.tryParse(text) == null) {
            return 'Enter a valid number';
          }
          if (label == 'Email' && text.isNotEmpty && !text.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
        decoration: _inputDecoration(label, hint).copyWith(
          suffixIcon: suffixIcon == null
              ? null
              : Icon(suffixIcon, color: _ProfileColors.softGold),
        ),
      ),
    );
  }
}

class _MenuField extends StatelessWidget {
  const _MenuField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: _ProfileColors.panel,
        iconEnabledColor: _ProfileColors.softGold,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, null),
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(item.isEmpty ? 'Not set' : item),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: _ProfileColors.gold,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF5A4F),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout, size: 24),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, String? hint) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: _ProfileColors.muted),
    hintStyle: const TextStyle(color: _ProfileColors.muted),
    errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _ProfileColors.gold),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
    ),
  );
}

BoxDecoration _panelDecoration({bool highlight = false}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: highlight
          ? _ProfileColors.gold.withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.16),
    ),
  );
}

String _display(String value) => value.trim().isEmpty ? 'Not set' : value;

String _unit(String value, String unit) {
  final text = value.trim();
  return text.isEmpty ? 'Not set' : '$text $unit';
}

String _option(String value, List<String> options) {
  return options.contains(value) ? value : '';
}

String? _emptyToNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int? _intOrNull(String value) {
  final text = value.trim();
  return text.isEmpty ? null : int.tryParse(text);
}

class _ProfileColors {
  const _ProfileColors._();

  static const black = Color(0xFF030303);
  static const panel = Color(0xFF141414);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
