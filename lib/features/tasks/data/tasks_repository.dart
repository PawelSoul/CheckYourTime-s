import '../../../data/db/daos/tasks_dao.dart';

abstract class TasksRepository {
  Stream<List<TaskRow>> watchAll({bool includeArchived = false});
}
