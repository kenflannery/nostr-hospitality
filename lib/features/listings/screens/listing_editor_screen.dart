import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/map_tile_config.dart';
import '../../../core/utils/geohash_helper.dart';
import '../../../models/hospitality_listing.dart';

/// Screen to create or edit a NIP-99 (Kind 30402) Hospitality Listing.
///
/// Supports both:
/// 1. **Hosting Offers** (`hospitality-offer`): Hosts opening their homes.
/// 2. **Travel Requests** (`hospitality-request`): Travelers posting time-bound stay requests (public trips).
class ListingEditorScreen extends ConsumerStatefulWidget {
  final HospitalityListing? initialListing;
  final bool initialIsRequest;

  const ListingEditorScreen({
    super.key,
    this.initialListing,
    this.initialIsRequest = false,
  });

  @override
  ConsumerState<ListingEditorScreen> createState() =>
      _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isRequest;
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

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isTemporaryHosting = false;

  final List<String> _images = [];

  String _currentLocationName = 'Seattle, WA, USA';
  String _currentGeohash = 'c23n';
  LatLng _currentCenter = const LatLng(47.6062, -122.3321);

  List<CitySearchResult> _citySuggestions = [];

  // Hosting / Stay Preferences (Tri-state: null = unanswered, true = Yes, false = No)
  int? _maxGuests;
  bool? _acceptLastMinute;
  bool? _wheelchairAccessible;
  bool? _tentCampingAvailable;
  bool? _hostsWithChildren;
  bool? _hostsWithPets;
  bool? _okayWithDrinking;
  String? _okayWithSmoking; // null, 'no', 'outside', 'yes'

  // Home Environment / Accommodation Needs (Tri-state: null = unanswered, true = Yes, false = No)
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

    _isRequest = init != null ? init.isRequest : widget.initialIsRequest;
    _startDate = init?.startDate;
    _endDate = init?.endDate;
    _isTemporaryHosting =
        !_isRequest && (_startDate != null || _endDate != null);

