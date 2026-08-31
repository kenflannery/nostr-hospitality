import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat_message.dart';
import '../../models/hospitality_listing.dart';
import '../../models/interaction_reference.dart';
import '../../models/reference_summary.dart';
import '../../models/travel_profile.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/reference_repository.dart';
import '../nostr/nostr_service.dart';
import '../nostr/relay_config.dart';
import '../nostr/signer_service.dart';
import '../services/media_upload_service.dart';

// --- Base Infrastructure Providers ---

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main with override');
});

final relayConfigProvider = Provider<RelayConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RelayConfig(prefs);
});

final signerServiceProvider = Provider<SignerService>((ref) {
  return SecureLocalSignerService();
});

final nostrServiceProvider = Provider<NostrService>((ref) {
  final relayConfig = ref.watch(relayConfigProvider);
  final signerService = ref.watch(signerServiceProvider);
  final service = NostrService(
    relayConfig: relayConfig,
    signerService: signerService,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  final nostrService = ref.watch(nostrServiceProvider);
  return MediaUploadService(nostrService);
});

// --- Repository Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final signer = ref.watch(signerServiceProvider);
  final nostr = ref.watch(nostrServiceProvider);
  return AuthRepository(signerService: signer, nostrService: nostr);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final nostr = ref.watch(nostrServiceProvider);
  return ProfileRepository(nostr);
});

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final nostr = ref.watch(nostrServiceProvider);
  return ListingRepository(nostr);
});

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  final nostr = ref.watch(nostrServiceProvider);
  return ReferenceRepository(nostr);
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final nostr = ref.watch(nostrServiceProvider);
  return MessageRepository(nostr);
});

// --- Auth State Notifier ---

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    init();
  }

  Future<void> init() async {
    try {
      final auth = await _repo.initialize();
      state = AsyncValue.data(auth);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithPrivateKey(String privKey) async {
    state = const AsyncValue.loading();
    try {
      final authState = await _repo.loginWithPrivateKey(privKey);
      state = AsyncValue.data(authState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithNip07() async {
    state = const AsyncValue.loading();
    try {
      final authState = await _repo.loginWithNip07();
      state = AsyncValue.data(authState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithNip46(String bunkerUri, {String? explicitUserPubkey}) async {
    state = const AsyncValue.loading();
    try {
      final authState = await _repo.loginWithNip46(bunkerUri, explicitUserPubkey: explicitUserPubkey);
      state = AsyncValue.data(authState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> generateNewAccount() async {
    state = const AsyncValue.loading();
    try {
      final authState = await _repo.generateNewAccount();
      state = AsyncValue.data(authState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final authState = await _repo.logout();
      state = AsyncValue.data(authState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// --- Data Providers ---

/// Current logged-in user profile provider
final currentUserProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null || !auth.isAuthenticated || auth.pubkey == null) {
    return null;
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(auth.pubkey!);
});

/// Generic profile provider by pubkey
final userProfileProvider =
    FutureProvider.family.autoDispose<UserProfile?, String>((ref, pubkey) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(pubkey);
});

/// Current logged-in user Kind 30602 Travel Profile provider
final currentUserTravelProfileProvider =
    FutureProvider.autoDispose<TravelProfile?>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null || !auth.isAuthenticated || auth.pubkey == null) {
    return null;
  }
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getTravelProfile(auth.pubkey!);
});

/// Generic Kind 30602 Travel Profile provider by pubkey
final userTravelProfileProvider =
    FutureProvider.family.autoDispose<TravelProfile?, String>((ref, pubkey) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getTravelProfile(pubkey);
});

/// Discover hospitality listings stream provider
final discoverSearchQueryProvider = StateProvider<String>((ref) => '');

final discoverListingsProvider =
    StreamProvider.autoDispose<List<HospitalityListing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  final query = ref.watch(discoverSearchQueryProvider);
  return repo.getHospitalityListingsStream(locationFilter: query);
});

/// Hosting listing for a specific author
final authorListingProvider =
    FutureProvider.family.autoDispose<HospitalityListing?, String>((ref, pubkey) async {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.getListingForAuthor(pubkey);
});

/// References received by a specific subject pubkey
final userReferencesStreamProvider =
    StreamProvider.family.autoDispose<List<InteractionReference>, String>((ref, subjectPubkey) {
  final repo = ref.watch(referenceRepositoryProvider);
  return repo.getReferencesForUserStream(subjectPubkey);
});

/// Reference summary provider
final userReferenceSummaryProvider =
    FutureProvider.family.autoDispose<ReferenceSummary, String>((ref, subjectPubkey) async {
  final repo = ref.watch(referenceRepositoryProvider);
  final refs = await repo.getReferencesForUser(subjectPubkey);
  return repo.calculateSummary(refs);
});

/// Conversations summary list provider
final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>((ref) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null || !auth.isAuthenticated || auth.pubkey == null) {
    return [];
  }
  final repo = ref.watch(messageRepositoryProvider);
  return repo.loadConversations(forceRefresh: true);
});
