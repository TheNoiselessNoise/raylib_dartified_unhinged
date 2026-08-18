part of '../../raylib_dartified_unhinged.dart';

class _RecordedEvent<T extends App<T>> {
  final Event<T> event;
  final double simTime;
  final EventScope? scope;
  final ECSBase<T>? origin;
  final bool wasEmitted;
  final bool wasDispatched;

  const _RecordedEvent({
    required this.event,
    required this.simTime,
    required this.scope,
    required this.origin,
    required this.wasEmitted,
    required this.wasDispatched,
  });
}

typedef IsAnyEventHistoryHolder<T extends App<T>> = IsEventHistoryHolder<T, ECSBase<T>>;

/// Records dispatched events for time-windowed queries and replay.
/// Mixed in alongside IsEventQueueHolder on root App.
mixin IsEventHistoryHolder<
  T extends App<T>,
  E extends ECSBase<T>
> on IsEventEmittable<T, E> {

  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██   ░██         
  // ░██████████ ░██     ░██ ░██     ░██ ░███████     ░████████  
  // ░██     ░██ ░██     ░██ ░██     ░██ ░██   ░██           ░██ 
  // ░██     ░██  ░██   ░██   ░██   ░██  ░██    ░██   ░██   ░██  
  // ░██     ░██   ░██████     ░██████   ░██     ░██   ░██████   

  late final hookOnBeforeEventRecordedKey = ECSHookKey<bool Function(E self, Event<T> event)>(
    'IsEventHistoryHolder', 'onBeforeEventRecorded'
  );
  
  late final hookOnEventRecordedKey = ECSHookKey<void Function(E self, Event<T> event)>(
    'IsEventHistoryHolder', 'onEventRecorded'
  );

  Iterable<bool Function(E self, Event<T> event)> get _onBeforeEventRecordedFns
    => hooksOf(hookOnBeforeEventRecordedKey);

  Iterable<void Function(E self, Event<T> event)> get _onEventRecordedFns
    => hooksOf(hookOnEventRecordedKey);

  /// Registers [fn] as a before-event-record listener.
  ///
  /// [fn] returning `false` cancels the event recording.
  @nonVirtual
  E listenOnBeforeEventRecorded(bool Function(E self, Event<T> event) fn) {
    addHook(hookOnBeforeEventRecordedKey, fn);
    return self;
  }

  /// Registers [fn] to be called for every event recorded.
  ///
  /// Listeners are called in registration order.
  @nonVirtual
  E listenOnEventRecorded(void Function(E self, Event<T> event) fn) {
    addHook(hookOnEventRecordedKey, fn);
    return self;
  }

  /// Runs all before-event-record listeners and [onBeforeEventRecorded].
  ///
  /// Returns `false` if any listener or the override cancels the event recording.
  bool _doOnBeforeEventRecorded(Event<T> event) {
    if (!_onBeforeEventRecordedFns.every((f) => f(self, event))) return false;
    return onBeforeEventRecorded(event);
  }

  /// Propagates [event] through listeners and the [onEventRecorded] hook.
  void _doOnEventRecorded(Event<T> event) {
    _onEventRecordedFns.forEach((f) => f(self, event));
    onEventRecorded(event);
  }

  /// Override to cancel an event handling from within the class.
  ///
  /// Return `false` to abort. Called after all registered [listenOnBeforeEventRecorded] listeners.
  bool onBeforeEventRecorded(Event<T> event) => true;

  /// Override to handle incoming events within the class.
  ///
  /// Called after all registered [listenOnEventRecorded] listeners, and only if
  /// propagation has not been stopped.
  void onEventRecorded(Event<T> event) {}

  // ░██████░███     ░███ ░█████████  ░██         
  //   ░██  ░████   ░████ ░██     ░██ ░██         
  //   ░██  ░██░██ ░██░██ ░██     ░██ ░██         
  //   ░██  ░██ ░████ ░██ ░█████████  ░██         
  //   ░██  ░██  ░██  ░██ ░██         ░██         
  //   ░██  ░██       ░██ ░██         ░██         
  // ░██████░██       ░██ ░██         ░██████████ 

  late final stateEventHistoryKey = ECSStateKey<List<_RecordedEvent<T>>>(
    'IsEventHistoryHolder', 'eventHistory',
    get: () => .from(_eventHistory),
    set: (value) => _eventHistory = value,
  );

  @override
  @mustCallSuper
  void _registerBuiltinStateKeys() {
    super._registerBuiltinStateKeys();
    registerStateKey(stateEventHistoryKey);
  }

  List<_RecordedEvent<T>> _eventHistory = [];

  Iterable<Event<T>> get eventHistory => _eventHistory.map((e) => e.event);

  /// How long (in sim-scaled seconds) to retain events before pruning.
  /// Null = keep forever.
  double? get eventHistoryRetention => 10.0;

  IsAnyEventHistoryHolder<T> get _eventHolderRoot => app;

  void _recordEvent(Event<T> event) {
    if (!_doOnBeforeEventRecorded(event)) return;
    _eventHistory.add(.new(
      event: event,
      simTime: app.time.timeScaled,
      scope: event.scope,
      origin: event.origin,
      wasEmitted: event._wasEmitted,
      wasDispatched: event._wasDispatched,
    ));
    _pruneEventHistory();
    _doOnEventRecorded(event);
  }

  void _tryToRecordEvent(Event<T> event) {
    if (identical(self, _eventHolderRoot)) { // i am root
      if (event._rootRecorded) return;
      event._rootRecorded = true;
      _recordEvent(event);
      return;
    }

    // i am origin
    if (event._originRecorded) return;
    event._originRecorded = true;

    // record to ourselves (origin)
    _recordEvent(event);
    // try to record to root
    // due to event's scope, it will probably never reach the root
    // so that's why we do it here explicitly
    _eventHolderRoot._tryToRecordEvent(event);
  }

  void _pruneEventHistory() {
    final retention = eventHistoryRetention;
    if (retention == null) return;
    final cutoff = app.time.timeScaled - retention;
    _eventHistory.removeWhere((e) => e.simTime < cutoff);
  }

  /// Clears history of recorded events.
  void clearEventHistory() => _eventHistory.clear();

  List<_RecordedEvent<T>> _getEventRecords({
    double? duration,
    ECSBase<T>? origin,
    bool Function(Event<T> event)? filter,
  }) {
    var events = _eventHistory.where((e) => origin == null || e.event.origin == origin);

    if (duration != null) {
      final cutoff = app.time.timeScaled - duration;
      events = events.where((e) => e.simTime >= cutoff);
    }

    if (filter != null) {
      events = events.where((e) => filter(e.event));
    }

    return events.toList();
  }

  /// Events dispatched within the last [duration] sim-scaled seconds,
  /// optionally filtered to a specific origin.
  List<Event<T>> getRecordedEvents({
    double? duration,
    ECSBase<T>? origin,
    bool Function(Event<T> event)? filter,
  }) => _getEventRecords(
    duration: duration,
    origin: origin,
    filter: filter,
  ).map((e) => e.event).toList();

  /// Re-dispatches events from [fromTime] sim-scaled seconds ago to now.
  void replayRecordedEvents({
    double? fromTime,
    ECSBase<T>? origin,
    bool Function(Event<T> event)? filter,
  }) {
    final records = _getEventRecords(
      duration: fromTime != null ? -fromTime : null,
      origin: origin,
      filter: filter,
    );

    for (final rec in records) {
      assert(!(rec.wasEmitted && rec.wasDispatched), "Event was emitted and dispatched, this should not happen.");

      final e = rec.event;
      final eventOrigin = rec.origin;
      e.scope = rec.scope;

      if (rec.wasEmitted) {

        if (eventOrigin case IsAnyEventEmittable<T> emittable) {
          emittable.emit(e);
          continue;
        }

        if (rec.scope != .self && rec.scope != .local) {
          // Scene-or-broader scope with a non-emittable origin: Root is the
          // correct re-entry point, propagation still happens normally from here.
          _eventHolderRoot.emit(e);
          continue;
        }

        // .self/.local scope with a non-emittable origin: there is no valid
        // replay target. The original emitter could propagate from itself
        // because it WAS the emittable origin; without that, Root can't safely
        // stand in, since Root emitting with .self/.local scope means the event
        // goes no further than Root, which is not what the original emit meant.
        throw StateError(
          'Cannot replay event ${e.runtimeType} (scope: ${rec.scope}): origin '
          '$eventOrigin does not implement IsAnyEventEmittable, and scope '
          '${rec.scope} cannot be safely re-emitted from Root ($_eventHolderRoot).',
        );
      
      } else if (rec.wasDispatched) {

        if (eventOrigin case IsAnyEventEmittable<T> emittable) {
          emittable.dispatch(e);
          continue;
        }

        if (rec.scope != .self && rec.scope != .local) {
          // Scene-or-broader scope with a non-emittable origin: Root is the
          // correct re-entry point, propagation still happens normally from here.
          _eventHolderRoot.dispatch(e);
          continue;
        }

        // .self/.local scope with a non-emittable origin: there is no valid
        // replay target. The original emitter could propagate from itself
        // because it WAS the emittable origin; without that, Root can't safely
        // stand in, since Root dispatching with .self/.local scope means the event
        // goes no further than Root, which is not what the original dispatch meant.
        throw StateError(
          'Cannot replay event ${e.runtimeType} (scope: ${rec.scope}): origin '
          '$eventOrigin does not implement IsAnyEventEmittable, and scope '
          '${rec.scope} cannot be safely re-dispatched from Root ($_eventHolderRoot).',
        );
      
      } else {
        throw StateError('Unhandled event state. Nor emitted or dispatched!');
      }
    }
  }
}