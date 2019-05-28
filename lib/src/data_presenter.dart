import 'dart:async';

/// 返回给listView的数据实体
class RefreshListItemDataEntity {
  /// 是否成功
  bool success = false;

  /// 实体类列表
  List entityList;

  /// 额外字段信息
  dynamic extraData;
}

/// 数据Presenter,可继承,可with.
/// 默认提供实现类[RefreshListViewDataPresenter]
abstract class RefreshListViewDataIPresenter {
  /// 获取数据
  Future<RefreshListItemDataEntity> fetchDataEntity();

  /// 清空所有数据,根据需求可重写
  void clear();

  /// 添加新数据,当每次fetchDataEntity成功之后会调用,根据需求可重写
  void addAll(RefreshListItemDataEntity fetchedData);

  /// 是否显示空数据,每次fetchDataEntity成功之后
  bool isEmptyData(RefreshListItemDataEntity fetchedData);

  /// 是否没有更多数据,每次fetchDataEntity成功之后
  bool isNoMoreData(RefreshListItemDataEntity fetchedData);

  /// 重置页码,比如将单页面pageNum=1
  void resetPage();

  /// 下一页,比如pageNum++
  void nextPage();

  /// 上一页,比如pageNum--
  void previousPage();
}


/// 默认的dataPresenter
class RefreshListViewDataPresenter implements RefreshListViewDataIPresenter {
  int pageSize = 20;

  int pageNum = 1;

  /// 提供一个默认的list,可以不使用
  List entityList = [];

  /// 获取数据
  Future<RefreshListItemDataEntity> fetchDataEntity() => null;

  /// 清空this.entityList所有数据,根据需求可重写
  @override
  void clear() => entityList.clear();

  /// 添加新数据数组,根据需求可重写
  /// 每次调用fetchDataEntity,获取到了新的RefreshListItemDataEntity.entityList之后,默认会添加到this.entityList里面
  @override
  void addAll(RefreshListItemDataEntity fetchedData) {
    if (fetchedData?.entityList != null) {
      entityList.addAll(fetchedData.entityList);
    }
  }

  /// 是否显示空数据
  @override
  bool isEmptyData(RefreshListItemDataEntity fetchedData) =>
      fetchedData.entityList == null || fetchedData.entityList.isEmpty;

  /// 是否没有更多数据
  @override
  bool isNoMoreData(RefreshListItemDataEntity fetchedData) =>
      fetchedData.entityList == null ||
          fetchedData.entityList.length < pageSize;

  @override
  void resetPage() => pageNum = 1;

  @override
  void nextPage() => pageNum++;

  @override
  void previousPage() => pageNum--;
}