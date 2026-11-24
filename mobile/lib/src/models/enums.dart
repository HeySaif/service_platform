enum UserRole {
  client('CLIENT'),
  provider('PROVIDER');

  const UserRole(this.db);
  final String db;
  static UserRole from(String v) => values.firstWhere((e) => e.db == v);
}

enum ServiceCategory {
  electrical('ELECTRICAL', 'Electrical'),
  plumbing('PLUMBING', 'Plumbing'),
  acRepair('AC_REPAIR', 'AC Repair'),
  cleaning('CLEANING', 'Cleaning'),
  carpentry('CARPENTRY', 'Carpentry'),
  painting('PAINTING', 'Painting'),
  handyman('HANDYMAN', 'General Handyman');

  const ServiceCategory(this.db, this.label);
  final String db;
  final String label;
  static ServiceCategory from(String v) => values.firstWhere((e) => e.db == v);
}

enum RequestStatus {
  open('OPEN'),
  booked('BOOKED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const RequestStatus(this.db);
  final String db;
  static RequestStatus from(String v) => values.firstWhere((e) => e.db == v);
}

enum BidStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  withdrawn('WITHDRAWN');

  const BidStatus(this.db);
  final String db;
  static BidStatus from(String v) => values.firstWhere((e) => e.db == v);
}

enum BookingStatus {
  confirmed('CONFIRMED'),
  workDone('WORK_DONE'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const BookingStatus(this.db);
  final String db;
  static BookingStatus from(String v) => values.firstWhere((e) => e.db == v);
}
