import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'daos/crop_dao.dart';
import 'daos/task_dao.dart';
import 'daos/finance_dao.dart';
import '../services/auth_service.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  SharedPreferences? _prefs;
  final _uuid = const Uuid();

  LocalDatabase._init();

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Auth ---
  Future<AppUser?> login(String email, String password) async {
    final p = await prefs;
    final usersStr = p.getString('users') ?? '{}';
    final users = json.decode(usersStr) as Map<String, dynamic>;
    
    for (var u in users.values) {
      if (u['email'] == email && u['password'] == password) {
        return AppUser.fromMap(u);
      }
    }
    return null;
  }

  Future<AppUser> register(String name, String email, String password) async {
    final p = await prefs;
    final usersStr = p.getString('users') ?? '{}';
    final users = json.decode(usersStr) as Map<String, dynamic>;
    
    for (var u in users.values) {
      if (u['email'] == email) {
        throw Exception('User already registered');
      }
    }

    final id = _uuid.v4();
    final newUser = {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
    
    users[id] = newUser;
    await p.setString('users', json.encode(users));
    
    return AppUser.fromMap(newUser);
  }

  Future<void> updateProfile(AppUser user) async {
    final p = await prefs;
    final usersStr = p.getString('users') ?? '{}';
    final users = json.decode(usersStr) as Map<String, dynamic>;
    
    if (users.containsKey(user.id)) {
      final existing = users[user.id];
      users[user.id] = {
        ...existing,
        ...user.toMap(),
      };
      await p.setString('users', json.encode(users));
    }
  }

  // --- Crops ---
  Future<Crop> insertCrop(Crop crop) async {
    final p = await prefs;
    final id = crop.id.isEmpty ? _uuid.v4() : crop.id;
    final cropsStr = p.getString('crops') ?? '{}';
    final crops = json.decode(cropsStr) as Map<String, dynamic>;
    
    final map = crop.toInsertMap();
    map['id'] = id;
    crops[id] = map;
    
    await p.setString('crops', json.encode(crops));
    return Crop.fromMap(map);
  }

  Future<List<Crop>> getCropsByUser(String userId) async {
    final p = await prefs;
    final cropsStr = p.getString('crops') ?? '{}';
    final crops = json.decode(cropsStr) as Map<String, dynamic>;
    
    return crops.values
        .where((c) => c['user_id'] == userId)
        .map((c) => Crop.fromMap(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateCrop(Crop crop) async {
    await insertCrop(crop);
  }

  Future<void> deleteCrop(String cropId) async {
    final p = await prefs;
    final cropsStr = p.getString('crops') ?? '{}';
    final crops = json.decode(cropsStr) as Map<String, dynamic>;
    crops.remove(cropId);
    await p.setString('crops', json.encode(crops));
  }

  // --- Tasks ---
  Future<FarmTask> insertTask(FarmTask task) async {
    final p = await prefs;
    final id = task.id.isEmpty ? _uuid.v4() : task.id;
    final tasksStr = p.getString('tasks') ?? '{}';
    final tasks = json.decode(tasksStr) as Map<String, dynamic>;
    
    final map = task.toInsertMap();
    map['id'] = id;
    tasks[id] = map;
    
    await p.setString('tasks', json.encode(tasks));
    return FarmTask.fromMap(map);
  }

  Future<List<FarmTask>> getTasksByUser(String userId) async {
    final p = await prefs;
    final tasksStr = p.getString('tasks') ?? '{}';
    final tasks = json.decode(tasksStr) as Map<String, dynamic>;
    
    return tasks.values
        .where((t) => t['user_id'] == userId)
        .map((t) => FarmTask.fromMap(t as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    final p = await prefs;
    final tasksStr = p.getString('tasks') ?? '{}';
    final tasks = json.decode(tasksStr) as Map<String, dynamic>;
    
    if (tasks.containsKey(taskId)) {
      tasks[taskId]['status'] = status;
      await p.setString('tasks', json.encode(tasks));
    }
  }

  Future<void> deleteTask(String taskId) async {
    final p = await prefs;
    final tasksStr = p.getString('tasks') ?? '{}';
    final tasks = json.decode(tasksStr) as Map<String, dynamic>;
    tasks.remove(taskId);
    await p.setString('tasks', json.encode(tasks));
  }

  // --- Finance ---
  Future<Expense> insertExpense(Expense expense) async {
    final p = await prefs;
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final expensesStr = p.getString('expenses') ?? '{}';
    final expenses = json.decode(expensesStr) as Map<String, dynamic>;
    
    final map = expense.toInsertMap();
    map['id'] = id;
    expenses[id] = map;
    
    await p.setString('expenses', json.encode(expenses));
    return Expense.fromMap(map);
  }

  Future<List<Expense>> getExpensesByUser(String userId) async {
    final p = await prefs;
    final expensesStr = p.getString('expenses') ?? '{}';
    final expenses = json.decode(expensesStr) as Map<String, dynamic>;
    
    final list = expenses.values
        .where((e) => e['user_id'] == userId)
        .map((e) => Expense.fromMap(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> deleteExpense(String expenseId) async {
    final p = await prefs;
    final expensesStr = p.getString('expenses') ?? '{}';
    final expenses = json.decode(expensesStr) as Map<String, dynamic>;
    expenses.remove(expenseId);
    await p.setString('expenses', json.encode(expenses));
  }

  Future<Sale> insertSale(Sale sale) async {
    final p = await prefs;
    final id = sale.id.isEmpty ? _uuid.v4() : sale.id;
    final salesStr = p.getString('sales') ?? '{}';
    final sales = json.decode(salesStr) as Map<String, dynamic>;
    
    final map = sale.toInsertMap();
    map['id'] = id;
    sales[id] = map;
    
    await p.setString('sales', json.encode(sales));
    return Sale.fromMap(map);
  }

  Future<List<Sale>> getSalesByUser(String userId) async {
    final p = await prefs;
    final salesStr = p.getString('sales') ?? '{}';
    final sales = json.decode(salesStr) as Map<String, dynamic>;
    
    final list = sales.values
        .where((s) => s['user_id'] == userId)
        .map((s) => Sale.fromMap(s as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> deleteSale(String saleId) async {
    final p = await prefs;
    final salesStr = p.getString('sales') ?? '{}';
    final sales = json.decode(salesStr) as Map<String, dynamic>;
    sales.remove(saleId);
    await p.setString('sales', json.encode(sales));
  }
}
