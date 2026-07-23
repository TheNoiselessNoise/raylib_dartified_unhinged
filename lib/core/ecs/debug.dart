part of '../raylib_dartified_unhinged.dart';

class DebugCompWidget<T extends App<T>> extends FWidget<T> {
  final DebugWidget<T> debugWidget;
  
  DebugCompWidget(super.app, this.debugWidget);

  late Comp<T> targetComp;

  final int _titleSize = 150;
  FSized<T> sizedTitle(String text, {int? width}) => FSized(app,
    heightMode: .flexible,
    width: width ?? _titleSize,
    child: FLabel(app, text: text),
  );

  List<FWidget<T>> buildDebugCompBaseControls() => [
    FRow(app,
      gap: 8,
      children: [
        sizedTitle('ID'),
        
        FLabel(app, text: targetComp.id.toString()),
      ],
    ),

    FRow(app,
      gap: 8,
      children: [
        sizedTitle('Named ID'),

        FLabel(app, text: targetComp.namedId),
      ],
    ),

    // is active
    FRow(app,
      gap: 8,
      children: [
        sizedTitle('Is Active'),

        FCheckbox(app,
          checked: targetComp.isActive,
          onChangeFn: (_, v) => debugWidget.setState(() => targetComp.setActive(v)),
        ),
      ],
    ),
  ];

  List<FWidget<T>> buildDebugCompControls() {
    if (targetComp case CTransform<T> t) return [

      // position
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Position'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          // x
          sizedTitle(t.position.x.f2, width: 75),

          // TODO: (DEBUG) came up with different control, slider is dumb
          FSlider(app,
            min: 0,
            max: screenWidth,
            initialValue: t.position.x,
            onChangeEndFn: (_, v) => setState(() => t.position.x = v),
          ),

          // y
          sizedTitle(t.position.y.f2, width: 75),

          // TODO: (DEBUG) came up with different control, slider is dumb
          FSlider(app,
            min: 0,
            max: screenHeight,
            initialValue: t.position.y,
            onChangeEndFn: (_, v) => setState(() => t.position.y = v),
          ),
        ],
      ),

