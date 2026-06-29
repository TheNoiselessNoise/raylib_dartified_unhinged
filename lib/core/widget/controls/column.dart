part of '../../raylib_dartified_unhinged.dart';

class FColumn<T extends App<T>> extends FWidget<T> {
  double gap;
  FColumnAlignment alignment;

  FColumn(super.app, {
    super.key,
    this.gap = 0,
    this.alignment = .start,
    super.children,
  });

  @override
  void layout(FConstraints constraints) {
    final children = getEntities().toList();
    if (children.isEmpty) {
      size = .vec2(0, 0);
      return;
    }

    // pass 1 - measure non-expanded children, sum flex of expanded ones
    double usedHeight = 0;
    int totalFlex = 0;
    for (final child in children) {
      if (child is FExpanded<T>) {
        totalFlex += child.flex;
      } else {
        usedHeight += child.size.y;
      }
    }

    final totalGap = gap * (children.length - 1);
    final remaining = constraints.maxHeight - usedHeight - totalGap;

    // pass 2 - assign expanded sizes, position cursor
    double cursor = 0;
    double maxWidth = 0;
    for (final child in children) {
      if (child is FExpanded<T> && totalFlex > 0) {
        final crossSize = constraints.maxWidth.isFinite ? constraints.maxWidth : child.size.x;
        child.size = .vec2(crossSize, remaining * child.flex / totalFlex);
      }
      child.localOffset = .vec2(0, cursor);
      cursor += child.size.y + gap;
      if (child.size.x > maxWidth) maxWidth = child.size.x;
    }
    cursor -= gap;

    size = .vec2(maxWidth, cursor);

    // pass 3 - actually run each child's layout, now with a real constraint
    for (final child in children) {
      if (child is FExpanded<T> && totalFlex > 0) {
        child._doLayout(.tight(child.size));
      } else {
        child._doLayout(.new(
          maxWidth: constraints.maxWidth,
          maxHeight: double.infinity,
        ));
      }
    }

    if (alignment != .start) {
      for (final child in children) {
        child.localOffset = .vec2(
          switch (alignment) {
            .center => (maxWidth - child.size.x) / 2,
            .end    => maxWidth - child.size.x,
            .start  => 0,
          },
          child.localOffset.y,
        );
      }
    }
  }

  @override
  FWidget<T> build() => this;
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FColumn<T>) return;
    copy.gap = gap;
    copy.alignment = alignment;
  }
}

enum FColumnAlignment { start, center, end }