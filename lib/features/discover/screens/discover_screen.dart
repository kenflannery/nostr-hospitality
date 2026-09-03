import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/map_tile_config.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/geohash_helper.dart';
import '../../../models/hospitality_listing.dart';
import '../../../repositories/listing_repository.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/user_avatar.dart';
import '../../about/screens/about_page.dart';
import '../../auth/screens/login_screen.dart';
import '../../listings/screens/listing_detail_screen.dart';
import '../../listings/screens/listing_editor_screen.dart';

/// Discover screen displaying open hospitality offers across Nostr relays with Map & List views.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isMapView = true;
  _ListingCluster? _selectedCluster;

  List<CitySearchResult> _citySuggestions = [];
  bool _isSearchingCities = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() {
        _citySuggestions = [];
        _isSearchingCities = false;
      });
      return;
    }

    setState(() => _isSearchingCities = true);
    final results = await GeohashHelper.searchCities(clean);
    if (mounted && _searchController.text.trim() == clean) {
      setState(() {
        _citySuggestions = results;
        _isSearchingCities = false;
      });
    }
  }

  void _selectCity(CitySearchResult city) {
    _searchFocusNode.unfocus();
    setState(() {
      _searchController.text = city.displayName;
      _citySuggestions = [];
      _isSearchingCities = false;
      _isMapView = true;
    });

    _mapController.move(LatLng(city.latitude, city.longitude), 10.5);
  }

  void _onSubmitSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    if (_citySuggestions.isNotEmpty) {
      _selectCity(_citySuggestions.first);
      return;
    }

    setState(() => _isSearchingCities = true);
    final results = await GeohashHelper.searchCities(clean);
    if (mounted) {
      setState(() => _isSearchingCities = false);
      if (results.isNotEmpty) {
        _selectCity(results.first);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No location found for "$clean"')),
        );
      }
    }
  }

  void _showCreateListingSheet(BuildContext context, bool isAuthenticated) {
    if (!isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Hospitality Listing',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Publish an accommodation offer or broadcast a stay request on Nostr.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: theme.colorScheme.surfaceContainerLow,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.roofing_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Host Travelers (Offer Accommodation)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Open your couch, spare room, house swap, or yard to travelers.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ListingEditorScreen(initialIsRequest: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: theme.colorScheme.surfaceContainerLow,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.luggage_rounded, color: Colors.teal),
                ),
                title: const Text('Find a Host (Post Stay Request)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Broadcast destination, travel dates, and party size to local hosts.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ListingEditorScreen(initialIsRequest: true),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listingsAsync = ref.watch(discoverListingsProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/branding/logo.png',
                width: 26,
                height: 26,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.roofing_rounded,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hospitality Libre'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Nostr Protocol Specs',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _selectedCluster != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateListingSheet(context, authState?.isAuthenticated ?? false),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Listing'),
            ),
      body: Stack(
        children: [
          // Main Body: Map or List View
          Column(
            children: [
              const SizedBox(height: 122), // Header spacer for floating search & filter bar
              Expanded(
                child: listingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: EmptyStateView(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to Load Listings',
                      message: err.toString(),
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(discoverListingsProvider),
                    ),
                  ),
                  data: (listings) {
                    if (listings.isEmpty) {
                      final typeFilter = ref.watch(discoverListingTypeFilterProvider);
                      final emptyTitle = typeFilter == ListingTypeFilter.requestsOnly
                          ? 'No Travel Requests Found'
                          : typeFilter == ListingTypeFilter.offersOnly
                              ? 'No Hosting Offers Found'
                              : 'No Hospitality Listings Yet';
                      final emptyMsg = typeFilter == ListingTypeFilter.requestsOnly
                          ? 'Be the first traveler to post a stay request in this destination!'
                          : typeFilter == ListingTypeFilter.offersOnly
                              ? 'Be the first host to open your home to travelers on Nostr!'
                              : 'Be the first to post a hosting offer or travel request on the open Nostr network!\nNo middleman, no fees, 100% sovereign.';

                      return EmptyStateView(
                        icon: Icons.explore_off_rounded,
                        title: emptyTitle,
                        message: emptyMsg,
                        actionLabel: typeFilter == ListingTypeFilter.requestsOnly
                            ? 'Post Travel Request'
                            : 'Create Listing',
                        onAction: () => _showCreateListingSheet(context, authState?.isAuthenticated ?? false),
                      );
                    }

                    if (_isMapView) {
                      return _buildMapView(context, theme, listings);
                    }

                    return _buildListView(context, theme, listings);
                  },
                ),
              ),
            ],
          ),

          // Floating Search Bar & Filter Controls
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search city or region (e.g. Chicago)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _isSearchingCities
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _citySuggestions = []);
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSubmitSearch,
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<ListingTypeFilter>(
                                segments: const [
                                  ButtonSegment(
                                    value: ListingTypeFilter.all,
                                    label: Text('All'),
                                  ),
                                  ButtonSegment(
                                    value: ListingTypeFilter.offersOnly,
                                    label: Text('Hosts'),
                                    icon: Icon(Icons.roofing_rounded, size: 15),
                                  ),
                                  ButtonSegment(
                                    value: ListingTypeFilter.requestsOnly,
                                    label: Text('Travelers'),
                                    icon: Icon(Icons.luggage_rounded, size: 15),
                                  ),
                                ],
                                selected: {ref.watch(discoverListingTypeFilterProvider)},
                                onSelectionChanged: (set) {
                                  ref.read(discoverListingTypeFilterProvider.notifier).state = set.first;
                                  setState(() => _selectedCluster = null);
                                },
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _isMapView ? Icons.view_list_rounded : Icons.map_rounded,
                                size: 20,
                              ),
                              tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
                              onPressed: () {
                                setState(() {
                                  _isMapView = !_isMapView;
                                  _selectedCluster = null;
                                  _citySuggestions = [];
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Auto-Fill City Suggestions Dropdown
                if (_citySuggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Material(
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surfaceContainerHigh,
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _citySuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _citySuggestions[idx];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              item.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Center map to ~${item.geohash} zone',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onTap: () => _selectCity(item),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, ThemeData theme, List<HospitalityListing> listings) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _ListingFeedCard(
          listing: listing,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(listing: listing),
              ),
            );
          },
        );
      },
    );
  }

  List<_ListingCluster> _buildClusters(List<HospitalityListing> listings) {
    final Map<String, List<HospitalityListing>> groups = {};
    final Map<String, LatLng> centers = {};
    final Map<String, String> geohashes = {};

    for (final listing in listings) {
      if (!listing.hasLocationCoordinates) continue;
      // Group by 4-char geohash or rounded coordinates
      final key = (listing.geohash != null && listing.geohash!.isNotEmpty)
          ? (listing.geohash!.length > 4 ? listing.geohash!.substring(0, 4).toLowerCase() : listing.geohash!.toLowerCase())
          : '${listing.effectiveLatitude!.toStringAsFixed(3)},${listing.effectiveLongitude!.toStringAsFixed(3)}';

      groups.putIfAbsent(key, () => []).add(listing);
      centers.putIfAbsent(key, () => LatLng(listing.effectiveLatitude!, listing.effectiveLongitude!));
      if (listing.geohash != null && listing.geohash!.isNotEmpty) {
        geohashes.putIfAbsent(key, () => listing.geohash!);
      }
    }

    return groups.entries.map((e) {
      return _ListingCluster(
        id: e.key,
        geohash: geohashes[e.key],
        center: centers[e.key]!,
        listings: e.value,
      );
    }).toList();
  }

  Widget _buildMapView(BuildContext context, ThemeData theme, List<HospitalityListing> listings) {
    final clusters = _buildClusters(listings);

    LatLng initialCenter = const LatLng(47.6062, -122.3321); // Default center
    double initialZoom = 9.0;

    if (clusters.isNotEmpty) {
      final first = clusters.first;
      initialCenter = first.center;
      initialZoom = clusters.length == 1 ? 9.0 : 4.0;
    }

    // Generate geohash bounding box polygon for selected cluster
    final polygons = <Polygon>[];
    if (_selectedCluster != null) {
      final geohash = _selectedCluster!.geohash ??
          GeohashHelper.encode(
            _selectedCluster!.center.latitude,
            _selectedCluster!.center.longitude,
            precision: 4,
          );
      final corners = GeohashHelper.getBoundingBoxCorners(geohash);
      if (corners != null && corners.length >= 4) {
        polygons.add(
          Polygon(
            points: corners.map((c) => LatLng(c.lat, c.lon)).toList(),
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            borderColor: theme.colorScheme.primary.withValues(alpha: 0.55),
            borderStrokeWidth: 2.0,
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 1.5,
            maxZoom: 18.0,
            onTap: (_, __) {
              if (_selectedCluster != null) {
                setState(() => _selectedCluster = null);
              }
              if (_citySuggestions.isNotEmpty) {
                setState(() => _citySuggestions = []);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: MapTileConfig.getTileUrl(context),
              subdomains: MapTileConfig.subdomains,
              userAgentPackageName: MapTileConfig.userAgentPackageName,
            ),
            if (polygons.isNotEmpty)
              PolygonLayer(
                polygons: polygons,
              ),
            MarkerLayer(
              markers: clusters.map((cluster) {
                final isSelected = _selectedCluster?.id == cluster.id;
                final isMulti = cluster.listings.length > 1;
                final isRequestCluster = cluster.listings.every((l) => l.isRequest);
                final isOfferCluster = cluster.listings.every((l) => l.isOffer);

                final Color markerColor = isMulti
                    ? (isRequestCluster
                        ? Colors.teal
                        : (isOfferCluster ? theme.colorScheme.primary : theme.colorScheme.tertiary))
                    : (cluster.listings.first.isRequest ? Colors.teal : theme.colorScheme.primary);

                final IconData markerIcon = isMulti
                    ? (isRequestCluster
                        ? Icons.luggage_rounded
                        : (isOfferCluster ? Icons.home_work_rounded : Icons.travel_explore_rounded))
                    : (cluster.listings.first.isRequest ? Icons.luggage_rounded : Icons.roofing_rounded);

                final markerWidth = isMulti ? (isSelected ? 62.0 : 50.0) : (isSelected ? 54.0 : 44.0);
                final markerHeight = markerWidth;

                return Marker(
                  point: cluster.center,
                  width: markerWidth,
                  height: markerHeight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCluster = cluster;
                        _citySuggestions = [];
                      });
                      _mapController.move(
                        cluster.center,
                        _mapController.camera.zoom < 6 ? 8.0 : _mapController.camera.zoom,
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main Marker Pin
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: markerWidth,
                          height: markerHeight,
                          decoration: BoxDecoration(
                            color: isSelected ? markerColor : theme.colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.white : markerColor,
                              width: isMulti ? 3.0 : 2.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              markerIcon,
                              size: isSelected ? 26 : 20,
                              color: isSelected ? Colors.white : markerColor,
                            ),
                          ),
                        ),

                        // Count Badge for Clusters (> 1 host)
                        if (isMulti)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${cluster.listings.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Selected Listing Overlay Bottom Card (Single or Multi-Host Carousel)
        if (_selectedCluster != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _MapClusterPreviewCard(
              key: ValueKey(_selectedCluster!.id),
              cluster: _selectedCluster!,
              onClose: () => setState(() => _selectedCluster = null),
            ),
          ),
      ],
    );
  }
}

/// Represents a cluster of listings sharing the same geohash or coordinates.
class _ListingCluster {
  final String id;
  final String? geohash;
  final LatLng center;
  final List<HospitalityListing> listings;

  const _ListingCluster({
    required this.id,
    this.geohash,
    required this.center,
    required this.listings,
  });
}

/// Bottom preview card supporting single listing or multi-host swipeable carousel.
class _MapClusterPreviewCard extends ConsumerStatefulWidget {
  final _ListingCluster cluster;
  final VoidCallback onClose;

  const _MapClusterPreviewCard({
    super.key,
    required this.cluster,
    required this.onClose,
  });

  @override
  ConsumerState<_MapClusterPreviewCard> createState() => _MapClusterPreviewCardState();
}

class _MapClusterPreviewCardState extends ConsumerState<_MapClusterPreviewCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMulti = widget.cluster.listings.length > 1;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Host Count and Pager if multi-host
            if (isMulti) ...[
              Row(
                children: [
                  Icon(Icons.hub_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.cluster.listings.length} Hosts in Area',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Previous Button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Previous Host',
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1} of ${widget.cluster.listings.length}',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Next Host',
                    onPressed: _currentPage < widget.cluster.listings.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Dismiss',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const Divider(height: 12),
            ],

            // Content: Single or PageView
            if (!isMulti)
              _buildListingRow(context, theme, widget.cluster.listings.first, showClose: true)
            else
              SizedBox(
                height: 76,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: widget.cluster.listings.length,
                  itemBuilder: (context, index) {
                    return _buildListingRow(
                      context,
                      theme,
                      widget.cluster.listings[index],
                      showClose: false,
                    );
                  },
                ),
              ),

            // Dot indicators for multi-host clusters (Clickable)
            if (isMulti && widget.cluster.listings.length <= 8) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.cluster.listings.length, (idx) {
                  final isActive = idx == _currentPage;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListingRow(
    BuildContext context,
    ThemeData theme,
    HospitalityListing listing, {
    required bool showClose,
  }) {
    final authorProfile = ref.watch(userProfileProvider(listing.authorPubkey)).valueOrNull;

    return Row(
      children: [
        UserAvatar(
          imageUrl: authorProfile?.picture,
          nameOrPubkey: authorProfile?.bestName ?? listing.authorPubkey,
          radius: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                listing.title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: listing.isRequest
                          ? Colors.teal.withValues(alpha: 0.15)
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.isRequest ? 'Request' : 'Offer',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: listing.isRequest ? Colors.teal : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${authorProfile?.bestName ?? (listing.isRequest ? "Traveler" : "Host")} • ${listing.location}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingDetailScreen(listing: listing),
              ),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('View'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (showClose) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            tooltip: 'Dismiss',
            onPressed: widget.onClose,
          ),
        ],
      ],
    );
  }
}

class _ListingFeedCard extends ConsumerWidget {
  final HospitalityListing listing;
  final VoidCallback onTap;

  const _ListingFeedCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorProfile = ref.watch(userProfileProvider(listing.authorPubkey)).valueOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Host / Traveler Info Header
              Row(
                children: [
                  UserAvatar(
                    imageUrl: authorProfile?.picture,
                    nameOrPubkey: authorProfile?.bestName ?? listing.authorPubkey,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorProfile?.bestName ?? (listing.isRequest ? 'Traveler' : 'Host'),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: theme.colorScheme.outline),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                listing.location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: listing.isRequest
                          ? Colors.teal.withValues(alpha: 0.12)
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          listing.isRequest ? Icons.luggage_rounded : Icons.roofing_rounded,
                          size: 13,
                          color: listing.isRequest ? Colors.teal : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.isRequest ? 'Request' : 'Offer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: listing.isRequest ? Colors.teal : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                listing.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // Summary
              Text(
                listing.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // Dates & Guest Info
              if (listing.isDateConstrained || listing.maxGuests != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (listing.isDateConstrained)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12, color: Colors.teal[800]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDateRange(listing.startDate, listing.endDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (listing.maxGuests != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${listing.isRequest ? "Party" : "Max"}: ${listing.maxGuests}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
