import 'dart:async';

//import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/* 计算获取section数量count */
typedef ListViewSectionCountBuilder = int Function();

/* 每个section对应的分组有多少个item count数量 */
typedef ListViewSectionRowCountBuilder = int Function(int section);

/* listView 的头部、尾部、加载更多Widget*/
typedef ListViewWidgetBuilder = Widget Function(BuildContext context);

/* itemBuilder item对应的widget */
typedef ListViewItemWidgetBuilder = Widget Function(
    BuildContext context, int section, int index);

/* 分组的头部、尾部、对应的widget */
typedef ListViewReuseableWidgetBuilder = Widget Function(
    BuildContext context, int section);

/* item的builder点击 */
typedef ListViewItemOnTapCallback = void Function(
    BuildContext context, int section, int index);

/* item的builder 能否点击 */
typedef ListViewItemShouldTapCallback = bool Function(
    BuildContext context, int section, int index);

/* 枚举： 滚动到的位置 */
enum ListViewItemPosition { top, middle, bottom }

/* 一些常量设置 */
const int _sectionHeaderIndex = -1;
const String _footerCacheKey = 'footer';
const String _loadMoreCacheKey = 'loadMore';

/*
 *
 * --------------------------------  ListViewItemBuilder --------------------------------------
 *
 */

class ListViewItemBuilder {
  /// * 有多少个section
  ListViewSectionCountBuilder sectionCountBuilder;

  /// * 每个section对应有多少行
  ListViewSectionRowCountBuilder sectionRowCountBuilder;

  /// * list的item builder, 每组中的item
  ListViewItemWidgetBuilder listItemBuilder;

  /// * 分组的头部builder
  ListViewReuseableWidgetBuilder sectionHeaderBuilder;

  /// * 分组的尾部builder
  ListViewReuseableWidgetBuilder sectionFooterBuilder;

  /// * listVie的头部builder
  ListViewWidgetBuilder headerWidgetBuilder;

  /// * listVie的尾部builder
  ListViewWidgetBuilder footerWidgetBuilder;

  /// * listVie的底部加载更多
  ListViewWidgetBuilder loadMoreWidgetBuilder;

  /// * item的builder点击回调
  ListViewItemOnTapCallback itemOnTapCallback;

  /// * item是否能够点击
  ListViewItemShouldTapCallback itemShouldTap;

  /// * 控制滚动的scrollController
  ScrollController scrollController;

  /// * 控制滚动方向 (默认竖直方向)
  Axis scrollDirection = Axis.vertical;

  /// * listView的上下文
  BuildContext _listViewBuildContext;

  /// * 缓存所有item的高度
  Map<String, Size> _itemsSizeCache = <String, Size>{};

  /// 定义的ListView 构造方法
  ListViewItemBuilder({
    ListViewSectionCountBuilder sectionCountBuilder, // 返回多少个section
    this.sectionRowCountBuilder, // 每个section有多少个item
    this.listItemBuilder, // 每个section中有多少个itemBuilder
    this.sectionHeaderBuilder,
    this.sectionFooterBuilder,
    this.headerWidgetBuilder,
    this.footerWidgetBuilder,
    this.loadMoreWidgetBuilder,
    this.itemOnTapCallback,
    ListViewItemShouldTapCallback itemShouldTap,
    this.scrollController,
    this.scrollDirection,
  })  : sectionCountBuilder =
            sectionCountBuilder ?? ListViewItemBuilder._sectionCountBuilder,
        itemShouldTap = itemShouldTap ?? ListViewItemBuilder._itemShouldTap,

        /// 这里使用类调用_itemShouldTap，是因为构造方法还没完成，不能使用对象方法，只能用类方法
        super();

  /// 返回列表显示的widget, 包括header, sectionHeader, item, sectionFooter, footer loadMode
  /// *******  这里的index 是flutter SDK内部给出的，
  Widget itemBuilder(BuildContext context, int index) {
    _listViewBuildContext = context;
//    print('index: $index');
    return _iterateItems(true, index) as Widget;
  }

  /// 返回item的数量
  int get itemCount => _iterateItems(false, null) as int;

