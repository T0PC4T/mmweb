import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

import 'plugins/basic.dart';
import 'plugins/scroll.dart';
import 'plugins/shaders.dart';

extension on NodeList {
  Iterable<Element> get iter => () sync* {
        for (int i = 0; i < length; i++) {
          yield item(i) as Element;
        }
      }();
}

class DartFunction {
  List<DartFunctionPlugin> plugins = [];
  Map<String, bool Function(HTMLElement, HtmlFunction)> functionMap = {};
  DartFunction() {
    plugins = [
      BasicEffectsPlugin(this),
      ScrollPlugin(this),
      ShaderPlugin(this),
    ];
    // js.context['runFunctions'] = runFunctions;
  }

  void runFunctions() async {
    // ? Start up plugins
    if (functionMap.isEmpty) {
      for (var plugin in plugins) {
        await plugin.initializer();
        plugin.registerFunctions();
      }
    }

    // ? get functions
    for (HTMLElement element in document
        .querySelectorAll("*[data-function]")
        .iter
        .map((e) => e as HTMLElement)) {
      for (final funcString
          in element.attributes["data-function"].toString().split(";")) {
        _runFuction(element, funcString);
      }
    }
  }

  void _runFuction(HTMLElement element, String funcString) async {
    final f = HtmlFunction(funcString);
    if (functionMap.containsKey(f.name)) {
      final response = functionMap[f.name]!.call(element, f);
      if (response) {
        element.removeAttribute("data-function");
      }
      return;
    }
    print("[!] Unable to find function $funcString");
  }
}

// ? UTIL OBJECTS //

abstract class DartFunctionPlugin {
  final DartFunction df;
  DartFunctionPlugin(this.df);
  Future<void> initializer();
  // null = function not found
  // true = function run and can be removed
  // false = function found but did not complete
  void registerFunctions();
}

class HtmlFunction {
  late String name;
  late List<String> args;

  static RegExp spaces = RegExp(
    r"[\s]",
    caseSensitive: true,
    multiLine: false,
  );

  String? operator [](int key) {
    if (args.length > key) {
      return args[key];
    }
    return null;
  }

  HtmlFunction(funcString) {
    name = funcString.split("(")[0];
    final paramsString = funcString
        .split("(")[1]
        .split(")")[0]
        .toString()
        .replaceAll(spaces, "");
    args = paramsString.split(",");
  }
}

({Iterable<String> addClasses, Iterable<String> removeClasses})
    classListsFromString(String input) {
  final addClasses = input.split("|").where((element) => element[0] != "!");

  final removeClasses = input
      .split("|")
      .where((element) => element[0] == "!")
      .map((e) => e.substring(1));

  return (addClasses: addClasses, removeClasses: removeClasses);
}

// ? JS INTERLOP //
@JS('window')
external Window get jsWindow;

@JS('Object')
extension type SObject._(JSAny _jsObject) implements JSAny {
  external static JSArray<JSString> keys(JSObject _);
}

// ? UTIL FUNCTIONS //

JSAny convertValueToJS(dynamic value) {
  if (value is JSAny) {
    return value;
  }
  if (value is String) {
    return value.toJS;
  } else if (value is num) {
    return value.toJS;
  } else if (value is bool) {
    return value.toJS;
  } else if (value is List<JSAny>) {
    return value.toJS;
  } else if (value is Map<dynamic, dynamic>) {
    return value.toJS;
  }

  throw "Unable to convert $value";
}

extension UtilMap on Map<dynamic, dynamic> {
  JSObject get toJS {
    final object = JSObject();

    for (var mapEntry in entries) {
      object.setProperty(
          convertValueToJS(mapEntry.key), convertValueToJS(mapEntry.value));
    }

    return object;
  }
}

extension UtilList on List<dynamic> {
  JSArray get toJSArray {
    final object = JSArray();

    for (var entry in this) {
      object.add(convertValueToJS(entry));
    }

    return object;
  }
}

extension UtilAny on JSAny? {
  JSObject? get obj => this as JSObject;
}

extension UtilObj on JSObject {
  Map<String, dynamic>? get toMap {
    if (isNull) {
      return null;
    }

    final dartMap = <String, dynamic>{};
    final keys = SObject.keys(this).toDart;

    for (var key in keys) {
      final value = getProperty(key);
      String dkey = key.toDart;

      if (value == null) {
        dartMap[dkey] = null;
      } else if (value is bool || value is num || value is String) {
        dartMap[dkey] = value;
      } else if (value is JSArray) {
        // Assume it's an array-like object
        dartMap[dkey] = value.toDart;
      } else if (value is JSObject) {
        dartMap[dkey] = value.toMap;
      } else {
        dartMap[dkey] = value.toString();
      }
    }

    return dartMap;
  }
}
