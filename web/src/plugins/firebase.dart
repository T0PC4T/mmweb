// import 'dart:html';
// import 'dart:js' as js;

// import '../functions.dart';

// class FirebasePlugin implements DartFunctionPlugin {
//   late JsWrapper fb;
//   late JsWrapper db;

//   static const firebaseConfig = {
//     "apiKey": "AIzaSyC-IJJWKuAMxWtyq_YG-VTgjCtNpuFn_DA",
//     "authDomain": "thomas-clovis.firebaseapp.com",
//     "projectId": "thomas-clovis",
//     "storageBucket": "thomas-clovis.appspot.com",
//     "messagingSenderId": "941242414378",
//     "appId": "1:941242414378:web:d16c1483a20dd6447f1a53",
//     "measurementId": "G-L0YR95QSXL"
//   };
//   Future setupFirebase() async {
//     var jsMap = js.JsObject.jsify(firebaseConfig);
//     final firebase = JsWrapper.context("firebase");
//     firebase.callMethod("initializeApp", [jsMap]);
//   }

//   @override
//   Future initializer() async {
//     setupFirebase();
//     fb = JsWrapper.context("firebase");
//     db = fb.callMethod("firestore");
//   }

//   // ! FUNCTIONS

//   _get(Element element, HtmlFunction func) async {
//     final String collectionName = func[0]!;
//     final collection = db.callMethod("collection", [collectionName]);

//     final String docName = func[1]!;
//     final query = collection.callMethod("doc", [docName]);

//     final result = await query.callMethod("get").toFuture();

//     final data = result.callMethod("data").jsObject;
//     data?["id"] = docName;

//     final exists = result.get<bool, js.JsObject>("exists");
//     if (exists) {
//       element.style.opacity = "0";
//       Element newElement =
//           mergeElement(element, result.callMethod("data").jsObject);
//       element.replaceWith(newElement);
//       await Future.delayed(Duration(milliseconds: 1));
//       newElement.style.opacity = "1";
//     }
//   }

//   _post(Element element, HtmlFunction func) async {
//     final String collectionName = func[0]!;
//     final String functionName = func[1]!;
//     js.context[functionName] = () async {
//       final submit = element.querySelector("#submitButton") as InputElement;
//       submit.disabled = true;

//       final inputs = element.querySelectorAll("*[data-name]");
//       final collection = db.callMethod("collection", [collectionName]);
//       await collection.callMethod("add", [
//         js.JsObject.jsify({
//           for (dynamic el in inputs) el.attributes["data-name"]: el.value,
//         }),
//       ]).toFuture();
//       element.setInnerHtml(
//           "<h3 style='width:100%;display:flex;justify-content:center;'>Message Received</h3>",
//           validator: MyValidator());
//     };

//     // db.collection("cities").add({name: "Tokyo", country: "Japan"});
//   }

//   _fetch(Element element, HtmlFunction func) async {
//     final String collectionName = func[0]!;
//     final String? orderField = func[1];
//     final String? limitStr = func[2];
//     final int? limit = limitStr != null ? int.parse(limitStr) : null;

//     final collection = db.callMethod("collection", [collectionName]);
//     JsWrapper query = collection;
//     if (orderField != null) {
//       query = query.callMethod("orderBy", [orderField]);
//     }
//     if (limit != null) {
//       query = query.callMethod("limit", [limit]);
//     }

//     final result = await query.callMethod("get").toFuture();
//     final docs = result.get<JsWrapper<js.JsArray>, js.JsArray>("docs");
//     List<js.JsObject> dataList = [];

//     for (var doc in docs.jsObject) {
//       final data = (doc as js.JsObject).callMethod("data") as js.JsObject;
//       data["id"] = doc["id"];
//       dataList.add(data);
//     }
//     mergeFunction(element, dataList);
//   }

//   // ! END FUNCTIONS

//   @override
//   bool runFuction(Element element, HtmlFunction func) {
//     final f = switch (func.name) {
//       'fetch' => _fetch,
//       'post' => _post,
//       'get' => _get,
//       // 'addShader' => _addShader,
//       _ => null
//     };
//     if (f case Function f) {
//       f.call(element, func);
//     }
//     return false;
//   }
// }