  /// 获取widget 或者 item的数量
  /// getWidget: true  返回的是widget
  /// getWidget: false 返回的是item的数量
  dynamic _iterateItems(bool isGetWidget, int index) {
    // 断言
    assert(sectionRowCountBuilder != null);
    assert(listItemBuilder != null);

    // 缓存所有item的key(key相当于唯一标识id)
    Set<String> itemKeyCache = Set<String>();

    // 标记每一个widget的索引
    int idx = 0;

    // 1. -----------------------------------------------  设置headerView
    if (headerWidgetBuilder != null) {
      // TODO: 这里只是定义方法，怎么能拿到
      // TODO: 在main.dart中通过函数传递进来
      var headerWidget = headerWidgetBuilder(_listViewBuildContext);
      if (headerWidget != null) {
        idx += 1;

        // 获取拼接的key
        var cacheKey = _cacheKey(section: _sectionHeaderIndex, index: 0);
        itemKeyCache.add(cacheKey);

        if (isGetWidget && index == 0) {
          return _buildWidgetContainer(
              cacheKey,
              false,
              headerWidget ??
                  Container(
                    height: 0,
                    color: Colors.transparent,
                  ));
        }
      }
    }

    // 组 section, 外面传进来的
    int sectionCount = sectionCountBuilder();

    for (int i = 0; i < sectionCount; i++) {
      // 2. -----------------------------------------------   设置组的头部

      // 组头部的++
      idx++;
      var cacheKey = _cacheKey(section: i, index: _sectionHeaderIndex);

      if (isGetWidget) {
        var sectionHeaderWidget;
        if (sectionHeaderBuilder != null) {
          sectionHeaderWidget = sectionHeaderBuilder(_listViewBuildContext, i);
        }

        if (idx == (index + 1)) {
          return _buildWidgetContainer(
              cacheKey,
              false,
              sectionHeaderWidget ??
                  Container(
                    height: 0,
                    color: Colors.transparent,
                  ));
        }
      } else {
        // 返回个数
        itemKeyCache.add(cacheKey);
      }

      // 3. -----------------------------------------------  设置item
      // 每组多少个item  这里的rowCount就是外面函数调用返回 【(int section) => 10,】
      var rowCount = sectionRowCountBuilder(i);
      if (isGetWidget) {
        // 返回每组的item
        for (int j = 0; j < rowCount; j++) {
          if (index == (idx + j)) {
            // 创建item
            Widget item = listItemBuilder(_listViewBuildContext, i, j);
            bool canTap = itemOnTapCallback != null &&
                itemShouldTap != null &&
                itemShouldTap(_listViewBuildContext, i, j) == true;

            var cacheKey = _cacheKey(section: i, index: j);
            return _buildWidgetContainer(cacheKey, canTap, item);
          }
        }
      } else {
        // 返回每组item数量
        for (int j = 0; j < rowCount; j++) {
          itemKeyCache.add(_cacheKey(section: i, index: j));
        }
      }

      idx += rowCount;

      // 4. ------------------------------ 设置组的尾部 SectionFooter

      // 组尾部的++
      idx++;
      if (isGetWidget) {
        var sectionFooterWidget;
        if (sectionFooterBuilder != null) {
          sectionFooterWidget = sectionFooterBuilder(_listViewBuildContext, i);
        }

        if (idx == index + 1) {
          var cacheKey = _cacheKey(section: i, index: rowCount);
          return _buildWidgetContainer(
              cacheKey,
              false,
              sectionFooterWidget ??
                  Container(
                    height: 0,
                    color: Colors.transparent,
                  ));
        }
      } else {
        itemKeyCache.add(_cacheKey(index: rowCount, section: i));
      }
    }

    // 5. ------------------------------ 设置list的 footerWidget
    Widget footerWidget;
    if (footerWidgetBuilder != null) {
      footerWidget = _ListViewItemContainer(
        canTap: false,
        cacheKey: _footerCacheKey,
        itemHeightCache: _itemsSizeCache,
        child: footerWidgetBuilder(_listViewBuildContext),
      );

      if (footerWidget != null) {
        idx += 1;
      }
    }

    // 6. ------------------------------ 设置listView loadMore
    Widget loadMoreWidget;
    if (loadMoreWidgetBuilder != null) {
      loadMoreWidget = _ListViewItemContainer(
        canTap: false,
        cacheKey: _loadMoreCacheKey,
        itemHeightCache: _itemsSizeCache,
        child: loadMoreWidgetBuilder(_listViewBuildContext),
      );
      if (loadMoreWidget != null) {
        idx += 1;
      }
    }

    // 7.1 ====================  这里返回 widget
    if (isGetWidget) {
      if (footerWidget != null && loadMoreWidget != null) {
        if (idx == index + 2) {
          return footerWidget;
        } else {
          return loadMoreWidget;
        }
      } else if (footerWidget != null && loadMoreWidget == null) {
        return footerWidget;
      } else if (footerWidget == null && loadMoreWidget != null) {
        return loadMoreWidget;
      } else {
        return Container(
          height: 0,
          color: Colors.transparent,
        );
      }
    }

    // 7.2 ====================  这里返回 count
    if (!isGetWidget) {
      // 这里移除键值对， 通过key指出， 谓词检索出要删除的
      _itemsSizeCache.removeWhere((key, value) => !itemKeyCache.contains(key));
    }
    return idx;
  }

