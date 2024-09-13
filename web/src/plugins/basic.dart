import 'dart:js_interop';

import 'package:web/web.dart';

import '../functions.dart';

class BasicEffectsPlugin extends DartFunctionPlugin {
  BasicEffectsPlugin(super.df);

  @override
  Future initializer() async {}

  // ? addClassDelay(milliseconds: 500, classList: is-rounded);
  bool _addClassDelay(Element element, HtmlFunction func) {
    if (func.args case [String milliseconds, String classes]) {
      Future.delayed(Duration(milliseconds: int.parse(milliseconds)), () {
        final res = classListsFromString(classes);
        // TODO Check this still works
        for (var klass in res.addClasses) {
          element.classList.add(klass);
        }
        for (var klass in res.removeClasses) {
          element.classList.remove(klass);
        }
      });
    }
    return true;
  }

  // ? onHover(classes: is-hovered)
  bool _onHover(Element element, HtmlFunction func) {
    final add = func.args[0];
    element.addEventListener(
        "mouseover",
        (Event event) {
          element.classList.add(add);
        }.toJS);

    element.addEventListener(
        "mouseout",
        (Event event) {
          element.classList.remove(add);
        }.toJS);

    return true;
  }

  // ? radioClass(click, wrap-button, wrap-button-active)
  bool _radioClass(Element element, HtmlFunction func) {
    final args = func.args;
    final add = args[0];
    final groupClass = args[1];
    final toggleClass = args[2];

    element.addEventListener(
        add,
        (Event event) {
          final nl = document.querySelectorAll(".$groupClass");
          for (var i = 0; i < nl.length; i++) {
            var el = nl.item(i) as Element;
            if (el != element) {
              el.classList.remove(toggleClass);
            }
            element.classList.add(toggleClass);
          }
        }.toJS);
    return true;
  }

  // ! END FUNCTIONS
  @override
  void registerFunctions() {
    df.functionMap['addClassDelay'] = _addClassDelay;
    df.functionMap['radioClass'] = _radioClass;
    df.functionMap['onHover'] = _onHover;
  }
}
