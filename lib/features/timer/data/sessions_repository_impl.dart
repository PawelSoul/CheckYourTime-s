import 'dart:async';
import 'sessions_repository.dart';

class InMemorySessionsRepository implements SessionsRepository {
  final _controller = StreamController<List<CompletedSession>>.broadcast();
  final List<CompletedSession> _items = [];

  InMemorySessionsRepository() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<CompletedSession>> watchAll() => _controller.stream;

  @override
  Future<void> add(CompletedSession session) async {
    _items.insert(0, session);
    _controller.add(List.unmodifiable(_items));
  }

  void dispose() {
    _controller.close();
  }
}