  /// 包装widget (header、)
  Widget _buildWidgetContainer(String cacheKey, bool canTap, Widget widget) {
    return _ListViewItemContainer(
      cacheKey: cacheKey,
      child: widget,
      canTap: canTap,
      itemOnTapCallback: itemOnTapCallback,
      listViewContext: _listViewBuildContext,
      itemHeightCache: _itemsSizeCache,
    );
  }

  /// 转文本
  String _cacheKey({int section, int index}) {
    return '${section.toString()}+${index.toString()}';
  }

  double _getHeight(Size size) =>
      (scrollDirection == Axis.vertical ? size?.height : size?.width) ?? 0;

  /// (static类方法) 默认多少分组
  static int _sectionCountBuilder() => 1;

  /// (static类方法)默认能够点击
  static bool _itemShouldTap(BuildContext context, int section, int index) =>
      true;

  /// ------------------------------------------------------------------------------------------ 滚动跳转

  Future<void> scrollTo(int section, int row,
      {bool animation, Duration duration}) {
    print('滚动跳转逻辑在这里写');

    if (animation) {
      _animateTo(section, row, duration);
    } else {
      _jumpTo(section, row);
    }
  }

  Future<void> _animateTo(int section, int row, Duration duration) {}

  Future<void> _jumpTo(int section, int row) {
    return _jumpToPoistion(section, row, poistion: ListViewItemPosition.top);
  }

  Future<void> _jumpToPoistion(int section, int row,
      {ListViewItemPosition poistion = ListViewItemPosition.top}) async {
    assert(section != null && row != null);
    assert(scrollController != null);
    // assert(scrollController.hasClients == true);
    assert(_listViewBuildContext?.findRenderObject()?.paintBounds != null,
        '❌The listView must already be laid out.');
    assert(() {
      int sectionCount = sectionCountBuilder();
      if (section >= sectionCount || section < 0) return false;

      int rowCount = sectionRowCountBuilder(section);
      if (row >= rowCount || row < 0) return false;
      return true;
    }(),
        "❌section:${section.toString()} index:${row.toString()} was beyond bounds");

    // 定义最大的section, 最大的row
    int maxSection = _sectionHeaderIndex;
    int maxRow = _sectionHeaderIndex;

    // 总高度
    double itemsTotalHeight = 0;
    double targetItemHeight = 0;
    double targetItemTop = 0;

    //
    // 遍历
    var listViewHeight = _getHeight(
        _listViewBuildContext?.findRenderObject()?.paintBounds?.size);

    _itemsSizeCache.forEach((key, size) {
      var keys = key.split('+');
      if (keys == null || keys.length != 2) return;

      var cacheSection = int.parse(keys.first);
      var cacheRow = int.parse(keys.last);
      var itemHeight = _getHeight(size);

      // 找到最大的section 和最大的index
      if (cacheSection > maxSection ||
          (cacheSection == maxSection && cacheRow > maxRow)) {
        maxSection = cacheSection;
        maxRow = cacheRow;
        itemsTotalHeight += itemHeight;
      }

      // 要跳转到的item顶部距离
      if (cacheSection < section ||
          (cacheSection == section && cacheRow < row)) {
        targetItemTop += itemHeight;
      }

      // 设置widget的高度
      if (row == maxRow && section == cacheSection) {
        targetItemHeight = itemHeight;
      }

    });

    // 到这里目标item可以看到了，跳转到可见的item
    if (section < maxSection || (section == maxSection && row < maxRow)) {

      print('这里是真的跳转地方：');
      return scrollController.jumpTo(_calculateOffset(
          targetItemTop, targetItemHeight,
          position: poistion, listViewHeight: listViewHeight));
    } else {
      // 目标项目是不可见的，它还没有被布局。
     // 跳转到不可见位置的item
      print('不可见位置的item');
    }

  }

  /// 计算要滚动到的位置
  double _calculateOffset(double top, double itemHeight,
      {ListViewItemPosition position = ListViewItemPosition.top,
      double listViewHeight}) {
    double offset = 0.0;
    switch (position) {
      case ListViewItemPosition.top:
        offset = top;
        break;
      case ListViewItemPosition.middle:
        offset = top + itemHeight * 0.5;
        break;
      case ListViewItemPosition.bottom:
        offset = top + itemHeight;
        break;
    }

    if (offset > scrollController.position.maxScrollExtent) {
      return _min(offset, _maxScrollExtent() - listViewHeight);
    } else {
      return offset;
    }
  }

