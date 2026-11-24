import 'enums.dart';

export 'enums.dart';

DateTime _dt(dynamic v) => DateTime.parse(v as String).toLocal();
double _d(dynamic v) => (v as num).toDouble();

class AppUser {
  final String id, fullName, email, phone, city;
  final String? avatarUrl;
  final UserRole activeRole;
  final bool isProviderOnboarded;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.city,
    this.avatarUrl,
    required this.activeRole,
    required this.isProviderOnboarded,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        fullName: j['full_name'],
        email: j['email'],
        phone: j['phone'] ?? '',
        city: j['city'],
        avatarUrl: j['avatar_url'],
        activeRole: UserRole.from(j['active_role']),
        isProviderOnboarded: j['is_provider_onboarded'],
        createdAt: _dt(j['created_at']),
      );
}

class ProviderProfile {
  final String userId, displayName, bio, city;
  final List<ServiceCategory> categories;
  final List<String> serviceAreas;
  final bool isAvailable;
  final double ratingAverage;
  final int reviewCount, completedBookingsCount;

  const ProviderProfile({
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.categories,
    required this.city,
    required this.serviceAreas,
    this.isAvailable = true,
    this.ratingAverage = 0,
    this.reviewCount = 0,
    this.completedBookingsCount = 0,
  });

  factory ProviderProfile.fromJson(Map<String, dynamic> j) => ProviderProfile(
        userId: j['user_id'],
        displayName: j['display_name'],
        bio: j['bio'],
        categories: (j['categories'] as List).map((e) => ServiceCategory.from(e)).toList(),
        city: j['city'],
        serviceAreas: List<String>.from(j['service_areas']),
        isAvailable: j['is_available'],
        ratingAverage: _d(j['rating_average']),
        reviewCount: j['review_count'],
        completedBookingsCount: j['completed_bookings_count'],
      );

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'display_name': displayName,
        'bio': bio,
        'categories': categories.map((e) => e.db).toList(),
        'city': city,
        'service_areas': serviceAreas,
      };
}

class ServiceRequest {
  final String id, clientId, clientName, title, description, city, areaName;
  final ServiceCategory category;
  final double? budgetPkr;
  final List<String> photoUrls;
  final RequestStatus status;
  final int bidCount;
  final DateTime createdAt;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.description,
    required this.city,
    required this.areaName,
    required this.category,
    this.budgetPkr,
    required this.photoUrls,
    required this.status,
    required this.bidCount,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
        id: j['id'],
        clientId: j['client_id'],
        clientName: j['client_name'],
        title: j['title'],
        description: j['description'],
        city: j['city'],
        areaName: j['area_name'],
        category: ServiceCategory.from(j['category']),
        budgetPkr: j['budget_pkr'] == null ? null : _d(j['budget_pkr']),
        photoUrls: List<String>.from(j['photo_urls']),
        status: RequestStatus.from(j['status']),
        bidCount: j['bid_count'],
        createdAt: _dt(j['created_at']),
      );
}

class Bid {
  final String id, requestId, providerId, providerName, message;
  final double providerRating, proposedPrice;
  final BidStatus status;
  final DateTime createdAt;

  const Bid({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    required this.providerRating,
    required this.proposedPrice,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> j) => Bid(
        id: j['id'],
        requestId: j['request_id'],
        providerId: j['provider_id'],
        providerName: j['provider_name'],
        providerRating: _d(j['provider_rating']),
        proposedPrice: _d(j['proposed_price']),
        message: j['message'],
        status: BidStatus.from(j['status']),
        createdAt: _dt(j['created_at']),
      );
}

class Booking {
  final String id, requestId, bidId, clientId, providerId;
  final double agreedPrice;
  final BookingStatus status;
  final UserRole? cancelledBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Booking({
    required this.id,
    required this.requestId,
    required this.bidId,
    required this.clientId,
    required this.providerId,
    required this.agreedPrice,
    required this.status,
    this.cancelledBy,
    required this.createdAt,
    this.completedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'],
        requestId: j['request_id'],
        bidId: j['bid_id'],
        clientId: j['client_id'],
        providerId: j['provider_id'],
        agreedPrice: _d(j['agreed_price']),
        status: BookingStatus.from(j['status']),
        cancelledBy: j['cancelled_by'] == null ? null : UserRole.from(j['cancelled_by']),
        createdAt: _dt(j['created_at']),
        completedAt: j['completed_at'] == null ? null : _dt(j['completed_at']),
      );
}

class ChatMessage {
  final String id, bookingId, senderId, senderName, text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        bookingId: j['booking_id'],
        senderId: j['sender_id'],
        senderName: j['sender_name'],
        text: j['text'],
        createdAt: _dt(j['created_at']),
      );
}

class Review {
  final String id, bookingId, requestId, clientId, clientName, providerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.requestId,
    required this.clientId,
    required this.clientName,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'],
        bookingId: j['booking_id'],
        requestId: j['request_id'],
        clientId: j['client_id'],
        clientName: j['client_name'],
        providerId: j['provider_id'],
        rating: j['rating'],
        comment: j['comment'],
        createdAt: _dt(j['created_at']),
      );
}
