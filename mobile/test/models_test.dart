import 'package:flutter_test/flutter_test.dart';
import 'package:service_platform/src/models/models.dart';

void main() {
  test('enum db values round-trip', () {
    for (final c in ServiceCategory.values) {
      expect(ServiceCategory.from(c.db), c);
    }
    expect(BookingStatus.from('WORK_DONE'), BookingStatus.workDone);
    expect(BidStatus.from('WITHDRAWN'), BidStatus.withdrawn);
    expect(RequestStatus.from('OPEN'), RequestStatus.open);
    expect(UserRole.from('PROVIDER'), UserRole.provider);
  });

  test('ServiceRequest.fromJson handles null budget and numeric types', () {
    final r = ServiceRequest.fromJson({
      'id': 'r1',
      'client_id': 'u1',
      'client_name': 'Ali',
      'title': 'Fix socket',
      'category': 'ELECTRICAL',
      'description': 'Socket is sparking',
      'city': 'Lahore',
      'area_name': 'Johar Town',
      'budget_pkr': null,
      'photo_urls': <String>[],
      'status': 'OPEN',
      'bid_count': 0,
      'created_at': '2026-11-21T10:00:00Z',
    });
    expect(r.budgetPkr, isNull);
    expect(r.category, ServiceCategory.electrical);
    expect(r.status, RequestStatus.open);
  });

  test('Bid.fromJson reads int or double prices', () {
    final b = Bid.fromJson({
      'id': 'b1',
      'request_id': 'r1',
      'provider_id': 'p1',
      'provider_name': 'Usman',
      'provider_rating': 4,
      'proposed_price': 2500.5,
      'message': 'Can do today',
      'status': 'PENDING',
      'created_at': '2026-11-21T10:00:00Z',
    });
    expect(b.providerRating, 4.0);
    expect(b.proposedPrice, 2500.5);
    expect(b.status, BidStatus.pending);
  });

  test('Booking.fromJson parses optional cancelled_by / completed_at', () {
    final b = Booking.fromJson({
      'id': 'k1',
      'request_id': 'r1',
      'bid_id': 'b1',
      'client_id': 'u1',
      'provider_id': 'p1',
      'agreed_price': 3000,
      'status': 'CANCELLED',
      'cancelled_by': 'CLIENT',
      'created_at': '2026-11-21T10:00:00Z',
      'completed_at': null,
    });
    expect(b.cancelledBy, UserRole.client);
    expect(b.completedAt, isNull);
    expect(b.agreedPrice, 3000.0);
  });

  test('ProviderProfile.toInsert only sends editable fields', () {
    const p = ProviderProfile(
      userId: 'p1',
      displayName: 'Usman',
      bio: 'Electrician',
      categories: [ServiceCategory.electrical, ServiceCategory.handyman],
      city: 'Lahore',
      serviceAreas: ['DHA'],
    );
    final m = p.toInsert();
    expect(m['categories'], ['ELECTRICAL', 'HANDYMAN']);
    expect(m.containsKey('rating_average'), isFalse);
  });
}
