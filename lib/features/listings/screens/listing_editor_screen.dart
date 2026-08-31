import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/map_tile_config.dart';
import '../../../core/utils/geohash_helper.dart';
import '../../../models/hospitality_listing.dart';

/// Screen to create or edit a NIP-99 (Kind 30402) Hospitality Hosting Offer
/// featuring a map-based area selector, nostr.build image upload, and tri-state preferences.
class ListingEditorScreen extends ConsumerStatefulWidget {
  final HospitalityListing? initialListing;

  const ListingEditorScreen({super.key, this.initialListing});

  @override
  ConsumerState<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _contentController;
  late TextEditingController _locationSearchController;
  late TextEditingController _parkingDetailsController;

  final MapController _mapController = MapController();

  late bool _isActive;
  bool _isSaving = false;
  bool _isSearchingCities = false;
  bool _isUploadingImage = false;

  final List<String> _images = [];

  String _currentLocationName = 'Seattle, WA, USA';
  String _currentGeohash = 'c23n';
  LatLng _currentCenter = const LatLng(47.6062, -122.3321);

  List<CitySearchResult> _citySuggestions = [];

  // Hosting Preferences (Tri-state: null = unanswered, true = Yes, false = No)
  int? _maxGuests;
  bool? _acceptLastMinute;
  bool? _wheelchairAccessible;
  bool? _tentCampingAvailable;
  bool? _hostsWithChildren;
  bool? _hostsWithPets;
  bool? _okayWithDrinking;
  String? _okayWithSmoking; // null, 'no', 'outside', 'yes'

  // Home Environment (Tri-state: null = unanswered, true = Yes, false = No)
  String? _sleepingArrangement;
  String? _parking;
  bool? _hasHousemates;
  bool? _hasKids;
  bool? _hasPets;
  bool? _drinksAtHome;
  String? _smokesAtHome; // null, 'no', 'outside', 'yes'

  @override
  void initState() {
    super.initState();
    final init = widget.initialListing;

    _titleController = TextEditingController(text: init?.title ?? '');
    _summaryController = TextEditingController(text: init?.summary ?? '');
    _contentController = TextEditingController(text: init?.content ?? '');
    _parkingDetailsController = TextEditingController(text: init?.parkingDetails ?? '');
    _isActive = init?.isActive ?? true;

    if (init?.images != null) {
      _images.addAll(init!.images);
    }

    // Load existing values (null if not set)
    _maxGuests = init?.maxGuests;
    _acceptLastMinute = init?.acceptLastMinute;
    _wheelchairAccessible = init?.wheelchairAccessible;
    _tentCampingAvailable = init?.tentCampingAvailable;
    _hostsWithChildren = init?.hostsWithChildren;
    _hostsWithPets = init?.hostsWithPets;
    _okayWithDrinking = init?.okayWithDrinking;
    _okayWithSmoking = init?.okayWithSmoking;

    _sleepingArrangement = init?.sleepingArrangement;
    _parking = init?.parking;
    _hasHousemates = init?.hasHousemates;
    _hasKids = init?.hasKids;
    _hasPets = init?.hasPets;
    _drinksAtHome = init?.drinksAtHome;
    _smokesAtHome = init?.smokesAtHome;

    if (init != null && init.location.isNotEmpty) {
      _currentLocationName = init.location;
      if (init.geohash != null && init.geohash!.isNotEmpty) {
        _currentGeohash = init.privacyGeohash ?? init.geohash!;
        final decoded = GeohashHelper.decode(_currentGeohash);
        if (decoded != null) {
          _currentCenter = LatLng(decoded.latitude, decoded.longitude);
        }
      } else if (init.effectiveLatitude != null && init.effectiveLongitude != null) {
        _currentCenter = LatLng(init.effectiveLatitude!, init.effectiveLongitude!);
        _currentGeohash = GeohashHelper.encode(_currentCenter.latitude, _currentCenter.longitude, precision: 4);
      }
    }

    _locationSearchController = TextEditingController(text: _currentLocationName);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _locationSearchController.dispose();
    _parkingDetailsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final uploadService = ref.read(mediaUploadServiceProvider);
      final url = await uploadService.uploadImage(
        bytes: bytes,
        filename: picked.name,
      );
      setState(() {
        _images.add(url);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded to nostr.build successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showAddImageUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Image by URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Image HTTPS URL',
            hintText: 'https://example.com/room.jpg',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty && url.startsWith('http')) {
                setState(() => _images.add(url));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onCitySearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _citySuggestions = [];
        _isSearchingCities = false;
      });
      return;
    }

