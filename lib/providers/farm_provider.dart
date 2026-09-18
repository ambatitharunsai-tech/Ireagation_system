import 'package:flutter/material.dart';

import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';

/// Manages crop and task state with error resilience.
class FarmProvider extends ChangeNotifier {
  final CropDao _cropDao = CropDao();
  final TaskDao _taskDao = TaskDao();

  List<Crop> _crops = [];
  List<FarmTask> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Crop> get crops => _crops;
  List<FarmTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCropCount => _crops.where((c) => c.status == 'Active').length;
  int get pendingTaskCount => _tasks.where((t) => t.status == 'Pending').length;

  Future<void> loadData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _crops = await _cropDao.getCropsByUser(userId);
      _tasks = await _taskDao.getTasksByUser(userId);
    } catch (e) {
      _error = 'Could not load farm data. Check your connection.';
      debugPrint('FarmProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCrop(Crop crop) async {
    try {
      final saved = await _cropDao.insertCrop(crop);
      _crops.insert(0, saved);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save crop.';
      debugPrint('FarmProvider.addCrop error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCrop(Crop crop) async {
    try {
      await _cropDao.updateCrop(crop);
      final index = _crops.indexWhere((c) => c.id == crop.id);
      if (index != -1) _crops[index] = crop;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update crop.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCrop(String cropId) async {
    try {
      await _cropDao.deleteCrop(cropId);
      _crops.removeWhere((c) => c.id == cropId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete crop.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTask(FarmTask task) async {
    try {
      final saved = await _taskDao.insertTask(task);
      _tasks.add(saved);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save task.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(FarmTask task) async {
    try {
      await _taskDao.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) _tasks[index] = task;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update task.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _taskDao.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete task.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
