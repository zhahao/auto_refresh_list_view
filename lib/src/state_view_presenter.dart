import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// listView的各种状态view的Presenter,可继承,可with.
/// 默认提供实现类[RefreshListStateViewPresenter]
abstract class RefreshListStateViewIPresenter {
  /// context
  BuildContext context;

  /// 正在加载数据
  Widget loadingView();

  /// 首次加载失败
  Widget errorOnLoadView(VoidCallback onPressed);

  /// 暂无数据
  Widget emptyOnLoadView();

  /// 加载更多数据时失败
  Widget errorOnMoreView(VoidCallback onPressed);

  /// 加载更多数据
  Widget loadingMoreView();

  /// 上拉加载更多数据
  Widget pullUpLoadMoreView(VoidCallback onPressed);

  /// 没有更多数据
  Widget noMoreCanLoadView();
}

class RefreshListStateViewPresenter implements RefreshListStateViewIPresenter {
  /// context
  BuildContext context;

  /// 空数据文本
  String emptyOnLoadText = '暂无数据';

  /// 主题色
  Color themeColor = Colors.blue;

  /// 空数据图片Widget
  Widget emptyImageWidget = Container();

  /// 加载失败图片Widget
  Widget loadErrorImageWidget = Container();

  /// 正在加载数据
  @override
  Widget loadingView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: CupertinoActivityIndicator(
          animating: true,
          radius: 20,
        ),
        //child:
      ),
    );
  }

  /// 加载失败
  @override
  Widget errorOnLoadView(VoidCallback onPressed) {
    return _emptyDataSetView(
        loadErrorImageWidget,
        Container(
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              alignment: Alignment.center,
              width: 152,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: themeColor, width: 1),
              ),
              child: Text(
                '加载失败,再试试',
                style: TextStyle(color: themeColor, fontSize: 15),
              ),
            ),
          ),
        ));
  }

  /// 暂无数据
  @override
  Widget emptyOnLoadView() {
    return _emptyDataSetView(
        emptyImageWidget,
        Container(
          child: Text(
            emptyOnLoadText,
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ),
        width: 215,
        height: 120);
  }

  /// 加载更多数据
  @override
  Widget loadingMoreView() {
    return Container(
      height: 50,
      child: new Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CupertinoActivityIndicator(
            animating: true,
            radius: 10,
          ),
          SizedBox(width: 16.0),
          Text(
            '正在加载更多数据...',
            style: TextStyle(fontSize: 14.0),
          )
        ],
      )
          //child:
          ),
    );
  }

  /// 上拉加载更多
  @override
  Widget pullUpLoadMoreView(VoidCallback onPressed) =>
      _loadMoreDataView(onPressed);

  /// 没有更多数据
  @override
  Widget noMoreCanLoadView() {
    return Container(
        child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Center(
        child: Text("已经全部加载完毕"),
      ),
    ));
  }

  Widget _emptyDataSetView(Widget imageWidget, Widget bottomWidget,
      {double width, double height}) {
    return Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            imageWidget,
            SizedBox(
              height: 10,
            ),
            bottomWidget
          ],
        ));
  }

  /// 加载更多时失败
  @override
  Widget errorOnMoreView(VoidCallback onPressed) =>
      _loadMoreDataView(onPressed,"加载失败,点击重试");

  Widget _loadMoreDataView(VoidCallback onPressed, [String text]) {
    return GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(text ?? "上拉加载更多"),
        ));
  }
}
