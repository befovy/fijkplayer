import 'package:flutter/material.dart';

typedef void OnItemVisibilityState(List<int> exposure, List<int> hidden);
///通过SliverChildBuilderDelegate 对比Item得出滑动隐藏显示的Item下标
class MySliverChildBuilderDelegate extends SliverChildBuilderDelegate {
  MySliverChildBuilderDelegate(Widget Function(BuildContext, int) builder,
      {int childCount,
      bool addAutomaticKeepAlives = true,
      bool addRepaintBoundaries = true,
      this.onItemVisibilityState})
      : super(builder,
            childCount: childCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries);

  final OnItemVisibilityState onItemVisibilityState;
  final visibilityMonitor = VisibilityMonitor();

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    visibilityMonitor.update(
        VisibilityState(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
        ),
        onItemVisibilityState);
  }
}

class VisibilityState {
  const VisibilityState({this.firstIndex, this.lastIndex});

  final int firstIndex;
  final int lastIndex;
}

class ChangeSet {
  final List<int> exposure = [];
  final List<int> hidden = [];

  bool get empty => exposure.length == 0 && hidden.length == 0;
}

class VisibilityMonitor {
  VisibilityState lastState;

  addSequenceToList(List<int> list, int sequenceStart, int sequenceEnd) {
    if (sequenceStart <= sequenceEnd) {
      for (var i = sequenceStart; i <= sequenceEnd; i++) {
        list.add(i);
      }
    } else {
      for (var i = sequenceEnd; i >= sequenceStart; i--) {
        list.add(i);
      }
    }
  }

  update(
      VisibilityState newState, OnItemVisibilityState onItemVisibilityState) {
    if (lastState != null &&
        newState.firstIndex == lastState.firstIndex &&
        newState.lastIndex == lastState.lastIndex) {
      return;
    }

    final changeSet = ChangeSet();

    if (lastState == null) {
      addSequenceToList(
          changeSet.exposure, newState.firstIndex, newState.lastIndex);
    } else if (newState.firstIndex > lastState.lastIndex) {
      addSequenceToList(
          changeSet.exposure, newState.firstIndex, newState.lastIndex);
      addSequenceToList(
          changeSet.hidden, lastState.firstIndex, lastState.lastIndex);
    } else if (newState.lastIndex < lastState.firstIndex) {
      addSequenceToList(
          changeSet.exposure, newState.lastIndex, newState.firstIndex);
      addSequenceToList(
          changeSet.hidden, lastState.lastIndex, lastState.firstIndex);
    } else {
      if (newState.firstIndex < lastState.firstIndex) {
        addSequenceToList(
            changeSet.exposure, lastState.firstIndex - 1, newState.firstIndex);
      }

      if (newState.firstIndex > lastState.firstIndex) {
        addSequenceToList(
            changeSet.hidden, lastState.firstIndex, newState.firstIndex - 1);
      }

      if (newState.lastIndex > lastState.lastIndex) {
        addSequenceToList(
            changeSet.exposure, lastState.lastIndex + 1, newState.lastIndex);
      }

      if (newState.lastIndex < lastState.lastIndex) {
        addSequenceToList(
            changeSet.hidden, lastState.lastIndex, newState.lastIndex + 1);
      }
    }

    lastState = newState;

    if (!changeSet.empty && onItemVisibilityState != null) {
      onItemVisibilityState(changeSet.exposure, changeSet.hidden);
    }
  }
}
