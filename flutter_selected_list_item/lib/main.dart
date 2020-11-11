import 'package:flutter/material.dart';
import 'package:flutter_selected_list_item/list_view_item_builder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('jump to item of section'),
        ),
        body: ListViewPage(),
      ),
    );
  }
}


class ListViewPage extends StatefulWidget {
  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  // 1. 定义变量

  // 定义的控制listView的变量
  ListViewItemBuilder _listViewItemBuilder;

  // 定义控制滚动的scrollController
  ScrollController _scrollController = ScrollController();

  // 文本输入控制 (默认 2  1 )
  TextEditingController _sectionTextEditingController =
      TextEditingController(text: '0');
  TextEditingController _rowTextEditingController =
      TextEditingController(text: '4');

  // 是否使用动画 (默认没有动画)
  bool _animation = false;

  // 滚动方向 （竖直滚动）
  Axis _scrollDirection = Axis.vertical;

  // 滚动列表方向是否能改变
  bool _scrollDirectionChangerd = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initItemBuilder();
  }

  _initItemBuilder() {
    _listViewItemBuilder = ListViewItemBuilder(
      sectionCountBuilder: () => 10,
      sectionRowCountBuilder: (int section) => 5,
      listItemBuilder: _itemsBuilder,
      sectionHeaderBuilder: _sectionHeaderBuilder,
      // 这里是通过里面定义的函数在外面实现， 这里不是调用函数， 只是外面实现然后传入函数参数，
      sectionFooterBuilder: _sectionFooterBuilder,
      headerWidgetBuilder: (ctx) => _widgetBuilder('HeaderWidget', Colors.green, height: 80),
      footerWidgetBuilder: (ctx) => _widgetBuilder('FooterWidget', Colors.green, height: 80),
      loadMoreWidgetBuilder: (ctx) => _widgetBuilder('loadMoreWidget', Colors.lightBlue, height: 120),

      itemOnTapCallback: _itemOnTap,
      // 点击回调打印
      itemShouldTap: _itemShouldTap,
      // 是否应该点击判断
      scrollController: _scrollController,
      scrollDirection: _scrollDirection,
    );
  }

  Widget _itemsBuilder(BuildContext context, int section, int index) {
    return _widgetBuilder(
        'section:${section.toString()}, index:${index.toString()},',
        Colors.white70,
        richText: 'canTap:${_itemShouldTap(context, section, index)}',
        height: 50);
  }

  Widget _sectionHeaderBuilder(BuildContext context, int section) {
    return _widgetBuilder('headerSection:${section.toString()}', Colors.yellow,
        height: 30);
  }

  Widget _sectionFooterBuilder(BuildContext context, int section) {
    return _widgetBuilder('footerSection:${section.toString()}', Colors.orange,
        height: 30);
  }

  /// list头部  组头部， 组尾部  item  loadMore
  ///
  Widget _widgetBuilder(String text, Color color,
      {double height, String richText}) {
    var size = height ?? 44;
    return Container(
      height: _scrollDirection == Axis.horizontal ? null : size,
      width: _scrollDirection == Axis.horizontal ? size : null,
      color: color,
      alignment: Alignment.center,
      child: !text.contains('index:')
          ? Text(text, style: TextStyle(color: Colors.black, fontSize: 18))
          : RichText(
              // item需要用到富文本
              text: TextSpan(children: <TextSpan>[
                TextSpan(
                    text: text,
                    style: TextStyle(fontSize: 18, color: Colors.black)),
                TextSpan(
                    text: richText,
                    style: TextStyle(
                        fontSize: 18,
                        color: () {
                          // 这里用的匿名函数， 这里面计算判断得出结果
                          return richText.contains('true')
                              ? Colors.black
                              : Colors.red;
                        }()))
              ]),
              textAlign: TextAlign.center,
              softWrap: true,
              // 是否会换行， 如果为false 如果文本超过1行，不换换行， 默认是true
              textScaleFactor: 1.1,
              // 缩放倍数
              textWidthBasis: TextWidthBasis.longestLine, // 相对宽度是基于谁的
            ),
    );
  }

  /*
   * 设置输入文案的widget
   * */
  Widget _buildInputWidget(String title, TextEditingController editController) {
    return Container(
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontSize: 16),
          ),
          Container(
            width: 30,
            child: TextField(
              controller: editController, // 监听输入的文本
              keyboardType: TextInputType.number, // 设置输入键盘类型
            ),
          ),
        ],
      ),
    );
  }

  bool _itemShouldTap(BuildContext context, int section, int index) {
    // print('🔥 section: $section, row: $index');

    return index != 0;
  }

  void _itemOnTap(BuildContext context, int section, int index) {
    print(
        '🔥click ==>  section: ${section.toString()}, index:${index.toString()}');

    // 关闭键盘
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /*
   *  ****************************************************************
   *  上部分的widget
   *
   * */
  Widget _topPartWidget() {
    return Container(
      color: Colors.brown,
      child: Column(
        children: [
          Row(
            // --------------------------- 第一部分
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FlatButton(
                  onPressed: () {
                    // 关闭键盘
                    FocusScope.of(context).requestFocus(FocusNode());
                    // 转int类型
                    int section = int.parse(_sectionTextEditingController.text);
                    int row = int.parse(_rowTextEditingController.text);

                    // 跳转到指定组 & 行
                    _listViewItemBuilder.listViewScrollTo(section, row, animation: _animation, duration: Duration(seconds: 1));
                  },
                  child: Text(
                    'jumpTo',
                    style: TextStyle(fontSize: 18, color: Colors.yellow),
                  )),
              Text(
                'animate',
                style: TextStyle(fontSize: 16),
              ),
              Checkbox(
                  value: _animation,
                  onChanged: (value) {
                    // 开关动画
                    setState(() {
                      _animation = value;
                    });
                  }),
              Text(
                'isVertical',
                style: TextStyle(fontSize: 16),
              ),
              Checkbox(
                  value: _scrollDirection == Axis.vertical, // 默认竖直滚动
                  onChanged: (value) {
                    setState(() {
                      if (_scrollDirectionChangerd) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text('滚动方向只能修改一次'),
                          ),
                        );
                      } else {
                        _scrollDirection =
                            value ? Axis.vertical : Axis.horizontal;
                        _listViewItemBuilder.scrollDirection = _scrollDirection;
                      }
                      // 标记已经改变过了
                      _scrollDirectionChangerd = true;
                    });
                  }),
            ],
          ),
          Row(
            // ------------------------  第二部分
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildInputWidget('section：', _sectionTextEditingController),
              _buildInputWidget('index：', _rowTextEditingController),
            ],
          ),
        ],
      ),
    );
  }

  /*
   *
   * ------------------------------------------------------ build --------------------------------------------
   * */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topPartWidget(),
        Expanded(
            child: ListView.builder(
          /// shrinkWrap特别推荐
          /// child 高度会适配 item填充的内容的高度,我们非常的不希望child的高度固定，因为这样的话，如果里面的内容超出就会造成布局的溢出。
          /// shrinkWrap多用于嵌套listView中 内容大小不确定
          /// 比如 垂直布局中 先后放入文字 listView （需要Expend包裹否则无法显示无穷大高度 但是需要确定listview高度 shrinkWrap使用内容适配不会有这样的影响）
          shrinkWrap: true,
          itemBuilder: _listViewItemBuilder.itemBuilder,
          // TODO: 为什么调用函数不需要传参数, 这里只是引用，具体实现在_listViewItemBuilder中，对应的是listItemBuilder传值
          itemCount: _listViewItemBuilder.itemCount,
          padding: const EdgeInsets.all(0),
         controller: _scrollController,
//          // 滑动监听
         scrollDirection: _scrollDirection,
        )),
      ],
    );
  }
}
