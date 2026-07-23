library;

import 'dart:collection';
import 'dart:math' as math;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'package:raylib_dartified_web/raylib_dartified_web.dart'
  if (dart.library.ffi) 'package:raylib_dartified/raylib.dart';
import 'package:uuid/uuid.dart';

// backends
part 'ecs/backends/base.dart';
part 'ecs/backends/headless.dart';
part 'ecs/backends/raylib.dart';

// widget (flutter-like gui)
part 'widget/base.dart';
part 'widget/events.dart';
part 'widget/mixins.dart';
part 'widget/query.dart';
part 'widget/scene_systems.dart';
part 'widget/scene.dart';
part 'widget/animations/shake.dart';
part 'widget/controls/button.dart';
part 'widget/controls/center.dart';
part 'widget/controls/checkbox.dart';
part 'widget/controls/column.dart';
part 'widget/controls/container.dart';
part 'widget/controls/expanded.dart';
part 'widget/controls/label.dart';
part 'widget/controls/padding.dart';
part 'widget/controls/row.dart';
part 'widget/controls/select.dart';
part 'widget/controls/separator.dart';
part 'widget/controls/single_child_scroll_view.dart';
part 'widget/controls/sized.dart';
part 'widget/controls/slider.dart';
part 'widget/controls/text_input.dart';
part 'widget/controls/tree.dart';

// core
part 'ecs/components/animation.dart';
part 'ecs/components/animator.dart';
part 'ecs/components/bounds_bounce.dart';
part 'ecs/components/bounds_constraint.dart';
part 'ecs/components/bounds_wrap.dart';
part 'ecs/components/collider.dart';
part 'ecs/components/image.dart';
part 'ecs/components/input.dart';
part 'ecs/components/lifetime.dart';
part 'ecs/components/local_transform.dart';
part 'ecs/components/out_of_bounds.dart';
part 'ecs/components/particle_emitter.dart';
part 'ecs/components/physics_body.dart';
part 'ecs/components/pulse.dart';
part 'ecs/components/render_layer.dart';
part 'ecs/components/sprite.dart';
part 'ecs/components/state_machine.dart';
part 'ecs/components/transform.dart';
part 'ecs/components/velocity.dart';
part 'ecs/scene_systems/collision_resolver.dart';
part 'ecs/scene_systems/gravity.dart';
part 'ecs/scene_systems/screen_bounce.dart';
part 'ecs/scene_systems/transform_sync.dart';
part 'ecs/app_system.dart';
part 'ecs/app.dart';
part 'ecs/base.dart';
part 'ecs/clone.dart';
part 'ecs/components.dart';
part 'ecs/debug.dart';
part 'ecs/drawers.dart';
part 'ecs/entity.dart';
part 'ecs/events.dart';
part 'ecs/extras.dart';
part 'ecs/factories.dart';
part 'ecs/input.dart';
part 'ecs/map.dart';
part 'ecs/mixins.dart';
part 'ecs/query.dart';
part 'ecs/renderer.dart';
part 'ecs/scene_system.dart';
part 'ecs/scene.dart';
part 'ecs/state.dart';
part 'ecs/tasks.dart';

extension StableSortExtension<T> on List<T> {
  List<T> sortedBy<K extends Comparable<K>>(K Function(T) key) {
    final indexed = asMap().entries.toList();
    indexed.sort((a, b) {
      final cmp = key(a.value).compareTo(key(b.value));
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }
}