      // rotation (in radians)
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Rotation'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          sizedTitle(t.rotation.f2, width: 50),
          FSlider(app,
            min: 0,
            max: 2 * math.pi,
            initialValue: t.rotation,
            onChangeEndFn: (_, v) => setState(() => t.rotation = v),
          ),
        ],
      ),

      // scale
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Scale'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          // x
          sizedTitle(t.scale.x.f2, width: 50),
          FSlider(app,
            min: 0,
            max: 10,
            initialValue: t.scale.x,
            onChangeEndFn: (_, v) => setState(() {
              t.entity.getAll<IsComponentScaleMutable<T>>()
                .forEach((c) => c.setActive(false));
              t.scale.x = v;
            }),
          ),

          // y
          sizedTitle(t.scale.y.f2, width: 50),
          FSlider(app,
            min: 0,
            max: 10,
            initialValue: t.scale.y,
            onChangeEndFn: (_, v) => setState(() {
              t.entity.getAll<IsComponentScaleMutable<T>>()
                .forEach((c) => c.setActive(false));
              t.scale.y = v;
            }),
          ),
        ],
      ),
    ];

    if (targetComp case CVelocity<T> t) return [
      // velocity
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Velocity'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          // x
          sizedTitle(t.velocity.x.f2, width: 50),
          FSlider(app,
            min: -9999,
            max: 9999,
            initialValue: t.velocity.x,
            onChangeEndFn: (_, v) => setState(() => t.velocity.x = v),
          ),

          // y
          sizedTitle(t.velocity.y.f2, width: 50),
          FSlider(app,
            min: -9999,
            max: 9999,
            initialValue: t.velocity.y,
            onChangeEndFn: (_, v) => setState(() => t.velocity.y = v),
          ),
        ],
      ),

      // angularVelocity (in radians)
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Angular Velocity'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          sizedTitle(t.angularVelocity.f2, width: 50),
          FSlider(app,
            min: -2 * math.pi,
            max: 2 * math.pi,
            initialValue: t.angularVelocity,
            onChangeEndFn: (_, v) => setState(() => t.angularVelocity = v),
          ),
        ],
      ),

      // linearDamping (in radians)
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Linear Damping'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          sizedTitle(t.linearDamping.f2, width: 50),
          FSlider(app,
            min: -2 * math.pi,
            max: 2 * math.pi,
            initialValue: t.linearDamping,
            onChangeEndFn: (_, v) => setState(() => t.linearDamping = v),
          ),
        ],
      ),

      // angularDamping (in radians)
      FRow(app,
        gap: 8,
        children: [
          sizedTitle('Angular Damping'),
        ],
      ),
      FRow(app,
        gap: 8,
        children: [
          sizedTitle(t.angularDamping.f2, width: 50),
          FSlider(app,
            min: -2 * math.pi,
            max: 2 * math.pi,
            initialValue: t.angularDamping,
            onChangeEndFn: (_, v) => setState(() => t.angularDamping = v),
          ),
        ],
      ),

      // TODO: (DEBUG) maxVelocity (nullable)
    ];

    // TODO: (DEBUG) CRectCollider
    // TODO: (DEBUG) CBoundsBounce
    // TODO: (DEBUG) CPulse

    return [];
    // throw UnimplementedError('Unknown component $targetComp for debug info.');
  }

  @override
  FWidget<T> build() => FPadding.all(app, 8,
    child: FColumn(app,
      gap: 8,
      children: [
        FRow(app,
          gap: 8,
          children: [
            FButton(app,
              onClickFn: (_) => debugWidget.setState(() {
                debugWidget.selectedComp = null;
              }),
              child: FPadding.symmetric(app, 4, 8,
                child: FLabel(app, text: 'BACK'),
              ),
            ),
            FButton(app,
              onClickFn: (_) => debugWidget.rebuild(),
              child: FPadding.symmetric(app, 4, 8,
                child: FLabel(app, text: 'REFRESH'),
              ),
            ),
          ],
        ),
        
        FExpanded(app,
          child: FPadding.all(app, 8,
            child: FSingleChildScrollView(app,
              child: FColumn(app,
                gap: 4,
                children: [
                  ...buildDebugCompBaseControls(),
                  
                  FPadding.symmetric(app, 8, 0,
                    child: FSeparator(app,
                      labelGap: 8,
                      label: FLabel(app, text: 'Controls'),
                    ),
                  ),
                  
                  ...buildDebugCompControls(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class DebugEntityWidget<T extends App<T>> extends FWidget<T> {
  final DebugWidget<T> debugWidget;

  DebugEntityWidget(super.app, this.debugWidget);

  late Entity<T> targetEntity;

  @override
  FWidget<T> build() => FPadding.all(app, 8,
    child: FColumn(app,
      gap: 8,
      children: [
        FButton(app,
          onClickFn: (_) => debugWidget.setState(() {
            debugWidget.selectedEntity = null;
          }),
          child: FPadding.symmetric(app, 4, 8,
            child: FLabel(app, text: 'BACK'),
          ),
        ),
        FExpanded(app,
          child: FSingleChildScrollView(app,
            autoScrollY: false,
            child: FColumn(app,
              gap: 4,
              children: [
                ...targetEntity._components.map((e) => FButton(app,
                  onClickFn: (_) => debugWidget.setState(() {
                    debugWidget.compWidget.targetComp = e;
                    debugWidget.selectedComp = e;
                  }),
                  child: FPadding.symmetric(app, 4, 8,
                    child: FLabel(app, text: e.name),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

enum DebugTabs {
  entities,
  watch
}

class DebugWatchWidget<T extends App<T>> extends FWidget<T> {
  final DebugWidget<T> debugWidget;

  DebugWatchWidget(super.app, this.debugWidget);

  @override
  FWidget<T> build() => FColumn(app,
    gap: 4,
    children: [
      for (final e in debugWidget._watchers.entries) ...[
        FRow(app,
          gap: 8,
          children: [
            FLabel(app, text: e.key),
            FLabel(app, text: ' => '),
            FLabel(app, text: '${e.value()}'),
          ],
        ),
      ],
    ],
  );
}

class DebugWidget<T extends App<T>> extends FWidget<T> {
  late DebugEntityWidget<T> entityWidget;
  late DebugCompWidget<T> compWidget;
  late DebugWatchWidget<T> watchWidget;

  final Map<String, dynamic Function()> _watchers = {};

  DebugWidget(super.app) {
    entityWidget = .new(app, this);
    compWidget = .new(app, this);
    watchWidget = .new(app, this);

    // always render at the top
    addComp(CRenderLayer<T>(app, layer: RenderLayers.debug.name));
  }

  bool hidden = false;
  DebugTabs currentTab = .entities;
  Entity<T>? selectedEntity;
  Comp<T>? selectedComp;

  @override
  bool get _ownsChildrenDrawOrder => true;

  FWidget<T> buildEntityList() => FPadding.all(app, 8,
    child: FSingleChildScrollView(app,
      child: FColumn(app,
        gap: 4,
        children: [
          ...scene._entities.map((e) => FButton(app,
            onClickFn: (_) => setState(() {
              entityWidget.targetEntity = e;
              selectedEntity = e;
            }),
            child: FPadding.symmetric(app, 4, 8,
              child: FLabel(app, text: e.name),
            ),
          )),
        ],
      ),
    ),
  );

  FWidget<T> buildEntitiesTab() {
    if (selectedComp != null) {
      return compWidget..rebuild();
    }

    if (selectedEntity != null) {
      return entityWidget..rebuild();
    }
    
    return buildEntityList();
  }

  FWidget<T> buildWatchTab() {
    return FLabel(app, text: 'Working!');
  }

  FWidget<T> buildDebugView() => switch (currentTab) {
    .entities => buildEntitiesTab(),
    .watch => watchWidget..rebuild(),
  };

  @override
  FWidget<T> build() => FColumn(app,
    children: [
      FRow(app,
        children: [
          FButton(app,
            onClickFn: (_) => setState(() => hidden = !hidden),
            child: FLabel(app, text: '...'),
          ),

          if (!hidden) ...[
            FSized.shrink(app, width: 8),

            FButton(app,
              onClickFn: (_) => setState(() => currentTab = .entities),
              child: FPadding.symmetric(app, 4, 8,
                child: FLabel(app, text: 'Entities'),
              ),
            ),

            FSized.shrink(app, width: 8),

            FButton(app,
              onClickFn: (_) => setState(() => currentTab = .watch),
              child: FPadding.symmetric(app, 4, 8,
                child: FLabel(app, text: 'Watch'),
              ),
            ),
          ],
        ],
      ),

      FExpanded(app,
        child: hidden ? FSized.shrink(app) : FPadding.all(app, 8,
          child: FContainer(app,
            backgroundColor: .ASH..a = 100,
            child: buildDebugView()
          ),
        ),
      ),
    ],
  );
}

class DebugAppSystem<T extends App<T>> extends AppSystem<T> {
  late DebugWidget<T> debugWidget;

  DebugAppSystem(super.app) {
    scene.addEntity(debugWidget = .new(app));
    app.listenOnEventRecorded(_debugBreakOn);
    _startWatchTask();
  }
  
  void _startWatchTask() {
    task(DelayTask(app,
      seconds: 1,
      action: (task) => callback(() {
        debugWidget.watchWidget.rebuild();
        debugWidget.setState(() => _startWatchTask());
      })
    ));
  }

  void devInspect(ECSBase<T> origin) {
    // TODO: support other structures, currently only Entity/Component
    if (origin is Entity<T>) debugWidget.setState(() {
      debugWidget.entityWidget.targetEntity = origin;
      debugWidget.hidden = false;
    });

    if (origin is Comp<T>) debugWidget.setState(() {
      debugWidget.compWidget.targetComp = origin;
      debugWidget.hidden = false;
    });

    throw UnsupportedError('Invalid origin $origin for `devInspect`!');
  }

  final List<bool Function(Event<T> event)> _listenOnEvents = [];

  void _debugBreakOn(_, Event<T> event) {
    if (_listenOnEvents.any((check) => check(event))) {
      print('[DEV] Breaking on event $event');
      app.time.setTimeScale(0);
    }
  }

  void devBreakOn<E extends Event<T>>() {
    _listenOnEvents.add((event) => event is E);
  }

  void devWatch(String name, dynamic Function() getter) {
    if (debugWidget._watchers.containsKey(name)) {
      throw StateError("Already watching a '$name', use different id.");
    }
    debugWidget._watchers[name] = getter;
  }

  @override
  void onEndFrame(double dt) {
    scene._entities.remove(debugWidget);
    scene._entities.add(debugWidget);
  }
}