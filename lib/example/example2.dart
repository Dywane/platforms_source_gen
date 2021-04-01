import 'dart:typed_data';

// "bool": "Boolean",
// "int": "Long",
// "double": "Double",
// "String": "String",
// "Uint8List": "byte[]",
// "Int32List": "int[]",
// "Int64List": "long[]",
// "Float64List": "double[]",
  class MyClass2 {
  // var a = ""; it's not support start with var
  //dynamic a = ""; it's not support start with dynamic

  bool boo;
  bool boo1 = true;

  int a;
  int a1 = 0;

  double c;
  double c1 = 0.1;

  String d;
  String d1 = "default";

  Uint8List e;
  Uint8List e1 = Uint8List(10);
  Uint8List e2 = new Uint8List(100);

  Int32List f;
  Int32List f1 = Int32List(5);
  Int32List f2 = new Int32List(75);

  Int64List g;
  Int64List g1 = Int64List(8);
  Int64List g2 = new Int64List(9);

  Float64List h;
  Float64List h1 = Float64List(45);
  Float64List h2 = new Float64List(13);

  // Object h; //it's not support.
  List<int> i;
  List<int> i1 = [];
  List<int> i2 = [1, 2, 3, 4];
  List<InnerClass2> j;
  List<InnerClass2> j1 = [];
  List<InnerClass2> j2 = [
    InnerClass2(),
    InnerClass2(),
    InnerClass2(),
    InnerClass2(),
    InnerClass2(),
    InnerClass2(),
    InnerClass2(),
  ]; //

  // List e = []; //don't do it, is the same List<dynamic>, it's not support
  // List<dynamic> f = []; ////don't do it, dynamic is not support

  Map<String, int> k;
  Map<String, int> k1 = {};
  Map<String, int> k2 = {"key": 1, "key2": 2};
  Map<InnerClass2, InnerClass2> l;
  Map<InnerClass2, InnerClass2> l1;
  Map<InnerClass2, InnerClass2> l2 = {
    InnerClass2(): InnerClass2(),
    InnerClass2(): InnerClass2(),
    InnerClass2(): InnerClass2(),
  };
}

class InnerClass2 {
  String a;
  int b;
}

class Route2 {
  static const String main_page = "/main/page"; //main page
  static const String mine_main = "/mine/main"; //
  static const int int_value = 123;
}
