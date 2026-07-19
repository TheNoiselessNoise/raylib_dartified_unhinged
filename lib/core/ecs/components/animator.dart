part of '../../raylib_dartified_unhinged.dart';

class Animation {
  String name;
  int? frameCount; // null = auto-calculate
  double? frameDuration;
  int frameWidth;
  int frameHeight;
  int startRow; // Which row to start on
  int? maxColumns; // How many columns before wrapping (null = don't wrap, single row)
  bool loop;
  String? sheetKey;
  String? nextAnimation;
  int paddingX;
  int paddingY;
  int offsetX;
  int offsetY;
  
  Animation({
    required this.name,
    this.frameCount,
    this.frameDuration,
    required this.frameWidth,
    required this.frameHeight,
    this.startRow = 0,
    this.maxColumns,
    this.loop = true,
    this.sheetKey,
    this.nextAnimation,
    this.paddingX = 0,
    this.paddingY = 0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  double get realFrameDuration => frameDuration ?? 0;

  int getFrameCount(int textureWidth, int textureHeight) {
    if (frameCount != null) return frameCount!;
    
    final effectiveFrameWidth = frameWidth + paddingX;
    final effectiveFrameHeight = frameHeight + paddingY;
    
    if (maxColumns != null) {
      // grid mode with wrapping
      final availableWidth = textureWidth - offsetX;
      final availableHeight = textureHeight - offsetY;
      final cols = availableWidth ~/ effectiveFrameWidth;
      final rows = availableHeight ~/ effectiveFrameHeight;
      return cols * rows;
    } else {
      // single row mode
      final availableWidth = textureWidth - offsetX;
      return availableWidth ~/ effectiveFrameWidth;
    }
  }
  
  RectangleD getFrameRect(int frameIndex) {
    if (maxColumns != null) {
      final col = frameIndex % maxColumns!;
      final row = startRow + (frameIndex ~/ maxColumns!);
      
      return .rect(
        (offsetX + col * (frameWidth + paddingX)),
        (offsetY + row * (frameHeight + paddingY)),
        frameWidth,
        frameHeight,
      );
    } else {
      return .rect(
        (offsetX + frameIndex * (frameWidth + paddingX)),
        (offsetY + startRow * frameHeight),
        frameWidth,
        frameHeight,
      );
    }
  }
}

class CAnimator<T extends App<T>> extends Comp<T> {
  TextureD? sheet;
  Map<String, TextureD>? sheets;
  Map<String, Animation> animations;
  List<Animation> _fpsBoundAnimations = [];
  void Function(String animName)? onComplete;
  
  late String currentAnimName;
  int currentFrame = 0;
  double frameTime = 0;
  bool isPlaying = true;

  RectangleD src = .zero();
  RectangleD dest = .zero();
  Vector2D origin = .zero();
  
  CAnimator(super.app, {
    this.sheet, // single sheet
    this.sheets, // or multiple sheets
    required this.animations,
    String? currentAnimName,
    this.onComplete,
  }) : currentAnimName = currentAnimName ?? animations.keys.first,
  assert(sheet != null || sheets != null, 'Must provide sheet or sheets'),
  assert(currentAnimName != null, 'You must either provide currentAnimName or at least one animation');

  factory CAnimator.fromGroup(T app, {
    required String groupPath,
    required List<String> animationNames,
    int? frameWidth,
    int? frameHeight,
    String? initialAnimation,
    String extension = 'png',
    void Function(String animName)? onComplete,
    Animation Function(Animation anim)? postAnimation,
  }) {
    int maxWidth = frameWidth ?? 0;
    int maxHeight = frameHeight ?? 0;
    final Map<String, TextureD> sheets = {};
    final Map<String, Animation> animations = {};
    
    for (final aninName in animationNames) {
      final animPath = path.join(groupPath, '$aninName.$extension');
      final sheet = app.backend.assets.texture(aninName, path: animPath);
      if (frameWidth == null && sheet.width > maxWidth) maxWidth = sheet.width;
      if (frameHeight == null && sheet.height > maxHeight) maxHeight = sheet.height;
      sheets[aninName] = sheet;
      Animation anim = .new(
        name: aninName,
        sheetKey: aninName,
        frameDuration: 1/app.time.fps,
        frameWidth: frameWidth ?? sheet.width,
        frameHeight: frameHeight ?? sheet.height,
      );
      if (postAnimation != null) anim = postAnimation(anim);
      animations[aninName] = anim;
    }

    return CAnimator(app,
      sheets: sheets,
      animations: animations,
      currentAnimName: initialAnimation ?? animations.keys.first,
      onComplete: onComplete,
    );
  }

  Animation get currentAnim {
    if (!animations.containsKey(currentAnimName)) {
      throw StateError('Animation $currentAnimName does not exist');
    }
    return animations[currentAnimName]!;
  }
  
  TextureD get currentTexture {
    final anim = currentAnim;
    
    // if sheetKey, use that
    final sheets = this.sheets;
    final sheetKey = anim.sheetKey;
    if (sheetKey != null && sheets != null) {
      if (!sheets.containsKey(sheetKey)) {
        throw StateError("Invalid sheet key '$sheetKey'.");
      }

      return sheets[sheetKey]!;
    }
    
    // fall back to single sheet
    return sheet!;
  }

  @override
  void onAdd(ECSBase<T> parent) {
    animations.values.forEach((animation) {
      if (animation.frameDuration == null) {
        animation.frameDuration = 1 / app.time.fps;
        _fpsBoundAnimations.add(animation);
      }
    });
    
    app.listenOnFPSChange((_, oldFps, newFps) {
      _fpsBoundAnimations.forEach((animation) {
        animation.frameDuration = 1 / newFps;
      });
    });
  }

  @override
  void onUpdate(double dt) {
    if (!isPlaying) return;
    
    final anim = currentAnim;
    final texture = currentTexture;
    final maxFrames = anim.getFrameCount(texture.width, texture.height);
    
    frameTime += dt;
    
    while (frameTime >= anim.realFrameDuration) {
      frameTime -= anim.realFrameDuration;
      currentFrame++;
      
      if (currentFrame >= maxFrames) {
        if (anim.loop) {
          currentFrame = 0;
        } else {
          currentFrame = maxFrames - 1;
          isPlaying = false;
          onAnimationComplete(anim.name);
          
          // transition to next animation
          if (anim.nextAnimation != null) {
            play(anim.nextAnimation!);
          }
        }
      }
    }
  }

  @override
  void onDraw(double dt) {
    final anim = currentAnim;
    
    entity.onTransform((t) {
      src = anim.getFrameRect(currentFrame).copy();
      
      dest.set(
        t.position.x,
        t.position.y,
        anim.frameWidth * t.scale.x,
        anim.frameHeight * t.scale.y,
      );

      origin.set(
        anim.frameWidth * t.scale.x / 2,
        anim.frameHeight * t.scale.y / 2,
      );
      
      backend.render.drawTexturePro(
        currentTexture,
        src,
        dest,
        origin,
        t.rotation * 180 / math.pi,
        .WHITE,
      );
    });
  }

  void playNextAnimation() {
    final animNames = animations.keys.toList();
    int index = animNames.indexOf(currentAnimName);
    index = (index + 1) % animNames.length;
    play(animNames[index]);
  }

  void playPrevAnimation() {
    final animNames = animations.keys.toList();
    int index = animNames.indexOf(currentAnimName);
    index = (index - 1) % animNames.length;
    play(animNames[index]);
  }
  
  void play(String animName, {bool restart = false}) {
    if (currentAnimName == animName && !restart) return;
    currentAnimName = animName;
    currentFrame = 0;
    frameTime = 0;
    isPlaying = true;
  }
  
  void pause() => isPlaying = false;
  void resume() => isPlaying = true;
  void stop() {
    isPlaying = false;
    currentFrame = 0;
    frameTime = 0;
  }
  
  @mustCallSuper
  void onAnimationComplete(String animName) {
    onComplete?.call(animName);
  }

  // clone

  @override
  CAnimator<T> createInstance() {
    final c = CAnimator<T>(app,
      animations: .from(animations),
      currentAnimName: currentAnimName,
      onComplete: onComplete,
      sheet: sheet,
      sheets: sheets != null ? .from(sheets!) : null,
    );

    c._fpsBoundAnimations.addAll(List.from(_fpsBoundAnimations));
    c.currentFrame = currentFrame;
    c.frameTime = frameTime;
    c.isPlaying = isPlaying;

    c.src = src.copy();
    c.dest = dest.copy();
    c.origin = origin.copy();

    return c;
  }

  // state

  @override
  CAnimatorSnapshot<T> createSnapshot() {
    final snapshot = CAnimatorSnapshot<T>(id);

    snapshot.sheet = sheet?.copy();
    snapshot.sheets = sheets == null ? null : .from(sheets!);
    snapshot.animations = .from(animations);
    snapshot._fpsBoundAnimations = .from(_fpsBoundAnimations);
    snapshot.onComplete = onComplete;

    snapshot.currentAnimName = currentAnimName;
    snapshot.currentFrame = currentFrame;
    snapshot.frameTime = frameTime;
    snapshot.isPlaying = isPlaying;
    
    snapshot.src = src.copy();
    snapshot.dest = dest.copy();
    snapshot.origin = origin.copy();

    return snapshot;
  }

  @override
  @mustCallSuper
  void restoreSnapshot(covariant CAnimatorSnapshot<T> snapshot) {
    super.restoreSnapshot(snapshot);
    
    sheet = snapshot.sheet?.copy();
    sheets = snapshot.sheets == null ? null : .from(snapshot.sheets!);
    animations = .from(snapshot.animations);
    _fpsBoundAnimations = List.from(snapshot._fpsBoundAnimations);
    onComplete = snapshot.onComplete;

    currentAnimName = snapshot.currentAnimName;
    currentFrame = snapshot.currentFrame;
    frameTime = snapshot.frameTime;
    isPlaying = snapshot.isPlaying;
    
    src = snapshot.src.copy();
    dest = snapshot.dest.copy();
    origin = snapshot.origin.copy();
  }

  // persistence

  static const typeId = '__comp__CAnimator';
  
  @override String get persistentTypeId => typeId;
}

class CAnimatorSnapshot<T extends App<T>> extends CompSnapshot<T, CAnimator<T>> {
  late TextureD? sheet;
  late Map<String, TextureD>? sheets;
  late Map<String, Animation> animations;
  late List<Animation> _fpsBoundAnimations;
  late void Function(String animName)? onComplete;
  
  late String currentAnimName;
  late int currentFrame;
  late double frameTime;
  late bool isPlaying;

  late RectangleD src;
  late RectangleD dest;
  late Vector2D origin;

  CAnimatorSnapshot(super.id);
  
  @override
  CAnimator<T> createInstance(T app) {
    final c = CAnimator<T>(app,
      animations: .from(animations),
      currentAnimName: currentAnimName,
      onComplete: onComplete,
      sheet: sheet,
      sheets: sheets != null ? .from(sheets!) : null,
    );

    c._fpsBoundAnimations.addAll(List.from(_fpsBoundAnimations));
    c.currentFrame = currentFrame;
    c.frameTime = frameTime;
    c.isPlaying = isPlaying;

    c.src = src.copy();
    c.dest = dest.copy();
    c.origin = origin.copy();

    return c;
  }
}