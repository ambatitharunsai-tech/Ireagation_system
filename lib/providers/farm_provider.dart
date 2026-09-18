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

  bool _isLoadingCrops = false;
  bool _isLoadingTasks = false;

  bool _isOffline = false;

  String? _cropError;
  String? _taskError;

  List<Crop> get crops => _crops;
  List<FarmTask> get tasks => _tasks;

  bool get isLoading => _isLoadingCrops || _isLoadingTasks;
  bool get isLoadingCrops => _isLoadingCrops;
  bool get isLoadingTasks => _isLoadingTasks;

  bool get isOffline => _isOffline;

  String? get error => _cropError ?? _taskError;
  String? get cropError => _cropError;
  String? get taskError => _taskError;

  int get activeCropCount => _crops.where((c) => c.status == 'Active').length;
  int get harvestedCropCount =>
      _crops.where((c) => c.status == 'Harvested').length;
  int get inactiveCropCount =>
      _crops.where((c) => c.status == 'Inactive').length;
  int get pendingTaskCount => _tasks.where((t) => t.status == 'Pending').length;

  Future<void> loadData(String userId) async {
    loadCrops(userId);
    loadTasks(userId);
  }

  Future<void> loadCrops(String userId) async {
    _isLoadingCrops = true;
    _cropError = null;
    notifyListeners();

    try {
      _crops = await _repo.getCropsByUser(userId);
      _isOffline = false;

      // Update Cache
      final currentCache = await _cache.getFarmData(userId) ?? {};
      currentCache['crops'] = _crops.map((c) => c.toMap()).toList();
      await _cache.saveFarmData(userId, currentCache);
    } catch (e) {
      _isOffline = true;
      _cropError = 'Could not load crops from server. Showing cached data.';
      debugPrint('FarmProvider.loadCrops error: $e');

      // Fallback to cache
      final cached = await _cache.getFarmData(userId);
      if (cached != null && cached['crops'] != null) {
        _crops = (cached['crops'] as List).map((c) => Crop.fromMap(c)).toList();
      } else {
        _cropError = 'No offline data available. Please check connection.';
      }
    } finally {
      _isLoadingCrops = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks(String userId) async {
    _isLoadingTasks = true;
    _taskError = null;
    notifyListeners();

    try {
      _tasks = await _repo.getTasksByUser(userId);

      // Update Cache
      final currentCache = await _cache.getFarmData(userId) ?? {};
      currentCache['tasks'] = _tasks.map((t) => t.toMap()).toList();
      await _cache.saveFarmData(userId, currentCache);
    } catch (e) {
      _taskError = 'Could not load tasks from server. Showing cached data.';
      debugPrint('FarmProvider.loadTasks error: $e');

      // Fallback to cache
      final cached = await _cache.getFarmData(userId);
      if (cached != null && cached['tasks'] != null) {
        _tasks = (cached['tasks'] as List)
            .map((t) => FarmTask.fromMap(t))
            .toList();
      } else {
        _taskError = 'No offline tasks available.';
      }
    } finally {
      _isLoadingTasks = false;
      notifyListeners();
    }
  }

  Future<bool> addCrop(Crop crop) async {
    try {
      final saved = await _repo.insertCrop(crop);
      _crops.insert(0, saved);

      // Update cache
      final currentCache = await _cache.getFarmData(crop.userId) ?? {};
      currentCache['crops'] = _crops.map((c) => c.toMap()).toList();
      await _cache.saveFarmData(crop.userId, currentCache);

      notifyListeners();
      return true;
    } catch (e) {
      _cropError = 'Failed to save crop.';
      debugPrint('FarmProvider.addCrop error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCrop(Crop crop) async {
    try {
      await _repo.updateCrop(crop);
      final index = _crops.indexWhere((c) => c.id == crop.id);
      if (index != -1) {
        _crops[index] = crop;
      }

      // Update cache
      final currentCache = await _cache.getFarmData(crop.userId) ?? {};
      currentCache['crops'] = _crops.map((c) => c.toMap()).toList();
      await _cache.saveFarmData(crop.userId, currentCache);

      notifyListeners();
      return true;
    } catch (e) {
      _cropError = 'Failed to update crop.';
      debugPrint('FarmProvider.updateCrop error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCrop(String cropId, String userId) async {
    try {
      await _repo.deleteCrop(cropId);
      _crops.removeWhere((c) => c.id == cropId);

      // Update cache
      final currentCache = await _cache.getFarmData(userId) ?? {};
      currentCache['crops'] = _crops.map((c) => c.toMap()).toList();
      await _cache.saveFarmData(userId, currentCache);

      notifyListeners();
      return true;
    } catch (e) {
      _cropError = 'Failed to delete crop.';
      debugPrint('FarmProvider.deleteCrop error: $e');
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
      _taskError = 'Failed to save task.';
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
      _taskError = 'Failed to update task.';
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
      _taskError = 'Failed to delete task.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _cropError = null;
    _taskError = null;
    notifyListeners();
  }
}
