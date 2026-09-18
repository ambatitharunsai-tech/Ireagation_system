import 'package:flutter/material.dart';

import '../data/repositories/farm_repository.dart';
import '../database/daos/crop_dao.dart';
import '../database/daos/task_dao.dart';
import '../services/local_cache_service.dart';

class FarmProvider extends ChangeNotifier {
  final FarmRepository _repo = FarmRepository();
  final LocalCacheService _cache = LocalCacheService();

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
      _crops = await _repo.getCropsByUser(userId);
      _tasks = await _repo.getTasksByUser(userId);

      // Update Cache
      await _cache.saveFarmData(userId, {
        'crops': _crops.map((c) => c.toMap()).toList(),
        'tasks': _tasks.map((t) => t.toMap()).toList(),
      });
    } catch (e) {
      _error =
          'Could not load farm data from server. Attempting offline cache...';
      debugPrint('FarmProvider.loadData error: $e');

      // Fallback to cache
      final cached = await _cache.getFarmData(userId);
      if (cached != null) {
        _crops = (cached['crops'] as List).map((c) => Crop.fromMap(c)).toList();
        _tasks = (cached['tasks'] as List)
            .map((t) => FarmTask.fromMap(t))
            .toList();
      } else {
        _error = 'No offline data available. Please check connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCrop(Crop crop) async {
    try {
      final saved = await _repo.insertCrop(crop);
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
      await _repo.updateCrop(crop);
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
      await _repo.deleteCrop(cropId);
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
      final saved = await _repo.insertTask(task);
      _tasks.insert(0, saved);
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
      await _repo.updateTask(task);
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
      await _repo.deleteTask(taskId);
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
