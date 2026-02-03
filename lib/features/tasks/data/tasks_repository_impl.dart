import '../../../data/db/daos/tasks_dao.dart';
import 'tasks_repository.dart';

class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl(this._dao);

  final TasksDao _dao;

  @override
  Stream<List<TaskRow>> watchAll({bool includeArchived = false}) {
    return _dao.watchAll(includeArchived: includeArchived);
  }
}
