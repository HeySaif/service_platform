import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';

String pkr(double v) => 'PKR ${NumberFormat.decimalPattern().format(v.round())}';

IconData categoryIcon(ServiceCategory c) => switch (c) {
      ServiceCategory.electrical => Icons.electrical_services,
      ServiceCategory.plumbing => Icons.plumbing,
      ServiceCategory.acRepair => Icons.ac_unit,
      ServiceCategory.cleaning => Icons.cleaning_services,
      ServiceCategory.carpentry => Icons.carpenter,
      ServiceCategory.painting => Icons.format_paint,
      ServiceCategory.handyman => Icons.handyman,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

Color requestStatusColor(RequestStatus s) => switch (s) {
      RequestStatus.open => Colors.blue,
      RequestStatus.booked => Colors.orange,
      RequestStatus.completed => Colors.green,
      RequestStatus.cancelled => Colors.grey,
    };

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap});
  final ServiceRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(categoryIcon(r.category))),
        title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${r.category.label} • ${r.areaName}, ${r.city}\n'
            '${r.budgetPkr != null ? pkr(r.budgetPkr!) : 'No budget set'}'
            '${r.status == RequestStatus.open ? ' • ${r.bidCount} bid${r.bidCount == 1 ? '' : 's'}' : ''}'),
        isThreeLine: true,
        trailing: StatusChip(r.status.db, color: requestStatusColor(r.status)),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 8),
            const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            const Text('Check your connection and pull down to retry.', textAlign: TextAlign.center),
          ]),
        ),
      );
}
