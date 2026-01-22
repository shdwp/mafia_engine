import 'game_frame.dart';

extension GameTree on GameFrame {
  Iterable<GameFrame> findAllPreceeding(bool Function(GameFrame x) predicate) {
    var result = List<GameFrame>.empty(growable: true);
    var frame = this;
    if (predicate(frame)) result.add(frame);

    while (frame.previous != null) {
      frame = frame.previous!;
      if (predicate(frame)) result.add(frame);
    }
    return result;
  }

  Iterable<T> takeAllBackwardsIncludingUntil<T extends GameFrame>(
    bool Function(T frame) predicate,
  ) {
    var result = List<T>.empty(growable: true);
    var frame = this;

    if (frame is T) {
      result.add(frame);
      if (predicate(frame)) return result;
    }

    while (frame.previous != null) {
      frame = frame.previous!;

      if (frame is T) {
        result.add(frame);
        if (predicate(frame)) return result;
      }
    }
    return result;
  }

  Iterable<T> takeBackUntil<T extends GameFrame>(GameFrame boundary) sync* {
    GameFrame? frame = this;
    if (frame == boundary) return;

    do {
      if (frame is T) yield frame;
      frame = frame!.previous;
      if (frame == boundary) break;
    } while (frame != null);
  }

  T? firstBackwards<T extends GameFrame>() {
    var frame = this;
    if (frame is T) return frame;

    while (frame.previous != null) {
      frame = frame.previous!;
      if (frame is T) return frame;
    }
    return null;
  }

  T? findBackwards<T extends GameFrame>(bool Function(T frame) predicate) {
    var frame = this;
    if (frame is T && predicate(frame)) return frame;

    while (frame.previous != null) {
      frame = frame.previous!;
      if (frame is T && predicate(frame)) return frame;
    }
    return null;
  }

  GameFrame findLast() {
    var frame = this;
    while (frame.next != null) {
      frame = frame.next!;
    }
    return frame;
  }

  GameFrame findFirst() {
    var frame = this;
    while (frame.previous != null) {
      frame = frame.previous!;
    }
    return frame;
  }

  int countNext() {
    var amount = 1;
    var frame = this;
    while (frame.next != null) {
      frame = frame.next!;
      amount++;
    }
    return amount;
  }

  int countPrevious() {
    var amount = 1;
    var frame = this;
    while (frame.previous != null) {
      frame = frame.previous!;
      amount++;
    }
    return amount;
  }
}
