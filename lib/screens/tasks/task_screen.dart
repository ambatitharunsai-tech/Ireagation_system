import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

import '../../providers/farm_provider.dart';
import '../../database/daos/task_dao.dart';
import '../../widgets/add_task_dialog.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final farm = Provider.of<FarmProvider>(context);
    final pending = farm.tasks.where((t) => t.status == 'Pending').toList();
    final inProgress = farm.tasks
        .where((t) => t.status == 'In Progress')
        .toList();
    final done = farm.tasks.where((t) => t.status == 'Done').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('Farm Tasks')),
        actions: [
          if (farm.tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${done.length}/${farm.tasks.length} ${lang.t("done")}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: farm.tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    lang.t('No tasks yet'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(lang.t('Tap + to create one')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader(
                    lang.t('Pending'),
                    pending.length,
                    Colors.orange,
                  ),
                  ...pending.map((t) => _buildTaskCard(context, t, farm, lang)),
                  const SizedBox(height: 16),
                ],
                if (inProgress.isNotEmpty) ...[
                  _buildSectionHeader(
                    lang.t('In Progress'),
                    inProgress.length,
                    Colors.blue,
                  ),
                  ...inProgress.map(
                    (t) => _buildTaskCard(context, t, farm, lang),
                  ),
                  const SizedBox(height: 16),
                ],
                if (done.isNotEmpty) ...[
                  _buildSectionHeader(
                    lang.t('Done'),
                    done.length,
                    Colors.green,
                  ),
                  ...done.map((t) => _buildTaskCard(context, t, farm, lang)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "tasks_fab",
        onPressed: () => AddTaskDialog.show(context),
        icon: const Icon(Icons.add),
        label: Text(lang.t('Add Task')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    FarmTask task,
    FarmProvider farm,
    LanguageProvider lang,
  ) {
    final priorityColor = task.priority == 'High'
        ? Colors.red
        : task.priority == 'Medium'
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.status == 'Done',
          onChanged: (val) {
            task.status = val == true ? 'Done' : 'Pending';
            farm.updateTask(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == 'Done'
                ? TextDecoration.lineThrough
                : null,
            color: task.status == 'Done' ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              task.date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lang.t(task.priority), // Assume priority string is translated
                style: TextStyle(
                  fontSize: 10,
                  color: priorityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              farm.deleteTask(task.id);
            } else {
              task.status = value;
              farm.updateTask(task);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(value: 'Pending', child: Text(lang.t('Pending'))),
            PopupMenuItem(
              value: 'In Progress',
              child: Text(lang.t('In Progress')),
            ),
            PopupMenuItem(value: 'Done', child: Text(lang.t('Done'))),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)), // Delete might not need translation if icon/red is clear, but let's translate if added
            ),
          ],
        ),
      ),
    );
  }
}
