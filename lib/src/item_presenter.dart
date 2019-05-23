import 'package:flutter/material.dart';

/// item的Presenter,可继承,可with
abstract class RefreshListViewItemIPresenter {
  /// 一共有多少个section,默认1个.
  int sectionCount() => 1;

  /// 每一个section有多少行
  int rowCount(int section);

  /// 创建所有item的
  Widget items(BuildContext context, int section, int index);

  /// 创建每一个section的头部
  Widget sectionHeader(BuildContext context, int section) => null;

  /// 创建每一个section的底部
  Widget sectionFooter(BuildContext context, int section) => null;

  /// 每一个item被点击的回调
  void itemOnTap(BuildContext context, int section, int index) {}

  /// 每一个item是否可以点击,如果返回true会立即调用[itemOnTap]
  bool itemShouldTap(BuildContext context, int section, int index) => true;

  /// listView的头部
  Widget headerWidget(BuildContext context) => null;

  /// listView的底部
  Widget footerWidget(BuildContext context) => null;
}