import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/daos/crop_dao.dart';
import '../../database/daos/task_dao.dart';

class FarmRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Crop>> getCropsByUser(String userId) async {
    final data = await _supabase.from('crops').select().eq('user_id', userId).order('created_at', ascending: false);
    return data.map((json) => Crop.fromMap(json)).toList();
  }

  Future<Crop> insertCrop(Crop crop) async {
    final data = await _supabase.from('crops').insert(crop.toInsertMap()).select().single();
    return Crop.fromMap(data);
  }

  Future<void> updateCrop(Crop crop) async {
    await _supabase.from('crops').update(crop.toUpdateMap()).eq('id', crop.id);
  }

  Future<void> deleteCrop(String cropId) async {
    await _supabase.from('crops').delete().eq('id', cropId);
  }

  Future<List<FarmTask>> getTasksByUser(String userId) async {
    final data = await _supabase.from('tasks').select().eq('user_id', userId).order('created_at', ascending: false);
    return data.map((json) => FarmTask.fromMap(json)).toList();
  }

  Future<FarmTask> insertTask(FarmTask task) async {
    final data = await _supabase.from('tasks').insert(task.toInsertMap()).select().single();
    return FarmTask.fromMap(data);
  }

  Future<void> updateTask(FarmTask task) async {
    await _supabase.from('tasks').update(task.toUpdateMap()).eq('id', task.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
