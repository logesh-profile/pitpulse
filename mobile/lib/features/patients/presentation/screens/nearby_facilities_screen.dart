import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../../data/models/healthcare_facility.dart';
import '../../services/offline_hospital_locator_service.dart';

class NearbyFacilitiesScreen extends StatefulWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  final OfflineHospitalLocatorService _locatorService = OfflineHospitalLocatorService();
  final TextEditingController _searchController = TextEditingController();

  Position? _currentPosition;
  bool _isLoadingGps = false;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshGpsPosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshGpsPosition() async {
    setState(() => _isLoadingGps = true);
    final pos = await _locatorService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _isLoadingGps = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot initiate cellular call to $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone call error. Dial directly: $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openDirections(HealthcareFacility facility) async {
    final geoUri = Uri.parse('geo:${facility.latitude},${facility.longitude}?q=${facility.latitude},${facility.longitude}(${Uri.encodeComponent(facility.name)})');
    final webMapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${facility.latitude},${facility.longitude}');

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
      } else if (await canLaunchUrl(webMapsUri)) {
        await launchUrl(webMapsUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No maps application found on device')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to launch navigation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? currentLat = _currentPosition?.latitude;
    final double? currentLon = _currentPosition?.longitude;

    final facilities = _locatorService.getNearbyFacilities(
      currentLat: currentLat,
      currentLon: currentLon,
      categoryFilter: _selectedCategory,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      backgroundColor: MaatraTheme.bgIvory,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MaatraTheme.textCharcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nearby Medical Radar',
          style: TextStyle(
            color: MaatraTheme.textCharcoal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoadingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MaatraTheme.brandEmerald),
                  )
                : const Icon(Icons.my_location, color: MaatraTheme.brandEmerald),
            tooltip: 'Refresh Satellite GPS',
            onPressed: _isLoadingGps ? null : _refreshGpsPosition,
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Location Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: MaatraTheme.brandSageWash,
            child: Row(
              children: [
                Icon(
                  _currentPosition != null ? Icons.satellite_alt : Icons.location_searching,
                  size: 16,
                  color: MaatraTheme.brandEmerald,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPosition != null
                        ? 'Satellite GPS Connected • Lat: ${_currentPosition!.latitude.toStringAsFixed(3)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(3)}'
                        : 'Offline Mode • Using Rural Regional Anchor (Pollachi / Anaimalai)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MaatraTheme.brandEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: MaatraTheme.surfacePorcelain,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MaatraTheme.borderHairline),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14, color: MaatraTheme.textCharcoal),
                decoration: InputDecoration(
                  hintText: 'Search hospital, clinic, PHC, or medical shop...',
                  hintStyle: const TextStyle(fontSize: 13, color: MaatraTheme.textQuiet),
                  prefixIcon: const Icon(Icons.search, size: 20, color: MaatraTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: MaatraTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All Facilities', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Govt PHC & GH', 'govt'),
                const SizedBox(width: 8),
                _buildFilterChip('24x7 Delivery Units', 'delivery'),
                const SizedBox(width: 8),
                _buildFilterChip('Medical Shops', 'pharmacy'),
                const SizedBox(width: 8),
                _buildFilterChip('Private Clinics', 'private'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Facilities List
          Expanded(
            child: facilities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 48, color: MaatraTheme.textQuiet),
                        const SizedBox(height: 12),
                        const Text(
                          'No medical facilities found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MaatraTheme.textCharcoal),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try clearing your search query or filter',
                          style: TextStyle(fontSize: 12, color: MaatraTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: facilities.length,
                    itemBuilder: (context, index) {
                      final item = facilities[index];
                      return _buildFacilityCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String categoryKey) {
    final bool isSelected = _selectedCategory == categoryKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? MaatraTheme.brandEmerald : MaatraTheme.surfacePorcelain,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MaatraTheme.brandEmerald : MaatraTheme.borderHairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : MaatraTheme.textCharcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityCard(FacilityWithDistance item) {
    final f = item.facility;

    // Badge styling based on type
    Color badgeBg;
    Color badgeText;
    IconData typeIcon;

    switch (f.type) {
      case FacilityType.govtPhc:
      case FacilityType.fru24x7:
        badgeBg = const Color(0xFFE8F5EF);
        badgeText = const Color(0xFF1B7A58);
        typeIcon = Icons.health_and_safety_outlined;
        break;
      case FacilityType.govtHospital:
        badgeBg = const Color(0xFFE6F0FA);
        badgeText = const Color(0xFF0D529C);
        typeIcon = Icons.local_hospital_outlined;
        break;
      case FacilityType.medicalShop:
        badgeBg = const Color(0xFFFEF5E7);
        badgeText = const Color(0xFFB46A10);
        typeIcon = Icons.medication_outlined;
        break;
      case FacilityType.privateClinic:
        badgeBg = const Color(0xFFF3EFEA);
        badgeText = MaatraTheme.textCharcoal;
        typeIcon = Icons.medical_services_outlined;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaatraTheme.surfacePorcelain,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaatraTheme.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category badge + Distance Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 14, color: badgeText),
                    const SizedBox(width: 6),
                    Text(
                      f.categoryLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MaatraTheme.brandSageWash,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MaatraTheme.brandSage.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${item.distanceDisplay} • ${item.compassDirection}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MaatraTheme.brandEmerald,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Facility Name
          Text(
            f.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MaatraTheme.textCharcoal,
            ),
          ),

          const SizedBox(height: 4),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: MaatraTheme.textQuiet),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  f.address,
                  style: const TextStyle(fontSize: 12, color: MaatraTheme.textMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Operating Hours & 24x7 Tag
          Row(
            children: [
              Icon(
                f.isOpen24x7 ? Icons.alarm_on : Icons.access_time,
                size: 14,
                color: f.isOpen24x7 ? const Color(0xFF1B7A58) : MaatraTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                f.operatingHours,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: f.isOpen24x7 ? FontWeight.w700 : FontWeight.w500,
                  color: f.isOpen24x7 ? const Color(0xFF1B7A58) : MaatraTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Features Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: f.features.map((feature) {
              final isDelivery = feature.toLowerCase().contains('delivery');
              final isBlood = feature.toLowerCase().contains('blood');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDelivery || isBlood
                      ? const Color(0xFFE8F5EF)
                      : MaatraTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDelivery || isBlood
                        ? const Color(0xFF1B7A58)
                        : MaatraTheme.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Call & Directions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MaatraTheme.brandEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text(
                    'Call Casualty / Desk',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _makePhoneCall(f.phone),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: MaatraTheme.textCharcoal,
                  side: const BorderSide(color: MaatraTheme.borderHairline),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.navigation_outlined, size: 16, color: MaatraTheme.brandEmerald),
                label: const Text(
                  'Directions',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _openDirections(f),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
