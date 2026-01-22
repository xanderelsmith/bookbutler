import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_thera/providers/user_provider.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/secure_cache_service.dart';
import '../models/offline_reminder_settings.dart';
import '../providers/serverpod_provider.dart';
import '../providers/reading_goal_provider.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminders = true;
  bool _milestoneNotifications = true;
  bool _weeklySummary = false;
  bool _homeWidgetEnabled = false;
  bool _pinWidgetSupported = false;
  OfflineReminderSettings _reminderSettings =
      OfflineReminderSettings.defaultSettings();

  @override
  void initState() {
    super.initState();
    _loadHomeWidgetEnabled();
    _checkPinWidgetSupport();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final cacheService = SecureCacheService();
    final cached = await cacheService.getReminderSettings();
    if (cached != null && mounted) {
      setState(() {
        _reminderSettings = OfflineReminderSettings.fromJson(cached);
      });
    }
  }

  Future<void> _loadHomeWidgetEnabled() async {
    final service = HomeWidgetService();
    final enabled = await service.isEnabled();
    if (mounted) {
      setState(() {
        _homeWidgetEnabled = enabled;
      });
    }
  }

  Future<void> _checkPinWidgetSupport() async {
    final service = HomeWidgetService();
    final supported = await service.isRequestPinWidgetSupported();
    if (mounted) {
      setState(() {
        _pinWidgetSupported = supported;
      });
    }
  }

  Future<void> _toggleHomeWidget(bool value) async {
    setState(() {
      _homeWidgetEnabled = value;
    });

    final service = HomeWidgetService();
    await service.initialize();
    final success = await service.setEnabled(value);

    if (mounted) {
      if (!success && value) {
        // Widget native setup might be missing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Home widget requires native setup. Widget updates are currently disabled.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _homeWidgetEnabled = false; // Revert toggle if it failed
        });
      } else if (success && value) {
        // Widget enabled successfully - automatically request to pin it
        final pinSupported = await service.isRequestPinWidgetSupported();
        if (pinSupported) {
          // Request to pin widget automatically
          final pinSuccess = await service.requestPinWidget();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  pinSuccess
                      ? 'Widget enabled! Follow the prompts to add it to your home screen.'
                      : 'Widget enabled! Add it from the widgets tab.',
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          // Widget enabled but pinning not supported
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Widget enabled! Add it from the widgets tab on your home screen.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else if (success && !value) {
        // Widget disabled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Home widget disabled'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Failed to toggle
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${value ? 'enable' : 'disable'} home widget',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {
            _homeWidgetEnabled = !value; // Revert toggle
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader('Account'),
          const SizedBox(height: 12),
          Card(
            child: Consumer(
              builder: (context, ref, child) {
                final authUser = ref.watch(userProvider);

                if (authUser == null) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text('Profile'),
                    subtitle: const Text('Sign in to view your profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      if (result == true) {
                        ref.invalidate(authUserProvider);
                      }
                    },
                  );
                }
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                  title: const Text('Profile'),
                  subtitle: const Text('View your account information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive notifications from The Butler'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      if (!value) {
                        _dailyReminders = false;
                        _milestoneNotifications = false;
                        _weeklySummary = false;
                      }
                    });
                  },
                ),
                const Divider(height: 1),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: const Text('Daily Reading Reminders'),
                    subtitle: const Text('Get reminded to read daily'),
                    value: _dailyReminders,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _dailyReminders = value;
                            });
                          }
                        : null,
                  ),
                ),
                const Divider(height: 1),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: const Text('Milestone Notifications'),
                    subtitle: const Text('Celebrate reading achievements'),
                    value: _milestoneNotifications,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            setState(() {
                              _milestoneNotifications = value;
                            });
                          }
                        : null,
                  ),
                ),
                const Divider(height: 1),
                Opacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.5,
                  child: SwitchListTile(
                    title: const Text('Offline Reading Reminder'),
                    subtitle: Text(
                      _reminderSettings.enabled
                          ? 'Remind me daily at ${_reminderSettings.time.format(context)}'
                          : 'Get reminded to read when inactive',
                    ),
                    value: _reminderSettings.enabled,
                    onChanged: _notificationsEnabled
                        ? (value) async {
                            final newSettings = _reminderSettings.copyWith(
                              enabled: value,
                            );
                            setState(() {
                              _reminderSettings = newSettings;
                            });

                            // Save to cache
                            final cacheService = SecureCacheService();
                            await cacheService.saveReminderSettings(
                              newSettings.toJson(),
                            );

                            // Schedule or cancel notification
                            final notificationService = NotificationService();
                            if (value) {
                              await selectTimeDialog(context);
                              await notificationService.scheduleOfflineReminder(
                                _reminderSettings.time,
                              );
                            } else {
                              await notificationService.cancelOfflineReminder();
                            }
                          }
                        : null,
                    secondary:
                        _notificationsEnabled && _reminderSettings.enabled
                        ? IconButton(
                            icon: const Icon(
                              Icons.access_time,
                              color: Colors.blue,
                            ),
                            onPressed: () async {
                              await selectTimeDialog(context);
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Home Widget Settings
          _buildSectionHeader('Home Widget'),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Home Widget'),
              subtitle: Text(
                _pinWidgetSupported
                    ? 'Enable widget and add it to your home screen automatically'
                    : 'Show currently reading book and streak on home screen widget\n(Add from widgets tab)',
              ),
              value: _homeWidgetEnabled,
              onChanged: _toggleHomeWidget,
              secondary: const Icon(Icons.widgets_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Reading Settings
          _buildSectionHeader('Reading Preferences'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final goalAsync = ref.watch(readingGoalProvider);
                    return goalAsync.when(
                      loading: () => const ListTile(
                        leading: Icon(Icons.flag_outlined),
                        title: Text('Yearly Reading Goal'),
                        subtitle: Text('Loading...'),
                        trailing: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('Yearly Reading Goal'),
                        subtitle: const Text('24 books'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showGoalDialog(context, ref, 24),
                      ),
                      data: (goal) => ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text('Yearly Reading Goal'),
                        subtitle: Text('$goal books'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showGoalDialog(context, ref, goal),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Reading Session Defaults'),
                  subtitle: const Text('Auto-start, page tracking'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to session settings
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data & Privacy
          _buildSectionHeader('Data & Privacy'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Sync'),
                  subtitle: const Text('Manage your data backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to backup settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear Data'),
                  subtitle: const Text('Remove all stored books'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showClearDataDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About
          _buildSectionHeader('About'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show terms
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> selectTimeDialog(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderSettings.time,
    );
    if (pickedTime != null) {
      final newSettings = _reminderSettings.copyWith(time: pickedTime);
      setState(() {
        _reminderSettings = newSettings;
      });

      // Save to cache
      final cacheService = SecureCacheService();
      await cacheService.saveReminderSettings(newSettings.toJson());

      // Reschedule notification
      final notificationService = NotificationService();
      await notificationService.scheduleOfflineReminder(pickedTime);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your books and reading data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    final TextEditingController controller = TextEditingController(
      text: currentGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reading Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many books do you want to read this year?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of books',
                hintText: 'Enter goal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final input = controller.text.trim();
              final goal = int.tryParse(input);

              if (goal == null || goal < 1) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number (at least 1)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final service = ref.read(readingGoalServiceProvider);
              final success = await service.setGoal(goal);

              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(readingGoalProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Reading goal updated to $goal books!'
                          : 'Failed to update reading goal',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
