part of '../../raylib_dartified_unhinged.dart';

class FRow<T extends App<T>> extends FWidget<T> {
  double gap;
  FRowAlignment alignment;

  FRow(super.app, {
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
    double usedWidth = 0;
    int totalFlex = 0;
    for (final child in children) {
      if (child is FExpanded<T>) {
        totalFlex += child.flex;
      } else {
        usedWidth += child.size.x;
      }
    }

    final totalGap = gap * (children.length - 1);
    final remaining = constraints.maxWidth - usedWidth - totalGap;

    // pass 2 - assign expanded sizes, position cursor
    double cursor = 0;
    double maxHeight = 0;
    for (final child in children) {
      if (child is FExpanded<T> && totalFlex > 0) {
        final crossSize = constraints.maxHeight.isFinite ? constraints.maxHeight : child.size.y;
        child.size = .vec2(remaining * child.flex / totalFlex, crossSize);
      }
      child.localOffset = .vec2(cursor, 0);
      cursor += child.size.x + gap;
      if (child.size.y > maxHeight) maxHeight = child.size.y;
    }
    cursor -= gap;

    size = .vec2(cursor, maxHeight);

    // pass 3 - actually run each child's layout, now with a real constraint
    for (final child in children) {
      if (child is FExpanded<T> && totalFlex > 0) {
        child._doLayout(.tight(child.size));
      } else {
        child._doLayout(.new(
          maxWidth: double.infinity,
          maxHeight: constraints.maxHeight,
        ));
      }
    }

    // vertical alignment pass
    if (alignment != .start) {
      for (final child in children) {
        child.localOffset = .vec2(
          child.localOffset.x,
          switch (alignment) {
            .center => (maxHeight - child.size.y) / 2,
            .end    => maxHeight - child.size.y,
            .start  => 0,
          },
        );
      }
    }
  }

  @override
  FWidget<T> build() => this;
  
  @override
  void cloneWidgetInto(FWidget<T> copy) {
    if (copy is! FRow<T>) return;
    copy.gap = gap;
    copy.alignment = alignment;
  }
}

enum FRowAlignment { start, center, end }