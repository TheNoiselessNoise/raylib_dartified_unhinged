part of '../../raylib_dartified_unhinged.dart';

/// Adds [Task] processing capabilities to an ECS object.
///
/// Tasks are queued and executed in a controlled pipeline each frame.
/// Listeners can intercept and cancel tasks before they reach [onTask] or execute.
mixin IsTaskProcessable<T extends App<T>, E extends ECSBase<T>> on Self<E>, HasAppAccess<T>, IsEventEmittable<T, E> {
  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  List<void Function(Task<T> task)> _onTaskFns = [];

  /// Registers [fn] to be called for each task before it is executed.
  @nonVirtual
  E listenOnTask(bool Function(Task<T> task) fn) {
    _onTaskFns.add(fn);
    return self;
  }

  bool _doCanceledTask(Task<T> task) {
    if (!task.isCanceled) return false;
    emit(EventTaskCancelled(app, task));
    return true;
  }

  // (internal) called by task system to propagate task
  // by default just call the hooks
  bool _doTask(Task<T> task, double dt) {
    final isFirstRun = !task._hasStarted;
    task._hasStarted = true;
    if (isFirstRun) emit(EventTaskStarting(app, task));
    if (_doCanceledTask(task)) return true;
    for (final f in _onTaskFns) {
      if (_doCanceledTask(task)) return true;
      f(task);
    }
    if (_doCanceledTask(task)) return true;
    if (isFirstRun) onTask(task);
    if (_doCanceledTask(task)) return true;
    final result = task._doUpdate(dt);
    if (result) emit(EventTaskFinished(app, task));
    return result;
  }

  /// Override to intercept tasks before they execute.
  ///
  /// Called after all [listenOnTask] listeners and before [Task] is executed.
  /// The task can be canceled here via [Task.cancel].
  void onTask(Task<T> task) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  Set<Task<T>> _taskQueue = {};
  
  Set<Task<T>> _pendingTaskQueue = {};

  /// Enqueues [task] for execution starting at the end of the current frame.
  @override
  void task(Task<T> task) {
    if (task._isQueued) return;
    task._isQueued = true;
    task._reset();
    _pendingTaskQueue.add(task);
  }

  /// Enqueues [task] and executes it immediately at the end of the current frame,
  /// if it isn't already running.
  @override
  E run(Task<T> task) {
    if (task._isQueued) return self;
    task._isQueued = true;
    task._reset();
    _pendingTaskQueue.add(task);

    final done = _doTask(task, time.dt);
    if (done) {
      _pendingTaskQueue.remove(task);
      task._isQueued = false;
    }
    return self;
  }

  void _processTasks(double dt) {
    if (_pendingTaskQueue.isNotEmpty) {
      _taskQueue.addAll(_pendingTaskQueue);
      _pendingTaskQueue.clear();
    }
    _taskQueue.removeWhere((task) {
      final done = _doTask(task, dt);
      if (done) task._isQueued = false;
      return done;
    });
  }

  /// Clears task queue.
  void clearTaskQueue() {
    _taskQueue.clear();
    _pendingTaskQueue.clear();
  }
}