    _titleController = TextEditingController(text: init?.title ?? '');
    _summaryController = TextEditingController(text: init?.summary ?? '');
    _contentController = TextEditingController(text: init?.content ?? '');
    _parkingDetailsController =
        TextEditingController(text: init?.parkingDetails ?? '');
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
      } else if (init.effectiveLatitude != null &&
          init.effectiveLongitude != null) {
        _currentCenter =
            LatLng(init.effectiveLatitude!, init.effectiveLongitude!);
        _currentGeohash = GeohashHelper.encode(
            _currentCenter.latitude, _currentCenter.longitude,
            precision: 4);
      }
    }

    _locationSearchController =
        TextEditingController(text: _currentLocationName);
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

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? (_startDate ?? now).add(const Duration(days: 3)));
    final firstDate =
        isStart ? now.subtract(const Duration(days: 30)) : (_startDate ?? now);
    final lastDate = now.add(const Duration(days: 730));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate!.subtract(const Duration(days: 1));
          }
        }
      });
    }
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
          const SnackBar(
              content: Text('Photo uploaded to nostr.build successfully!')),
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
            hintText: 'https://example.com/photo.jpg',
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
    final geohash =
        GeohashHelper.encode(point.latitude, point.longitude, precision: 4);
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
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? (_isRequest ? 'Edit Travel Request' : 'Edit Hosting Offer')
            : (_isRequest ? 'Post Travel Request' : 'Create Hosting Offer')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveListing,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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
            // Listing Type Selector (Offer vs. Request)
            if (!isEditing) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Hosting Offer'),
                    icon: Icon(Icons.roofing_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Travel Request'),
                    icon: Icon(Icons.luggage_rounded),
                  ),
                ],
                selected: {_isRequest},
                onSelectionChanged: (set) {
                  setState(() {
                    _isRequest = set.first;
                    if (_isRequest && _titleController.text.isEmpty) {
                      _titleController.text =
                          'Looking for a host in $_currentLocationName';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Status Switch Card
            Card(
              margin: EdgeInsets.zero,
              color: _isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : theme.colorScheme.surfaceContainerLow,
              child: SwitchListTile(
                title: Text(
                  _isRequest
                      ? (_isActive
                          ? 'Active Travel Request (Seeking Host)'
                          : 'Request Closed / Cancelled')
                      : (_isActive
                          ? 'Currently Accepting Guests (Active)'
                          : 'Not Accepting Guests (Inactive / Sold)'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isRequest
                      ? (_isActive
                          ? 'Discoverable by local hosts in this destination on Nostr relays.'
                          : 'Hidden from active searches.')
                      : (_isActive
                          ? 'Your offer is discoverable by travelers on open Nostr relays.'
                          : 'Hidden from active searches until you re-enable it.'),
                ),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Date Range Section (Required/Recommended for Request, Optional for Offer)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isRequest
                              ? Icons.calendar_month_rounded
                              : Icons.date_range_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRequest ? 'Trip Dates' : 'Availability Window',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRequest
                          ? 'When are you arriving and departing? Dates will be saved as open start/end tags.'
                          : 'Ongoing hosts can leave dates open-ended. Specify dates if you can only host temporarily.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (!_isRequest) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Temporary Hosting Window'),
                        subtitle: const Text(
                            'Set specific dates (e.g. while subletting or roommate is away)'),
                        value: _isTemporaryHosting,
                        onChanged: (val) {
                          setState(() {
                            _isTemporaryHosting = val ?? false;
                            if (!_isTemporaryHosting) {
                              _startDate = null;
                              _endDate = null;
                            }
                          });
                        },
                      ),
                    ],
                    if (_isRequest || _isTemporaryHosting) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(isStart: true),
                              icon: const Icon(Icons.login_rounded, size: 18),
                              label: Text(
                                _startDate != null
                                    ? '${_isRequest ? "Arrival" : "Start"}: ${dateFormat.format(_startDate!)}'
                                    : (_isRequest
                                        ? "Arrival Date"
                                        : "Start Date"),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(isStart: false),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: Text(
                                _endDate != null
                                    ? '${_isRequest ? "Departure" : "End"}: ${dateFormat.format(_endDate!)}'
                                    : (_isRequest
                                        ? "Departure Date"
                                        : "End Date"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
                            Icon(Icons.map_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              _isRequest
                                  ? 'Destination City / Area'
                                  : 'General Area & Neighborhood',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRequest
                              ? 'Search destination city or tap the map to set the general ~20-40km zone you plan to visit.'
                              : 'Type your city or tap/drag anywhere on the map to set the general ~20-40km area where you host. Your exact street address is NEVER asked for or stored.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),

                        // City Search Autocomplete Input
                        TextField(
                          controller: _locationSearchController,
                          decoration: InputDecoration(
                            labelText: _isRequest
                                ? 'Destination City or Region'
                                : 'Search City or Region',
                            hintText:
                                'e.g. Chicago, Seattle, Austin, Berlin, Paris...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _isSearchingCities
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: _onCitySearchChanged,
                        ),

                        // City Suggestions Dropdown
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
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = _citySuggestions[idx];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                      Icons.location_city_rounded,
                                      size: 20),
                                  title: Text(item.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      'Zone: ${item.geohash} (~20-40km area)'),
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
                              userAgentPackageName:
                                  MapTileConfig.userAgentPackageName,
                            ),

                            // Geohash Bounding Rectangle Polygon
                            if (polygonPoints.isNotEmpty)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: polygonPoints,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.25),
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
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRequest
                                          ? Icons.luggage_rounded
                                          : Icons.roofing_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                        Icon(Icons.shield_outlined,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Zone: $_currentLocationName (g: $_currentGeohash)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '🔒 Nostr Privacy: Bounded to ~20-40km area. Exact street coordinates are never published.',
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

            // --- SECTION: Arrangements & Capacity ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bed_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _isRequest
                              ? 'Travel Party & Sleeping Needs'
                              : 'Sleeping Arrangements & Capacity',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRequest
                          ? 'Acceptable Sleeping Setup'
                          : 'Primary Sleeping Setup',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                            '— Unspecified',
                            null,
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip(
                            'Private room',
                            'private_room',
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip(
                            'Shared room',
                            'shared_room',
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip(
                            'Couch / Sofa',
                            'couch',
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip(
                            'Common room',
                            'common_room',
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                        _buildChoiceChip(
                            'Tent camping space',
                            'tent_space',
                            _sleepingArrangement,
                            (v) => setState(() => _sleepingArrangement = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRequest
                                    ? 'Party Size'
                                    : 'Max Number of Guests',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRequest
                                    ? 'Number of travelers in your party'
                                    : 'Simultaneous travelers accommodated',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.remove_rounded, size: 18),
                                onPressed: (_maxGuests != null &&
                                        _maxGuests! > 1)
                                    ? () => setState(
                                        () => _maxGuests = _maxGuests! - 1)
                                    : () => setState(() => _maxGuests = null),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  _maxGuests != null ? '$_maxGuests' : '—',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                onPressed: () => setState(
                                    () => _maxGuests = (_maxGuests ?? 1) + 1),
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

            // --- SECTION: Preferences & Rules (Tri-State: — / Yes / No) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _isRequest
                              ? 'Travel Needs & Habits'
                              : 'Hosting Preferences',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select "—" to leave unspecified, or explicitly declare "Yes" or "No".',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    _buildTriStateRow(
                      _isRequest
                          ? 'Wheelchair accessible stay required'
                          : 'Wheelchair accessible accommodation',
                      _wheelchairAccessible,
                      (val) => setState(() => _wheelchairAccessible = val),
                    ),
                    _buildTriStateRow(
                      _isRequest
                          ? 'Tent camping acceptable'
                          : 'Tent camping space available',
                      _tentCampingAvailable,
                      (val) => setState(() => _tentCampingAvailable = val),
                    ),
                    _buildTriStateRow(
                      _isRequest
                          ? 'Traveling with children'
                          : 'Welcomes guests with children',
                      _hostsWithChildren,
                      (val) => setState(() => _hostsWithChildren = val),
                    ),
                    _buildTriStateRow(
                      _isRequest
                          ? 'Traveling with pets'
                          : 'Welcomes guests with pets',
                      _hostsWithPets,
                      (val) => setState(() => _hostsWithPets = val),
                    ),
                    _buildTriStateRow(
                      _isRequest
                          ? 'Open to drinking alcohol'
                          : 'Guests permitted to drink alcohol',
                      _okayWithDrinking,
                      (val) => setState(() => _okayWithDrinking = val),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRequest ? 'Smoking Habit' : 'Smoking Policy',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                            '— Unspecified',
                            null,
                            _okayWithSmoking,
                            (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip('No smoking', 'no', _okayWithSmoking,
                            (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip(
                            'Outside only',
                            'outside',
                            _okayWithSmoking,
                            (v) => setState(() => _okayWithSmoking = v)),
                        _buildChoiceChip(
                            'Allowed / Smoker',
                            'yes',
                            _okayWithSmoking,
                            (v) => setState(() => _okayWithSmoking = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION: Home Environment (Hosts Only) ---
            if (!_isRequest) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home_outlined,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'My Home Environment',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTriStateRow(
                          'I live with roommates / housemates',
                          _hasHousemates,
                          (val) => setState(() => _hasHousemates = val)),
                      _buildTriStateRow('Children live in household', _hasKids,
                          (val) => setState(() => _hasKids = val)),
                      _buildTriStateRow('Pets on the property', _hasPets,
                          (val) => setState(() => _hasPets = val)),
                      _buildTriStateRow(
                          'I drink alcohol at home',
                          _drinksAtHome,
                          (val) => setState(() => _drinksAtHome = val)),
                      const SizedBox(height: 12),
                      Text('Host Smoking at Home',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip('— Unspecified', null, _smokesAtHome,
                              (v) => setState(() => _smokesAtHome = v)),
                          _buildChoiceChip('Non-smoker', 'no', _smokesAtHome,
                              (v) => setState(() => _smokesAtHome = v)),
                          _buildChoiceChip(
                              'Outside only',
                              'outside',
                              _smokesAtHome,
                              (v) => setState(() => _smokesAtHome = v)),
                          _buildChoiceChip(
                              'Smokes at home',
                              'yes',
                              _smokesAtHome,
                              (v) => setState(() => _smokesAtHome = v)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Guest Parking',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChoiceChip('— Unspecified', null, _parking,
                              (v) => setState(() => _parking = v)),
                          _buildChoiceChip(
                              'Free on premises',
                              'free_on_premises',
                              _parking,
                              (v) => setState(() => _parking = v)),
                          _buildChoiceChip('Street parking', 'street', _parking,
                              (v) => setState(() => _parking = v)),
                          _buildChoiceChip('Paid nearby', 'paid', _parking,
                              (v) => setState(() => _parking = v)),
                          _buildChoiceChip('No parking', 'none', _parking,
                              (v) => setState(() => _parking = v)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _parkingDetailsController,
                        decoration: const InputDecoration(
                          labelText: 'Parking Instructions (Optional)',
                          hintText: 'e.g. Driveway spot on the left side',
                          prefixIcon: Icon(Icons.local_parking_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Photos Section
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _isRequest
                              ? 'Travel & Destination Photos'
                              : 'Accommodation Photos',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload photos to decentralized nostr.build media servers or enter existing URLs.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _images[i],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.white54),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _images.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isUploadingImage ? null : _pickAndUploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined,
                                    size: 18),
                            label: const Text('Upload Photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Add photo URL',
                          icon: const Icon(Icons.link_rounded),
                          onPressed: _showAddImageUrlDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Listing / Trip Title
            Text(
              _isRequest ? 'Trip Title' : 'Listing Title',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _isRequest
                    ? 'e.g. Visiting Chicago for Architecture Biennial'
                    : 'e.g. Spare Guest Room near Downtown Seattle',
                prefixIcon: const Icon(Icons.title_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isRequest
                      ? 'Please provide a trip title'
                      : 'Please provide a listing title')
                  : null,
            ),
            const SizedBox(height: 20),

            // Short Summary
            Text(
              _isRequest
                  ? 'Short Summary (Card Preview)'
                  : 'Short Summary (Card Preview)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'A brief 1-2 sentence overview displayed on map and discovery cards.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _summaryController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _isRequest
                    ? 'e.g. Solo traveler seeking 3 nights in Chicago for music and museum exploration'
                    : 'e.g. Cozy private room with queen bed, fast Wi-Fi, and bike access',
                prefixIcon: const Icon(Icons.short_text_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please provide a short summary'
                  : null,
            ),
            const SizedBox(height: 20),

            // Detailed Content & Markdown Description
            Text(
              _isRequest
                  ? 'Detailed Trip Description & Expectations'
                  : 'Detailed Description & House Expectations',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _contentController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: _isRequest
                    ? 'Tell local hosts about yourself, what brings you to town, what you hope to see or do, and what kind of stay you are hoping for...'
                    : 'Describe your home, host background, available sleeping arrangements, public transit access, and local recommendations...',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please provide a detailed description'
                  : null,
            ),
            const SizedBox(height: 32),

            // Publish Button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveListing,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.publish_rounded),
              label: Text(
                isEditing
                    ? (_isRequest
                        ? 'Update Travel Request'
                        : 'Update Hosting Offer')
                    : (_isRequest
                        ? 'Publish Travel Request'
                        : 'Publish Hosting Offer'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTriStateRow(
      String label, bool? value, ValueChanged<bool?> onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment<bool?>(value: null, label: Text('—')),
              ButtonSegment<bool?>(value: true, label: Text('Yes')),
              ButtonSegment<bool?>(value: false, label: Text('No')),
            ],
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip<T>(
      String label, T value, T currentValue, ValueChanged<T?> onSelected) {
    final isSelected = value == currentValue;
    return FilterChip(
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
    if (authState == null ||
        !authState.isAuthenticated ||
        authState.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please sign in with your Nostr keys to publish a listing')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(listingRepositoryProvider);
      final myPubkey = authState.pubkey!;
      final existing = widget.initialListing;

      final String dTag;
      if (existing != null) {
        dTag = existing.dTag;
      } else if (_isRequest) {
        final locSlug = _currentLocationName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-|-$'), '');
        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        dTag = 'trip-$locSlug-$nowSec';
      } else {
        dTag = '$myPubkey-home';
      }

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
        status:
            _isActive ? NostrConstants.statusActive : NostrConstants.statusSold,
        publishedAt: existing?.publishedAt ?? DateTime.now(),
        createdAt: DateTime.now(),
        images: _images,
        startDate: (_isRequest || _isTemporaryHosting) ? _startDate : null,
        endDate: (_isRequest || _isTemporaryHosting) ? _endDate : null,
        categories: _isRequest
            ? [
                NostrConstants.topicHospitality,
                NostrConstants.topicHospitalityRequest
              ]
            : [
                NostrConstants.topicHospitality,
                NostrConstants.topicHospitalityOffer,
                'Home'
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
        parkingDetails: _parkingDetailsController.text.trim().isNotEmpty
            ? _parkingDetailsController.text.trim()
            : null,
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
            content: Text(_isRequest
                ? (existing != null
                    ? 'Travel request updated!'
                    : 'Travel request published to Nostr!')
                : (existing != null
                    ? 'Hosting offer updated!'
                    : 'Hosting offer published to Nostr!')),
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
