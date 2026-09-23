part of '../../raylib_dartified_unhinged.dart';

class FContainer<T extends App<T>> extends FWidgetLeaf<T> {
  ColorD? backgroundColor;

  FContainer(super.app, {
    super.key,
    this.backgroundColor,
    required FWidget<T> child,
  }) : super(child: child);

  @override
  bool get _ownsChildrenDrawOrder => true;

  @override
  void layout(FConstraints constraints) {
    final child = this.child!;
    child._doLayout(.loose(.vec2(constraints.maxWidth, constraints.maxHeight)));
    size = .vec2(
      constraints.minWidth > child.size.x ? constraints.minWidth : child.size.x,
      constraints.minHeight > child.size.y ? constraints.minHeight : child.size.y,
    );
  }

  @override
  void onDraw(double dt) {
    if (backgroundColor != null) {
      final rect = get<CRectCollider<T>>()!.rect;
      backend.render.drawRectangleRec(rect, backgroundColor!);
    }

    child!._doDraw(dt);
  }
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FContainer<T>) return;
    copy.backgroundColor = backgroundColor;
  }
}