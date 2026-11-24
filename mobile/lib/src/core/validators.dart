/// Form validators from docs/04_USER_FLOWS_AND_SCREENS.md.
class Validators {
  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? Function(String?) length(String field, int min, int max) =>
      (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return '$field is required';
        if (t.length < min || t.length > max) {
          return '$field must be $min–$max characters';
        }
        return null;
      };

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Email is required';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter a valid email';
  }

  static String? password(String? v) =>
      (v == null || v.length < 6) ? 'At least 6 characters' : null;

  static String? positiveNumber(String? v, {bool optional = false}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return optional ? null : 'Required';
    final n = double.tryParse(t);
    return (n == null || n <= 0) ? 'Enter a positive number' : null;
  }
}
