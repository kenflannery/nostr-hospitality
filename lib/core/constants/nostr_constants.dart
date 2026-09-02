/// Central constants for Nostr hospitality protocol and NIP definitions.
class NostrConstants {
  NostrConstants._();

  // --- Event Kinds ---
  /// Kind 0: Standard user metadata (NIP-01)
  static const int metadataKind = 0;

  /// Kind 1: Short text note (NIP-01)
  static const int textNoteKind = 1;

  /// Kind 30402: Classified listing (NIP-99)
  static const int classifiedListingKind = 30402;

  /// Kind 30602: Travel & Community Profile (Draft NIP)
  static const int travelProfileKind = 30602;

  /// Kind 7654: Interaction Reference (Draft NIP)
  static const int interactionReferenceKind = 7654;

  /// Kind 1059: Gift Wrap (NIP-59 / NIP-17)
  static const int giftWrapKind = 1059;

  /// Kind 13: Seal (NIP-59 / NIP-17)
  static const int sealKind = 13;

  /// Kind 14: Rumor / Private Direct Message (NIP-17)
  static const int rumorKind = 14;

  /// Kind 10002: Relay list metadata (NIP-65)
  static const int relayListKind = 10002;

  // --- Tag Names ---
  static const String tagP = 'p';
  static const String tagE = 'e';
  static const String tagA = 'a';
  static const String tagD = 'd';
  static const String tagT = 't';
  static const String tagG = 'g';
  static const String tagTitle = 'title';
  static const String tagSummary = 'summary';
  static const String tagLocation = 'location';
  static const String tagStatus = 'status';
  static const String tagPrice = 'price';
  static const String tagPublishedAt = 'published_at';
  static const String tagImage = 'image';
  static const String tagContext = 'context';
  static const String tagRole = 'role';
  static const String tagSentiment = 'sentiment';
  static const String tagStart = 'start';
  static const String tagEnd = 'end';

  // --- Hospitality Conventions (NIP-99) ---
  static const String topicHospitality = 'hospitality';
  static const String topicHospitalityOffer = 'hospitality-offer';
  static const String topicHospitalityRequest = 'hospitality-request';
  static const String topicHome = 'Home';
  static const String statusActive = 'active';
  static const String statusSold = 'sold'; // NIP-99 closed/inactive

  // --- NIP-7654 Context Values ---
  static const String contextHospitality = 'hospitality';
  static const String contextMeeting = 'meeting';
  static const String contextTravel = 'travel';
  static const String contextTransaction = 'transaction';
  static const String contextService = 'service';
  static const String contextWorkExchange = 'work_exchange';
  static const String contextOther = 'other';

  static const List<String> standardContexts = [
    contextHospitality,
    contextMeeting,
    contextTravel,
    contextTransaction,
    contextService,
    contextWorkExchange,
    contextOther,
  ];

  // --- NIP-7654 Role Values ---
  static const String roleHost = 'host';
  static const String roleGuest = 'guest';
  static const String roleTraveler = 'traveler';
  static const String roleTravelCompanion = 'travel_companion';
  static const String roleBuyer = 'buyer';
  static const String roleSeller = 'seller';
  static const String roleCustomer = 'customer';
  static const String roleProvider = 'provider';
  static const String roleEmployer = 'employer';
  static const String roleWorker = 'worker';
  static const String roleOther = 'other';

  static const List<String> standardRoles = [
    roleHost,
    roleGuest,
    roleTraveler,
    roleTravelCompanion,
    roleBuyer,
    roleSeller,
    roleCustomer,
    roleProvider,
    roleEmployer,
    roleWorker,
    roleOther,
  ];

  // --- NIP-7654 Sentiment Values ---
  static const String sentimentPositive = 'positive';
  static const String sentimentNeutral = 'neutral';
  static const String sentimentNegative = 'negative';

  static const List<String> standardSentiments = [
    sentimentPositive,
    sentimentNeutral,
    sentimentNegative,
  ];

  // --- Default Bootstrap Relays ---
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
    'wss://relay.nostr.band',
    'wss://relay.trustroots.org',
  ];
}
