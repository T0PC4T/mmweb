import 'dart:js_interop';

import 'package:web/web.dart';

import '../functions.dart';
import 'util.dart';

class ScrollPlugin extends DartFunctionPlugin {
  ScrollPlugin(super.df);
  static List<ScrollHandle> scrollHandlers = [];

  @override
  Future initializer() async {
    document.addEventListener(
      "scroll",
      scrollHandler.toJS,
    );
  }

  final handlesToRemove = [];
  void scrollHandler(Event event) {
    for (var handler in scrollHandlers) {
      if (handler.run()) {
        handlesToRemove.add(handler);
      }
    }

    for (var handler in handlesToRemove) {
      scrollHandlers.remove(handler);
    }

    if (scrollHandlers.isEmpty) {
      document.removeEventListener("scroll", scrollHandler.toJS);
    }
  }

  // ! FUNCTIONS

  // _addScrollX(start: -100px end: 200px);
  // ? uses height as meter for 0 - 1;
  bool _addScrollX(HTMLElement element, HtmlFunction func) {
    final handle = ScrollHandleXAxis(
      element,
      start: double.parse(func.args[0]),
      end: double.parse(func.args[1]),
    );
    handle.run();
    scrollHandlers.add(handle);
    return true;
  }

  // addClassOnScroll(offset: 500, classList: is-rounded, [objective: true, reversable: true]);
  bool _addClassOnScroll(HTMLElement element, HtmlFunction func) {
    final handle = ScrollHandleClass(element, func);
    handle.run();
    scrollHandlers.add(handle);
    return true;
  }

  // ! END FUNCTIONS

  @override
  void registerFunctions() {
    df.functionMap['addClassOnScroll'] = _addClassOnScroll;
    df.functionMap['addScrollX'] = _addScrollX;
  }
}

abstract class ScrollHandle {
  final HTMLElement element;
  ScrollHandle(this.element);
  bool run(); // ? bool whether to remove the listener or not
  // https://developer.mozilla.org/en-US/docs/Web/API/Element/getBoundingClientRect/element-box-diagram.png
  num getDistanceElementBottomToScreenTop() {
    return element.getBoundingClientRect().bottom * -1;
  }

  num getElementTopScreenTop() {
    return element.getBoundingClientRect().top +
        document.documentElement!.scrollTop;
  }

  double inScreenT() {
    final rect = element.getBoundingClientRect();
    return (rect.top - window.innerHeight).abs() /
        (window.innerHeight + rect.height);
  }

  num getDistanceElementTopToScreenBottom() {
    final rect = element.getBoundingClientRect();
    return (rect.top - window.innerHeight).abs();
  }

  bool inView([padding = 0]) {
    final rect = element.getBoundingClientRect();
    return rect.top < (window.innerHeight + rect.height) + padding &&
        rect.top > -(rect.height + padding);
  }
}

class ScrollHandleXAxis extends ScrollHandle {
  final double start;
  final double end;
  ScrollHandleXAxis(
    super.element, {
    required this.start,
    required this.end,
  }) {
    element.style.position = "relative";
  }
  @override
  bool run() {
    if (inView(50)) {
      final t = inScreenT();
      element.style.left = "${lerpDouble(start, end, cubicInOut(t))}px";
    }

    return false;
  }
}

class ScrollHandleClass extends ScrollHandle {
  final HtmlFunction func;
  final int offset;
  final bool isObjective;
  final bool isReversible;
  final String classList;

  ScrollHandleClass(super.element, this.func)
      : offset = int.parse(func[0]!),
        classList = func[1]!,
        isObjective = (func[2] == "true"),
        isReversible = (func[3] == "true");

  @override
  bool run() {
    late num elementDistance;
    if (isObjective) {
      elementDistance = (document.querySelector("body") as HTMLBodyElement)
          .getBoundingClientRect()
          .top;
    } else {
      elementDistance =
          element.getBoundingClientRect().top - window.innerHeight;
    }
    final res = classListsFromString(classList);
    if (elementDistance + offset < 0) {
      if (res.addClasses.isNotEmpty) {
        element.classList.add(res.addClasses.join(","));
      }
      if (res.removeClasses.isNotEmpty) {
        element.classList.remove(res.removeClasses.join(','));
      }

      if (!isReversible) {
        return true;
      }
    }
    if (isReversible) {
      if (elementDistance + offset > 0) {
        if (res.removeClasses.isNotEmpty) {
          element.classList.add(res.removeClasses.join(","));
        }
        if (res.addClasses.isNotEmpty) {
          element.classList.remove(res.addClasses.join(','));
        }
      }
    }
    return false;
  }
}
