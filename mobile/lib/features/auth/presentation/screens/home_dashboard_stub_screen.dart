import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../../../health_check/data/datasources/health_remote_data_source.dart';
import '../../../health_check/presentation/screens/health_check_screen.dart';

class HomeDashboardStubScreen extends StatelessWidget {
  final AuthController authController;

  const HomeDashboardStubScreen({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = authController.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user session.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PitPulse Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined),
            tooltip: 'System Health Check',
            onPressed: () {
              final healthDs = HealthRemoteDataSourceImpl(apiClient: authController.apiClient);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HealthCheckScreen(dataSource: healthDs)),
              );
            },
          ),
          IconButton(
            key: const Key('logout_icon_button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to sign out of your session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authController.logout();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User profile card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleBadge(user.role),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Authenticated session metadata
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'PostgreSQL Session Verified',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildDetailRow('User UUID', user.id),
                      _buildDetailRow('Phone Number', user.phone ?? 'Not provided'),
                      _buildDetailRow('Account Status', user.isActive ? 'ACTIVE' : 'INACTIVE'),
                      _buildDetailRow('Registered At', user.createdAt),
                      _buildDetailRow('Active Token', 'Secure JWT (Encrypted Keystore)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action button to test logout
              OutlinedButton.icon(
                key: const Key('logout_button'),
                onPressed: () => authController.logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out Session'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;

    switch (role.toUpperCase()) {
      case 'DOCTOR':
        bg = Colors.blue[100]!;
        fg = Colors.blue[900]!;
        break;
      case 'ASHA':
        bg = Colors.purple[100]!;
        fg = Colors.purple[900]!;
        break;
      case 'ADMIN':
        bg = Colors.red[100]!;
        fg = Colors.red[900]!;
        break;
      case 'PATIENT':
      default:
        bg = Colors.teal[100]!;
        fg = Colors.teal[900]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
