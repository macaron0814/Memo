import 'package:flutter/material.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:memo/services/admob.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_review/app_review.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize();

  // 最初に表示するWidget
  runApp(MyTodoApp());
}

class MyTodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アプリ名
      title: 'メモリスタ',
      theme: ThemeData(
        // テーマカラー
        primarySwatch: Colors.deepOrange,
      ),
      // リスト一覧画面を表示
      home: DropDownPage(),
    );
  }
}

// リスト一覧画面用Widget
class DropDownPage extends StatefulWidget {
  @override
  _DropDownPageState createState() => _DropDownPageState();
}

class _DropDownPageState extends State<DropDownPage> {

  List<String> dropDownList = [];
  List<List<String>> todoList = [];
  List<List<bool>> isCheck = [];
  List<bool> isAllCheck = [];
  bool isReview = false;

  void Save() async {
    final pref = await SharedPreferences.getInstance();
    print("セーブ");
    pref.setStringList("dropDownList", dropDownList);
    pref.setInt("dropDownListAdd", dropDownList.length);
    pref.setBool("isReview", isReview);

    for(int j = 0; j < dropDownList.length; j++) {
      if(todoList[j].length != 0) {
        pref.setStringList("todoList" + j.toString(), todoList[j]);
        for(int i = 0; i < todoList[j].length; i++) {
          pref.setBool("isCheck" + j.toString() + i.toString(), isCheck[j][i]);
        }
      }
      pref.setInt("todoListAdd" + j.toString(), todoList[j].length);
    }
  }

  void Load() async {
    final pref = await SharedPreferences.getInstance();
    print("ロード");

    setState(() {
      //dropDownとtodoListの数は比例
      //todoList[j]の数はバラバラ
      int dropDownLength = pref.getInt("dropDownListAdd") ?? 0;
      for (int j = 0; j < dropDownLength; j++) {
        dropDownList.add("");
        isCheck.add([false]);
        todoList.add([""]);
        isAllCheck.add(false);
        int todoLength = pref.getInt("todoListAdd" + j.toString()) ?? 0;

        for (int i = 0; i < todoLength; i++) {
          todoList[j].add("");
          isCheck[j].add(false);
          todoList[j] = pref.getStringList("todoList" + j.toString()) ?? [];
          isCheck[j][i] = pref.getBool("isCheck" + j.toString() + i.toString()) ?? false;
          if(isCheck[j][i]){ isAllCheck[j] = true; }
        }
        dropDownList = pref.getStringList("dropDownList") ?? [];
      }

      isReview = pref.getBool("isReview") ?? false;
      if(!isReview && dropDownList.length != 0){
        RequestReview();
      }
    });
  }

  void RequestReview() {
    AppReview.requestReview.then((onValue) {
      isReview = true;
      Save();
    });
  }

  @override
  void initState() {
    super.initState();
    Load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('リスト一覧')
      ),
      body:
      ListView(
        children: <Widget>[
          for(int j = 0; j < dropDownList.length; j++) ...{
            ExpansionTile(
              onExpansionChanged: (bool changed) {
                //開いた時の処理を書ける
                setState(() {});
              },
              title: Text(dropDownList[j]),
              children: <Widget>[
                CheckboxListTile(
                  value: isAllCheck[j],
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    setState(() {
                      isAllCheck[j] = checked!;

                      //この項目の全てのCheckを外す
                      if(!isAllCheck[j]) {
                        for (int a = 0; a < isCheck[j].length; a++) {
                          isCheck[j][a] = false;
                        }
                      }
                      Save();
                    });
                  },
                ),
                for(int i = 0; i < todoList[j].length; i++) ... {
                  CheckboxListTile(
                    value: isCheck[j][i],
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setState(() {
                        isCheck[j][i] = checked!;

                        if(!isCheck[j][i]) {
                          for (int a = 0; a < isCheck[j].length; a++) {
                            if (isCheck[j][a]) {
                              isAllCheck[j] = true;
                              break;
                            }
                            else{ isAllCheck[j] = false; }
                          }
                        }
                        else{ isAllCheck[j] = true; }
                        Save();
                      });
                    },
                    title: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 1.55,
                          child:
                          TextField(
                            controller: TextEditingController(
                                text: todoList[j][i]),
                            //ここに初期値
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '忘れないようにメモしよう！',
                            ),
                            onChanged: (value) {
                              todoList[j][i] = value;
                              Save();
                            },
                          ),
                        ),
                        //削除
                        IconButton(
                          icon: Icon(Icons.clear),
                          alignment: Alignment.center,
                          splashRadius: 17.5,
                          onPressed: () {
                            setState(() {
                              // リスト追加
                              todoList[j].removeAt(i);
                              isCheck[j].removeAt(i);
                              if(todoList[j].length == 0){
                                todoList.removeAt(j);
                                isCheck.removeAt(j);
                                dropDownList.removeAt(j);
                                isAllCheck.removeAt(j);
                              }
                              Save();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                },
                Container(
                  width: 40.0,
                  //追加項目
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        // リスト追加
                        todoList[j].add("");
                        isCheck[j].add(false);
                        Save();
                      });
                    },
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          }
        ],
      ),
      //リスト追加Button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // "push"で新規画面に遷移
          // リスト追加画面から渡される値を受け取る
          final newListText = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              // 遷移先の画面としてリスト追加画面を指定
              return TodoAddPage();
            }),
          );
          if (newListText != null) {
            // キャンセルした場合は newListText が null となるので注意
            setState(() {
              // リスト追加
              dropDownList.add(newListText);
              todoList.add([""]);
              isCheck.add([false]);
              isAllCheck.add(false);
              Save();
            });
          }
        },
        child: Icon(Icons.add),
      ),

      bottomNavigationBar: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdmobBanner(
            adUnitId: AdMobService().getBannerAdUnitId(),
            adSize: AdmobBannerSize(
              width: MediaQuery.of(context).size.width.toInt(),
              height: AdMobService().getHeight(context).toInt(),
              name: 'SMART_BANNER',
            ),
          ),
        ],
      ),
    );
  }
}

class TodoAddPage extends StatefulWidget {
  @override
  _TodoAddPageState createState() => _TodoAddPageState();
}

class _TodoAddPageState extends State<TodoAddPage> {
  // 入力されたテキストをデータとして持つ
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // *** 追加する部分 ***
      appBar: AppBar(
        title: Text('リスト追加'),
      ),
      // *** 追加する部分 ***
      body: Container(
        // 余白を付ける
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 入力されたテキストを表示
            Text(_text, style: TextStyle(color: Colors.deepOrange)),
            const SizedBox(height: 8),
            // テキスト入力
            TextField(
              // 入力されたテキストの値を受け取る（valueが入力されたテキスト）
              onChanged: (String value) {
                // データが変更したことを知らせる（画面を更新する）
                setState(() {
                  // データを変更
                  _text = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              // 横幅いっぱいに広げる
              width: double.infinity,
              // リスト追加ボタン
              child: ElevatedButton(
                onPressed: () {
                  // *** 追加する部分 ***
                  // "pop"で前の画面に戻る
                  // "pop"の引数から前の画面にデータを渡す
                  Navigator.of(context).pop(_text);
                },
                child: Text('リスト追加', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              // 横幅いっぱいに広げる
              width: double.infinity,
              // キャンセルボタン
              child: TextButton(
                // ボタンをクリックした時の処理
                onPressed: () {
                  // "pop"で前の画面に戻る
                  Navigator.of(context).pop();
                },
                child: Text('キャンセル'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}