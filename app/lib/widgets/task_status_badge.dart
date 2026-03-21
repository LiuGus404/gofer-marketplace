import 'package:flutter/material.dart';

class TaskStatusBadge extends StatelessWidget {
  final String status;

  const TaskStatusBadge({super.key, required this.status});

  Color _color() {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'claimed':
        return Colors.orange;
      case 'in-progress':
        return Colors.indigo;
      case 'submitted':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'disputed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _label() {
    switch (status) {
      case 'open':
        return 'OPEN';
      case 'claimed':
        return 'CLAIMED';
      case 'in-progress':
        return 'IN PROGRESS';
      case 'submitted':
        return 'SUBMITTED';
      case 'completed':
        return 'COMPLETED';
      case 'disputed':
        return 'DISPUTED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color().withOpacity(0.5)),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color(),
        ),
      ),
    );
  }
}
