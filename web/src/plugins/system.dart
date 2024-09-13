import 'dart:html';

class SystemVariables {
  static SystemVariables? inst;

  SystemVariables._();

  factory SystemVariables() {
    if (SystemVariables.inst == null) {
      inst = SystemVariables._();
    }
    return inst!;
  }

  operator [](String key) {
    switch (key) {
      case "id":
        {
          UrlSearchParams params = UrlSearchParams(window.location.search);
          return params.get("id");
        }
      default:
        return "";
    }
  }
}
