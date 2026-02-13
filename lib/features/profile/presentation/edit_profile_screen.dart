import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_state.dart';
import 'profile_viewmodel.dart';
import 'widgets/profile_action_button.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_text_field.dart';
import 'widgets/sheet_handle.dart';
import '../../pregnancy/presentation/pregnancy_viewmodel.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _weekController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  late final ProviderSubscription<ProfileState> _profileSub;

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileProvider);
    _nameController =
        TextEditingController(text: state.profile?.fullName ?? '');
    _emailController =
        TextEditingController(text: state.profile?.email ?? '');

    _profileSub = ref.listenManual<ProfileState>(
      profileProvider,
      (previous, next) {
      final nextName = next.profile?.fullName ?? '';
      final nextEmail = next.profile?.email ?? '';

      if (_nameController.text != nextName) {
        _nameController.text = nextName;
      }
        if (_emailController.text != nextEmail) {
          _emailController.text = nextEmail;
        }
      },
    );
  }

  @override
  void dispose() {
    _profileSub.close();
    _nameController.dispose();
    _emailController.dispose();
    _weekController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final viewModel = ref.read(profileProvider.notifier);
    final pregnancyState = ref.watch(pregnancyProvider);
    final pregnancyVM = ref.read(pregnancyProvider.notifier);

    final email = state.profile?.email ?? '';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              ProfileHeader(
                name: state.profile?.fullName ?? '',
                email: email,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ProfileActionButton(
                      onPressed: () {},
                      icon: Icons.camera_alt_outlined,
                      label: 'Change Photo',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileActionButton(
                      onPressed: () {},
                      icon: Icons.lock_outline,
                      label: 'Security',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ProfileActionButton(
                      onPressed: () {},
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileActionButton(
                      onPressed: () {},
                      icon: Icons.help_outline,
                      label: 'Help',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ProfileTextField(
                controller: _nameController,
                label: 'Full Name',
              ),
              const SizedBox(height: 16),
              ProfileTextField(
                controller: _emailController,
                label: 'Email',
                readOnly: true,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Enable Pregnancy Mode"),
                value: pregnancyState.isEnabled,
                onChanged: (value) async {
                  if (value) {
                    await showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _weekController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Current Week",
                                ),
                              ),
                              TextField(
                                controller: _dayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Current Day (0-6)",
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  final week =
                                      int.tryParse(_weekController.text);
                                  final day =
                                      int.tryParse(_dayController.text);

                                  if (week == null || day == null) {
                                    return;
                                  }

                                  await pregnancyVM.enablePregnancy(
                                    week: week,
                                    day: day,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text("Save"),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    await pregnancyVM.disablePregnancy();
                  }
                },
              ),
              const SizedBox(height: 20),
              if (state.error != null) ...[
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        await viewModel.updateProfile(
                          _nameController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: state.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
