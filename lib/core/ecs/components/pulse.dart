part of '../../raylib_dartified_unhinged.dart';

mixin IsComponentScaleMutable<T extends App<T>> on Comp<T> {}

class CPulse<T extends App<T>> extends Comp<T> with
  IsComponentScaleMutable<T>
{
  double minScale;
  double maxScale;
  double speed;
  double pulseTime;

  double currentScale = 0;

  CPulse(super.app, {
    this.minScale = 0.8,
    this.maxScale = 1.2,
    this.speed = 2.0,
    double? time,
  }) : pulseTime = time ?? 0;

  @override
  void onUpdate(double dt) => entity.onTransform((t) {
    if (isDisabled) return;
    
    pulseTime += dt;

    currentScale = minScale + (maxScale - minScale) * (0.5 + 0.5 * math.sin(pulseTime * speed));

    t.scale.set(currentScale, currentScale);
  });

  // clone

  @override
  CPulse<T> createInstance() {
    final c = CPulse<T>(app,
      minScale: minScale,
      maxScale: maxScale,
      speed: speed,
      time: pulseTime,
    );
    c.currentScale = currentScale;
    return c;
  }

  // state

  @override
  CPulseSnapshot<T> createSnapshot() {
    final snapshot = CPulseSnapshot<T>(namedId);
    snapshot.minScale = minScale;
    snapshot.maxScale = maxScale;
    snapshot.speed = speed;
    snapshot.pulseTime = pulseTime;
    snapshot.currentScale = currentScale;
    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CPulseSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    minScale = snapshot.minScale;
    maxScale = snapshot.maxScale;
    speed = snapshot.speed;
    pulseTime = snapshot.pulseTime;
    currentScale = snapshot.currentScale;
  }
}

class CPulseSnapshot<T extends App<T>> extends CompSnapshot<T, CPulse<T>> {
  late double minScale;
  late double maxScale;
  late double speed;
  late double pulseTime;
  late double currentScale;
  
  CPulseSnapshot(super.namedId);

  @override
  CPulse<T> createInstance(T app) {
    final c = CPulse<T>(app,
      minScale: minScale,
      maxScale: maxScale,
      speed: speed,
      time: pulseTime,
    );
    c.currentScale = currentScale;
    return c;
  }
}
