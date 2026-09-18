import 'package:flutter/foundation.dart';
import '../local_database.dart';

/// Task data model.
class FarmTask {
  final String id;
  final String userId;
  final String? cropId;
  String title;
  String date;
  String priority; // Low, Medium, High
  String status; // Pending, In Progress, Done
  String? notes;

  FarmTask({
    required this.id,
    required this.userId,
    this.cropId,
    required this.title,
    required this.date,
    required this.priority,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'crop_id': cropId,
      'title': title,
      'date': date,
      'priority': priority,
      'status': status,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'date': date,
      'priority': priority,
      'status': status,
      'notes': notes,
    };
  }

  factory FarmTask.fromMap(Map<String, dynamic> map) {
    return FarmTask(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      cropId: map['crop_id'],
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? 'Pending',
      notes: map['notes'],
    );
  }
}

/// Data access object for task operations using LocalDatabase.
class TaskDao {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<FarmTask> insertTask(FarmTask task) async {
    return await _db.insertTask(task);
  }

  Future<List<FarmTask>> getTasksByUser(String userId) async {
    return await _db.getTasksByUser(userId);
  }

  Future<void> updateTask(FarmTask task) async {
    // In our LocalDatabase, updateTaskStatus modifies status, but we can reuse insert for full updates
    await _db.insertTask(task); 
  }

  Future<void> deleteTask(String taskId) async {
    await _db.deleteTask(taskId);
  }
}
