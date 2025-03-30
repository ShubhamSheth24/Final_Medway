import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Reminder {
  final int id;
  final String medicine;
  final String dosage;
  final List<TimeOfDay> times;
  final bool isDaily;
  final Timestamp? timestamp;

  Reminder({
    required this.id,
    required this.medicine,
    required this.dosage,
    required this.times,
    required this.isDaily,
    this.timestamp,
  });

  // Factory constructor to create a Reminder from Firestore data
  factory Reminder.fromFirestore(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final timesList =
        (data['times'] as List<dynamic>).map((timeStr) {
          final timeParts = timeStr.toString().split(' ')[0].split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          if (timeStr.toString().contains('PM') && hour < 12) {
            hour += 12;
          } else if (timeStr.toString().contains('AM') && hour == 12) {
            hour = 0;
          }
          return TimeOfDay(hour: hour, minute: minute);
        }).toList();

    return Reminder(
      id: int.parse(doc.id),
      medicine: data['medicine'] ?? 'Unknown',
      dosage: data['dosage'] ?? 'N/A',
      times: timesList,
      isDaily: data['isDaily'] ?? true,
      timestamp: data['timestamp'] as Timestamp?,
    );
  }

  // Method to convert Reminder to Firestore-compatible map
  Map<String, dynamic> toFirestore(BuildContext context) {
    return {
      'medicine': medicine,
      'dosage': dosage,
      'times': times.map((time) => time.format(context)).toList(),
      'isDaily': isDaily,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      // 'taken' is managed separately in medicines_reminder.dart
    };
  }
}
