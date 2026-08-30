import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/map_tile_config.dart';
import '../../../core/utils/geohash_helper.dart';
import '../../../models/hospitality_listing.dart';
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
  HospitalityListing? _selectedMapListing;

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
          // View Toggle (List vs Map)
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
                _selectedMapListing = null;
                _citySuggestions = [];
              });
            },
          ),
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
      floatingActionButton: _selectedMapListing != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (authState?.isAuthenticated ?? false) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ListingEditorScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_home_rounded),
              label: const Text('Host Travelers'),
            ),
      body: Stack(
        children: [
          // Main Body: Map or List View
          Column(
            children: [
              const SizedBox(height: 64), // Header spacer for floating search bar
              Expanded(
                child: listingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: EmptyStateView(
                      icon: Icons.error_outline_rounded,
                      title: 'Unable to Load Offers',
                      message: err.toString(),
                      actionLabel: 'Retry',
                      onAction: () => ref.invalidate(discoverListingsProvider),
                    ),
                  ),
                  data: (listings) {
                    if (listings.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.explore_off_rounded,
                        title: 'No Hospitality Offers Yet',
                        message:
                            'Be the first to list a couch, spare room, or home on the open Nostr network!\nNo middleman, no fees, 100% sovereign.',
                        actionLabel: 'Create a Hosting Offer',
                        onAction: () {
                          if (authState?.isAuthenticated ?? false) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ListingEditorScreen(),
                              ),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
                        },
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

          // Floating Search Bar & Auto-Fill Location Dropdown
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
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search city or region to recenter map (e.g. Seattle)...',
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSubmitSearch,
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

  Widget _buildMapView(BuildContext context, ThemeData theme, List<HospitalityListing> listings) {
    final mapListings = listings.where((l) => l.hasLocationCoordinates).toList();

    LatLng initialCenter = const LatLng(47.6062, -122.3321); // Default center
    double initialZoom = 9.0;

    if (mapListings.isNotEmpty) {
      final first = mapListings.first;
      initialCenter = LatLng(first.effectiveLatitude!, first.effectiveLongitude!);
      initialZoom = mapListings.length == 1 ? 9.0 : 4.0;
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
              if (_selectedMapListing != null) {
                setState(() => _selectedMapListing = null);
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
            MarkerLayer(
              markers: mapListings.map((listing) {
                final isSelected = _selectedMapListing?.addressCoordinate == listing.addressCoordinate;

                return Marker(
                  point: LatLng(listing.effectiveLatitude!, listing.effectiveLongitude!),
                  width: isSelected ? 56 : 44,
                  height: isSelected ? 56 : 44,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMapListing = listing;
                        _citySuggestions = [];
                      });
                      _mapController.move(
                        LatLng(listing.effectiveLatitude!, listing.effectiveLongitude!),
                        _mapController.camera.zoom < 6 ? 8.0 : _mapController.camera.zoom,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.roofing_rounded,
                          size: isSelected ? 26 : 20,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Selected Listing Overlay Bottom Card
        if (_selectedMapListing != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _MapListingPreviewCard(
              listing: _selectedMapListing!,
              onClose: () => setState(() => _selectedMapListing = null),
            ),
          ),
      ],
    );
  }
}

class _MapListingPreviewCard extends ConsumerWidget {
  final HospitalityListing listing;
  final VoidCallback onClose;

  const _MapListingPreviewCard({
    required this.listing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorProfile = ref.watch(userProfileProvider(listing.authorPubkey)).valueOrNull;

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(listing: listing),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: authorProfile?.picture,
                nameOrPubkey: authorProfile?.bestName ?? listing.authorPubkey,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.location,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Dismiss',
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
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
              // Host Info Header
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
                          authorProfile?.bestName ?? 'Host',
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
            ],
          ),
        ),
      ),
    );
  }
}
