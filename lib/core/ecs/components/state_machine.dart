part of '../../raylib_dartified_unhinged.dart';

class CStateMachineStateDef {
  final String name;
  final void Function()? onEnter;
  final void Function()? onExit;
  final void Function(double dt)? onUpdate;

  CStateMachineStateDef(this.name, {this.onEnter, this.onExit, this.onUpdate});
}

class CStateMachineTransition {
  final String from;
  final String to;
  final bool Function() when;

  CStateMachineTransition(this.from, this.to, this.when);
}

class CStateMachine<T extends App<T>> extends Comp<T> {
  Map<String, CStateMachineStateDef> _states = {};
  List<CStateMachineTransition> _transitions = [];

  String? _current;
  double _timeInState = 0;
  bool _started = false;
  bool _entered = false; // guards onEnter firing exactly once per state entry

  String? get currentState => _current;
  double get timeInState => _timeInState;
  bool get isStarted => _started;

  CStateMachine(super.app, {
    Map<String, CStateMachineStateDef>? states,
    List<CStateMachineTransition>? transitions,
  }) :
    _states = states ?? {},
    _transitions = transitions ?? [];

  /// Define a state. Must be called before [start]. Calling after start
  /// throws, because addState defines the machine's shape once; it's not meant
  /// to be mutated while running.
  CStateMachine addState(
    String name, {
    void Function()? onEnter,
    void Function()? onExit,
    void Function(double dt)? onUpdate,
  }) {
    if (_started) {
      throw StateError(
        'addState("$name") called after start() — define all states before starting.',
      );
    }
    if (_states.containsKey(name)) {
      throw ArgumentError('State "$name" already defined.');
    }
    _states[name] = .new(
      name,
      onEnter: onEnter,
      onExit: onExit,
      onUpdate: onUpdate,
    );
    return this;
  }

  /// Define a transition. [when] is checked every [onUpdate] while the
  /// machine is in [from]; first matching transition wins, evaluated in
  /// the order they were added.
  CStateMachine transition(
    String from,
    String to, {
    required bool Function() when,
  }) {
    if (_started) {
      throw StateError(
        'transition("$from" -> "$to") called after start() — define transitions before starting.',
      );
    }
    _requireState(from);
    _requireState(to);
    _transitions.add(CStateMachineTransition(from, to, when));
    return this;
  }

  /// Start the machine in [initialState]. Fires that state's onEnter.
  CStateMachine start(String initialState) {
    if (_started) {
      throw StateError('start() called twice.');
    }
    _requireState(initialState);
    _started = true;
    _current = initialState;
    _timeInState = 0;
    _entered = false;
    return this;
  }

  bool inState(String name) => _current == name;

  /// Fires onEnter (if not already fired for this state), evaluates
  /// transitions, fires onExit when leaving, then calls onUpdate for
  /// whichever state is current after any transition.
  @override
  void onUpdate(double dt) {
    if (!_started || _current == null) return;

    final currentDef = _states[_current]!;

    if (!_entered) {
      _entered = true;
      currentDef.onEnter?.call();
    }

    // Evaluate transitions out of the current state, first match wins.
    for (final t in _transitions) {
      if (t.from != _current) continue;
      if (t.when()) {
        currentDef.onExit?.call();
        _current = t.to;
        _timeInState = 0;
        _entered = false;
        _states[t.to]!.onEnter?.call();
        _entered = true;
        break; // only one transition per frame
      }
    }

    _timeInState += dt;
    _states[_current]!.onUpdate?.call(dt);
  }

  void _requireState(String name) {
    if (!_states.containsKey(name)) {
      throw ArgumentError(
        'Unknown state "$name" — call addState("$name") first.',
      );
    }
  }
  
  // clone

  @override
  CStateMachine<T> createInstance() {
    final c = CStateMachine<T>(app);
    c._states = .from(_states);
    c._transitions = .from(_transitions);
    c._current = _current;
    c._timeInState = _timeInState;
    c._started = _started;
    c._entered = _entered;
    return c;
  }

  // state

  @override
  CStateMachineSnapshot<T> createSnapshot() {
    final snapshot = CStateMachineSnapshot<T>(namedId);
    snapshot._states = .from(_states);
    snapshot._transitions = .from(_transitions);
    snapshot._current = _current;
    snapshot._timeInState = _timeInState;
    snapshot._started = _started;
    snapshot._entered = _entered;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CStateMachineSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    _states = .from(snapshot._states);
    _transitions = .from(snapshot._transitions);
    _current = snapshot._current;
    _timeInState = snapshot._timeInState;
    _started = snapshot._started;
    _entered = snapshot._entered;
  }
}

class CStateMachineSnapshot<T extends App<T>> extends CompSnapshot<T, CStateMachine<T>> {
  late Map<String, CStateMachineStateDef> _states;
  late List<CStateMachineTransition> _transitions;
  late String? _current;
  late double _timeInState;
  late bool _started;
  late bool _entered;
  
  CStateMachineSnapshot(super.namedId);

  @override
  CStateMachine<T> createInstance(T app) {
    final c = CStateMachine<T>(app);
    c._states = .from(_states);
    c._transitions = .from(_transitions);
    c._current = _current;
    c._timeInState = _timeInState;
    c._started = _started;
    c._entered = _entered;
    return c;
  }
}