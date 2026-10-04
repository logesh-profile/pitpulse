import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/health_remote_data_source.dart';
import '../../data/models/health_response_model.dart';

enum ConnectionStatus { initial, loading, connected, error }

class HealthCheckScreen extends StatefulWidget {
  final HealthRemoteDataSource dataSource;

  const HealthCheckScreen({super.key, required this.dataSource});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  ConnectionStatus _status = ConnectionStatus.initial;
  HealthResponseModel? _healthData;
  String? _errorMessage;
  late final TextEditingController _urlController;
  bool _isEditingUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.dataSource.apiClient.baseUrl);
    // Trigger real backend verification on startup
    _checkBackendHealth();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkBackendHealth() async {
    setState(() {
      _status = ConnectionStatus.loading;
      _errorMessage = null;
      _healthData = null;
    });

    try {
      final data = await widget.dataSource.checkHealth();
      if (mounted) {
        setState(() {
          _status = ConnectionStatus.connected;
          _healthData = data;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = ConnectionStatus.error;
          _healthData = null;
          if (e is Failure) {
            _errorMessage = e.message;
          } else {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  void _applyCustomUrl() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      widget.dataSource.apiClient.updateBaseUrl(newUrl);
      setState(() {
        _isEditingUrl = false;
      });
      _checkBackendHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PitPulse — System Status'),
        actions: [
          IconButton(
            icon: Icon(_isEditingUrl ? Icons.close : Icons.settings_ethernet),
            tooltip: 'Configure Backend URL',
            onPressed: () {
              setState(() {
                _isEditingUrl = !_isEditingUrl;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _status == ConnectionStatus.loading ? null : _checkBackendHealth,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Endpoint configuration banner (collapsible)
              if (_isEditingUrl) _buildUrlConfigCard(theme),
              const SizedBox(height: 12),

              // Main Status Display Card
              _buildMainStatusCard(theme),
              const SizedBox(height: 20),

              // Diagnostic Details Card (if connected or error)
              if (_status == ConnectionStatus.connected && _healthData != null)
                _buildConnectedDetailsCard(theme, _healthData!),

              if (_status == ConnectionStatus.error)
                _buildErrorCard(theme),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _status == ConnectionStatus.loading ? null : _checkBackendHealth,
                icon: _status == ConnectionStatus.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _status == ConnectionStatus.loading
                      ? 'Connecting to PitPulse backend...'
                      : 'Test Connection Again',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlConfigCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend Host Configuration',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Android Emulator default: http://10.0.2.2:8000\nPhysical Device (LAN): http://<YOUR_PC_LAN_IP>:8000\nLocal Desktop: http://127.0.0.1:8000',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base API URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _applyCustomUrl,
                child: const Text('Save & Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatusCard(ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    switch (_status) {
      case ConnectionStatus.initial:
      case ConnectionStatus.loading:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        statusTitle = 'Connecting to PitPulse backend...';
        statusSubtitle = 'Performing real HTTP health probe';
        break;
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'Connected';
        statusSubtitle = 'Real FastAPI Backend Online';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = 'Unable to connect';
        statusSubtitle = 'Failed to establish HTTP communication';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(statusIcon, size: 64, color: statusColor),
          const SizedBox(height: 16),
          Text(
            'Backend Status',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusTitle,
            key: const Key('backend_status_text'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            statusSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.dataSource.apiClient.baseUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDetailsCard(ThemeData theme, HealthResponseModel data) {
    return Card(
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
                const Icon(Icons.verified, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Verified Runtime Metadata',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDataRow('Service', data.service),
            _buildDataRow('Status Payload', data.status),
            _buildDataRow('Backend Version', data.version),
            _buildDataRow('Environment', data.environment),
            _buildDataRow('Server Timestamp (UTC)', data.timestamp),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 22),
                const SizedBox(width: 8),
                Text(
                  'Diagnostic Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Unknown communication error.',
              style: TextStyle(color: Colors.red[800], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Troubleshooting:\n• Is FastAPI running on port 8000?\n• If using Android emulator, ensure host is http://10.0.2.2:8000.\n• If using desktop/web, ensure host is http://127.0.0.1:8000.',
              style: TextStyle(color: Colors.grey[800], fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