    setState(() => _isSearchingCities = true);
    final results = await GeohashHelper.searchCities(query);
    if (mounted) {
      setState(() {
        _citySuggestions = results;
        _isSearchingCities = false;
      });
    }
  }

  void _selectCity(CitySearchResult city) {
    setState(() {
      _currentLocationName = city.displayName;
      _locationSearchController.text = city.displayName;
      _currentGeohash = city.geohash;
      _currentCenter = LatLng(city.latitude, city.longitude);
      _citySuggestions = [];
    });

    _mapController.move(_currentCenter, 10.0);
  }

  void _onMapTapped(LatLng point) {
    final geohash = GeohashHelper.encode(point.latitude, point.longitude, precision: 4);
    final decoded = GeohashHelper.decode(geohash);

    setState(() {
      _currentGeohash = geohash;
      if (decoded != null) {
        _currentCenter = LatLng(decoded.latitude, decoded.longitude);
      } else {
        _currentCenter = point;
      }
    });
  }

  List<LatLng> _getGeohashPolygonPoints() {
    final corners = GeohashHelper.getBoundingBoxCorners(_currentGeohash);
    if (corners == null) return [];
    return corners.map((c) => LatLng(c.lat, c.lon)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialListing != null;
    final polygonPoints = _getGeohashPolygonPoints();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Hosting Offer' : 'Create Hosting Offer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveListing,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Update' : 'Publish'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Status Switch Card
            Card(
              margin: EdgeInsets.zero,
              color: _isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : theme.colorScheme.surfaceContainerLow,
              child: SwitchListTile(
                title: Text(
                  _isActive ? 'Currently Accepting Guests (Active)' : 'Not Accepting Guests (Inactive / Sold)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isActive
                      ? 'Your offer is discoverable by travelers on open Nostr relays.'
                      : 'Hidden from active searches until you re-enable it.',
                ),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Listing Title
            Text('Listing Title', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Spare Guest Room near Downtown Seattle',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a listing title' : null,
            ),
            const SizedBox(height: 20),

            // Short Summary
            Text('Short Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cozy private room with queen bed, fast Wi-Fi, and bike access',
                prefixIcon: Icon(Icons.short_text_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide a short summary' : null,
            ),
            const SizedBox(height: 24),

            // Map & General Area Picker Section
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map_rounded, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'General Area & Neighborhood',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Type your city or tap/drag anywhere on the map to set the general ~20-40km area where you host. Your exact street address is NEVER asked for or stored.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),

                        // City Search Autocomplete Input
                        TextField(
                          controller: _locationSearchController,
                          decoration: InputDecoration(
                            labelText: 'Search City or Region',
                            hintText: 'e.g. Seattle, Austin, Berlin, Paris, Tokyo...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _isSearchingCities
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: _onCitySearchChanged,
                        ),

                        // City Suggestions Dropdown / Chips
                        if (_citySuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _citySuggestions.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = _citySuggestions[idx];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_city_rounded, size: 20),
                                  title: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('Zone: ${item.geohash} (~20-40km area)'),
                                  onTap: () => _selectCity(item),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Interactive Map Area Selector
                  SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentCenter,
                            initialZoom: 9.5,
                            minZoom: 3.0,
                            maxZoom: 16.0,
                            onTap: (_, point) => _onMapTapped(point),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: MapTileConfig.getTileUrl(context),
                              subdomains: MapTileConfig.subdomains,
                              userAgentPackageName: MapTileConfig.userAgentPackageName,
                            ),

                            // Geohash Bounding Rectangle Polygon
                            if (polygonPoints.isNotEmpty)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: polygonPoints,
                                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                    borderColor: theme.colorScheme.primary,
                                    borderStrokeWidth: 2.5,
                                  ),
                                ],
                              ),

                            // Center Marker
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentCenter,
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Tap instruction overlay
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Tap anywhere on the map to snap to that neighborhood zone',
                                    style: TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Area Confirmation Banner
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Zone: $_currentLocationName (g: $_currentGeohash)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '🔒 Nostr Privacy: Bounded to ~20-40km area. No private coordinates are broadcasted.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION: Sleeping Arrangements & Capacity ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bed_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Sleeping Arrangements & Capacity',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Primary Sleeping Setup', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('— Unspecified', null, _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip('Private room', 'private_room', _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip('Shared room', 'shared_room', _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip('Couch / Sofa', 'couch', _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip('Common room', 'common_room', _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip('Tent camping space', 'tent_space', _sleepingArrangement, (v) => setState(() => _sleepingArrangement = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Max Number of Guests', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Simultaneous travelers accommodated', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 18),
                                onPressed: (_maxGuests != null && _maxGuests! > 1)
                                    ? () => setState(() => _maxGuests = _maxGuests! - 1)
                                    : () => setState(() => _maxGuests = null),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  _maxGuests != null ? '$_maxGuests' : '—',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                onPressed: () => setState(() => _maxGuests = (_maxGuests ?? 1) + 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION: Hosting Preferences (Tri-State: — / Yes / No) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Hosting Preferences',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select "—" to leave unanswered / not specified, or explicitly set "Yes" or "No".',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),

                    _buildTriStateRow(
                      theme,
                      'Accept last-minute requests',
                      'Open to travelers reaching out same-day',
                      _acceptLastMinute,
                      (v) => setState(() => _acceptLastMinute = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Wheelchair accessible',
                      'Step-free or accessible access to accommodation',
                      _wheelchairAccessible,
                      (v) => setState(() => _wheelchairAccessible = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Tent camping available',
                      'Backyard or lawn space suitable for tents',
                      _tentCampingAvailable,
                      (v) => setState(() => _tentCampingAvailable = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Hosts people with children',
                      null,
                      _hostsWithChildren,
                      (v) => setState(() => _hostsWithChildren = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Hosts people with pets',
                      null,
                      _hostsWithPets,
                      (v) => setState(() => _hostsWithPets = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Okay with people drinking',
                      'Guests may drink alcohol in moderation',
                      _okayWithDrinking,
                      (v) => setState(() => _okayWithDrinking = v),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text('Smoking Policy for Guests', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('— Unspecified', null, _okayWithSmoking, (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip('No smoking', 'no', _okayWithSmoking, (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip('Outside only', 'outside', _okayWithSmoking, (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip('Smoking allowed', 'yes', _okayWithSmoking, (v) => setState(() => _okayWithSmoking = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION: My Home Environment (Tri-State: — / Yes / No) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.house_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'My Home & Household',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Information about your household environment.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),

                    Text('Parking Availability', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('— Unspecified', null, _parking, (v) => setState(() => _parking = v)),
                        _buildChoiceChip('No parking', 'none', _parking, (v) => setState(() => _parking = v)),
                        _buildChoiceChip('Free on premises', 'free_on_premises', _parking, (v) => setState(() => _parking = v)),
                        _buildChoiceChip('Street parking', 'street', _parking, (v) => setState(() => _parking = v)),
                        _buildChoiceChip('Paid parking nearby', 'paid', _parking, (v) => setState(() => _parking = v)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _parkingDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Parking Details (Optional)',
                        hintText: 'e.g. Driveway spot or free street parking after 6 PM',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTriStateRow(
                      theme,
                      'Has housemates / roommates',
                      null,
                      _hasHousemates,
                      (v) => setState(() => _hasHousemates = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Kids live in household',
                      null,
                      _hasKids,
                      (v) => setState(() => _hasKids = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Pets live in household',
                      null,
                      _hasPets,
                      (v) => setState(() => _hasPets = v),
                    ),
                    const Divider(height: 1),
                    _buildTriStateRow(
                      theme,
                      'Host drinks at home',
                      null,
                      _drinksAtHome,
                      (v) => setState(() => _drinksAtHome = v),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text('Host Smokes at Home', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('— Unspecified', null, _smokesAtHome, (v) => setState(() => _smokesAtHome = v)),
                        _buildChoiceChip('No', 'no', _smokesAtHome, (v) => setState(() => _smokesAtHome = v)),
                        _buildChoiceChip('Outside only', 'outside', _smokesAtHome, (v) => setState(() => _smokesAtHome = v)),
                        _buildChoiceChip('Yes', 'yes', _smokesAtHome, (v) => setState(() => _smokesAtHome = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Description / House Rules
            Text('Full Description & Hospitality Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Describe your space, house expectations, check-in details, and what makes hosting fun for you.',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide detailed description' : null,
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 24),

            // --- SECTION: Accommodation Photos (nostr.build) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Accommodation Photos',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload photos of your spare room, couch, or home. Hosted decentralized on nostr.build and published in your Nostr listing.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    // Active Upload Spinner
                    if (_isUploadingImage)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Uploading image to nostr.build via NIP-96...',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Gallery Display
                    if (_images.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (int i = 0; i < _images.length; i++)
                            Stack(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    image: DecorationImage(
                                      image: NetworkImage(_images[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (i == 0)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Cover',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                    if (_images.isNotEmpty) const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('Upload Photo'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _isUploadingImage ? null : _showAddImageUrlDialog,
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Add by URL'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _isSaving ? null : _saveListing,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(
                isEditing ? 'Save & Broadcast Changes to Relays' : 'Publish Hospitality Offer to Nostr',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTriStateRow(
    ThemeData theme,
    String title,
    String? subtitle,
    bool? value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool?>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
            ),
            segments: const [
              ButtonSegment<bool?>(
                value: null,
                label: Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                tooltip: 'Unanswered / Not specified',
              ),
              ButtonSegment<bool?>(
                value: true,
                label: Text('Yes', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment<bool?>(
                value: false,
                label: Text('No', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String? value, String? selectedValue, ValueChanged<String?> onSelected) {
    final isSelected = selectedValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
        } else if (value != null) {
          onSelected(null);
        }
      },
    );
  }

  void _saveListing() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState == null || !authState.isAuthenticated || authState.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in with your Nostr keys to publish a listing')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(listingRepositoryProvider);
      final myPubkey = authState.pubkey!;
      final existing = widget.initialListing;

      final dTag = existing?.dTag ?? '$myPubkey-home';

      final draft = HospitalityListing(
        eventId: existing?.eventId ?? '',
        authorPubkey: myPubkey,
        dTag: dTag,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        location: _currentLocationName,
        geohash: _currentGeohash,
        originLat: _currentCenter.latitude,
        originLon: _currentCenter.longitude,
        status: _isActive ? NostrConstants.statusActive : NostrConstants.statusSold,
        publishedAt: existing?.publishedAt ?? DateTime.now(),
        createdAt: DateTime.now(),
        images: _images,
        categories: const [
          NostrConstants.topicHospitality,
          'Home',
        ],
        maxGuests: _maxGuests,
        acceptLastMinute: _acceptLastMinute,
        wheelchairAccessible: _wheelchairAccessible,
        tentCampingAvailable: _tentCampingAvailable,
        hostsWithChildren: _hostsWithChildren,
        hostsWithPets: _hostsWithPets,
        okayWithDrinking: _okayWithDrinking,
        okayWithSmoking: _okayWithSmoking,
        sleepingArrangement: _sleepingArrangement,
        parking: _parking,
        parkingDetails: _parkingDetailsController.text.trim().isNotEmpty ? _parkingDetailsController.text.trim() : null,
        hasHousemates: _hasHousemates,
        hasKids: _hasKids,
        hasPets: _hasPets,
        drinksAtHome: _drinksAtHome,
        smokesAtHome: _smokesAtHome,
      );

      await repo.publishListing(draft);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing != null ? 'Hosting offer updated on Nostr!' : 'Hosting offer published to Nostr relays!'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish listing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
