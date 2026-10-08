import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';
import '../theme/maatra_theme.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String downloadUrl;
  final String releaseNotes;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      minSupportedVersion: json['min_supported_version'] as String? ?? '1.0.0',
      forceUpdate: json['force_update'] as bool? ?? false,
      downloadUrl: json['download_url'] as String? ?? 'https://github.com/logesh-profile/pitpulse',
      releaseNotes: json['release_notes'] as String? ?? 'Performance improvements and bug fixes.',
    );
  }
}

class VersionCheckService {
  static const String currentAppVersion = '1.0.0';
  static bool _hasCheckedThisSession = false;

  /// Compares two semver strings (e.g. "1.0.0" < "1.0.1").
  static bool isVersionLower(String current, String target) {
    try {
      final currentParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final targetParts = target.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (targetParts.length < 3) {
        targetParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < targetParts[i]) return true;
        if (currentParts[i] > targetParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Non-blocking check for available updates.
  /// If an update is detected, presents a clean, themed update modal.
  /// Fully failsafe: times out in 3s and silently falls back on any network error.
  static Future<void> checkAndPrompt(BuildContext context, {ApiClient? apiClient, bool manualCheck = false}) async {
    if (!manualCheck && _hasCheckedThisSession) return;
    if (!manualCheck) _hasCheckedThisSession = true;

    try {
      final client = apiClient ?? ApiClient.instance;
      final dio = Dio(
        BaseOptions(
          baseUrl: client.baseUrl,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      final response = await dio.get('/api/v1/system/app-version');
      if (response.statusCode != 200 || response.data == null) {
        if (manualCheck && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not verify updates at this time.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
              backgroundColor: MaatraTheme.cardDark,
            ),
          );
        }
        return;
      }

      final data = response.data as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(data);

      final isOutdated = isVersionLower(currentAppVersion, updateInfo.latestVersion);
      final isMandatory = updateInfo.forceUpdate || isVersionLower(currentAppVersion, updateInfo.minSupportedVersion);

      if (isOutdated || isMandatory) {
        if (!context.mounted) return;
        _showUpdateDialog(context, updateInfo, isMandatory);
      } else if (manualCheck && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'MAATRA is up to date (v$currentAppVersion).',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: MaatraTheme.cardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('[VersionCheckService] Check completed quietly: $e');
      if (manualCheck && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not reach server to check for updates.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: MaatraTheme.cardDark,
          ),
        );
      }
    }
  }

  static void _showUpdateDialog(BuildContext context, AppUpdateInfo info, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (dialogCtx) => PopScope(
        canPop: !isMandatory,
        child: AlertDialog(
          backgroundColor: MaatraTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMandatory ? 'Update Required' : 'New Version Ready',
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v$currentAppVersion  ➔  v${info.latestVersion}',
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.accentLilac,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                isMandatory
                    ? 'A critical update is required to continue using MAATRA with the latest clinical features and security enhancements.'
                    : 'A new version of MAATRA is available with improved performance and clinical refinements.',
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MaatraTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MaatraTheme.borderMuted),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WHAT'S NEW",
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.textTertiary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.releaseNotes,
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Later',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Update Now',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  final uri = Uri.parse(info.downloadUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('[VersionCheckService] Failed to launch update URL: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