  double _maxScrollExtent() {
    double height = 0.0;
    _itemsSizeCache.values.forEach((size) {
      height += _getHeight(size);
    });
    return height;
  }

  _min(double a, double b) => a < b ? a : b;
}

/**
 *
 *
 *
 */

/// -------------------------------- -------------------------------- --------------------------------
/// --------------------------------     _listViewItemContainer       --------------------------------
/// -------------------------------- -------------------------------- --------------------------------
class _ListViewItemContainer extends StatefulWidget {
  /// * 唯一标识 Key
  final String cacheKey;

  /// * 能够点击
  final bool canTap;

  /// * 点击回调
  final ListViewItemOnTapCallback itemOnTapCallback;

  /// * 上下文
  final BuildContext listViewContext;

  /// * 子widget
  final Widget child;

  /// * 高度缓存字典
  final Map<String, Size> itemHeightCache;

  @override
  State<StatefulWidget> createState() => _ListViewItemContainerState();

  // 构造方法
  _ListViewItemContainer({
    this.canTap,
    this.itemOnTapCallback,
    this.listViewContext,
    this.child,
    this.cacheKey,
    this.itemHeightCache,
  });
}

class _ListViewItemContainerState extends State<_ListViewItemContainer> {
  @override
  Widget build(BuildContext context) {
    /// : NotificationListener是以冒泡的方式监听Notification的组件，冒泡方式就是向上传递，从子组件向父组件传递。
    /// 系统定义了很多Notification，比如LayoutChangedNotification，SizeChangedLayoutNotification、ScrollNotification、KeepAliveNotification、OverscrollIndicatorNotification、DraggableScrollableNotification等。


    /// TODO: 注意一定要监听的对象类型<LayoutChangedNotification>  否则onNotification：接收不到发送的通知消息
    return NotificationListener<LayoutChangedNotification>(
      onNotification: (notification) {
        /// TODO: 2. 这里是接收通知
        _saveHeightToCache();

        /// onNotification的方法需要返回bool值，返回true, 表示当前事件不在向上传递，false表示继续向上传递，
        return false;
      },
      child: InitialSizeChangeLayoutNotifier(
        /// : InkWell组件在用户 点击时 会出现'水波纹'的效果
        child: widget.canTap
            ? InkWell(
                child: widget.child,
                splashColor: Colors.redAccent, // 设置水波纹颜色
                onTap: () {
                  // 分割成数组
                  var keys = widget.cacheKey.split('+');
                  if (keys == null || keys.length != 2) return;

                  // 字符串转int
                  var section = int.parse(keys.first);
                  var index = int.parse(keys.last);
                  // 回调出去
                  widget.itemOnTapCallback(
                      widget.listViewContext, section, index);
                },
              )
            : Container(
                color: Colors.transparent, // 透明色
                child: widget.child,
              ),
      ),
    );
  }

  _saveHeightToCache() {
    if (!mounted) return;

    // 到这里已经渲染完成了， 可以去到size
    var size = context.findRenderObject()?.paintBounds?.size;
    if (size != null) {
      /// 缓存高度
      widget.itemHeightCache[widget.cacheKey] = size;
    }
  }
}

/*
 *
 * --------------------------------  InitialSizeChangedLayoutNotifier --------------------------------------
 *
 */

class InitialSizeChangeLayoutNotifier extends SingleChildRenderObjectWidget {
  const InitialSizeChangeLayoutNotifier({Key key, Widget child})
      : super(key: key, child: child);

  @override
  InitialRenderSizeChangedWithCallback createRenderObject(
      BuildContext context) {
    return InitialRenderSizeChangedWithCallback(onLayoutChangedCallback: () {

      /// TODO: 1.这里是发送通知
      SizeChangedLayoutNotification().dispatch(context);
    });
  }
}

/*
 *
 * --------------------------------  _InitialRenderSizeChangedWithCallback --------------------------------------
 *
 */

class InitialRenderSizeChangedWithCallback extends RenderProxyBox {
  final VoidCallback onLayoutChangedCallback;
  Size _oldSize;

  InitialRenderSizeChangedWithCallback({
    RenderBox child,
    this.onLayoutChangedCallback,
  })  : assert(onLayoutChangedCallback != null),
        super(child);

  @override
  void performLayout() {
    super.performLayout();
    if (size != _oldSize) {
      // 执行回调更新， 更新size
      onLayoutChangedCallback();
    }

    // 重新保存
    _oldSize = size;
  }
}
