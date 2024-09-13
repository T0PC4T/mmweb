import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

import '../functions.dart';
import 'contentful/client.dart';

const int defaultPerPage = 5;

// Requires javascript import
class ContentfulPlugin extends DartFunctionPlugin {
  ContentfulPlugin(super.df);
  late ContentfulClient client;

  static const details = {
    "space": "8e6y7fam3t8b",
    "accessToken": "M7ENT0XU8qylO7sYlkViODq1M63D2otWTesoGENO-7U",
    "environment": "master",
  };

  @override
  Future initializer() async {
    client = contentful.createClient(details.toJS);
  }

  // ! FUNCTIONS
  // getAsset(1HT6BVMkKol8zyWMyOwVlE, fill)
  // <figure class="image" data-function="getAsset(6pNUkznq5tmKzWs9pJRWRJ)"> *it will insert an img tag in side.
  bool _getAsset(Element element, HtmlFunction func) {
    client.getAsset(func.args[0]).toDart.then(
      (value) {
        final fields = value.getProperty<JSObject>("fields".toJS);
        final title = fields.getProperty<JSString>("title".toJS);
        final url = value
            .getProperty("fields".toJS)
            .obj
            ?.getProperty("file".toJS)
            .obj
            ?.getProperty<JSString>("url".toJS);

        print(url);
        // element.innerHTML =
        //     '<div style="width:100%;height:100%;background:url("$url");background-size:${func.args[1]};"/></div>'
        //         .toJS;
        element.innerHTML =
            """<img src="$url" alt="$title" style="width:100%;height:100%;object-fit: ${func.args[1]};"/>""";
      },
    );

    return true;
  }

  // get(pages, id:1HT6BVMkKol8zyWMyOwVlE)
  // get(pages, myurlparam)
  bool _get(Element element, HtmlFunction func) {
    String? postId;
    if (func.args[1].startsWith("id:")) {
      postId = func.args[1].substring(3);
    } else {
      final urlParams = URLSearchParams(jsWindow.location.search.toJS);
      postId = urlParams.get(func.args[1]);
    }
    print("Getting POST ID $postId");
    final options = {
      "content_type": func.args[0],
    };
    client.getEntry(postId!.toJS, options.toJS).toDart.then(
      (value) {
        final datum = {};
        final fields = (value.getProperty("fields".toJS) as JSObject);
        for (var key in SObject.keys(fields).toDart) {
          final value = fields.getProperty(key);
          datum[key.toDart] = convertContentfulValue(value);
        }
        if (element.classList.contains("dart-function-blinder")) {
          element.classList.remove("dart-function-blinder");
        }
        mergeElement(element, datum);
      },
    );

    return true;
  }

  bool _fetch(Element element, HtmlFunction func) {
    final urlParams = URLSearchParams(jsWindow.location.search.toJS);
    final page = urlParams.get('page');
    print("PAGE: ${page.runtimeType}, $page");
    final options = {
      "limit": func.args.length > 3 ? int.parse(func.args[3]) : defaultPerPage,
      "content_type": func.args[1],
      "order": func.args.length > 2 ? func.args[2] : "-sys.createdAt"
    };
    if (page != null) {
      options["skip"] = ((int.tryParse(page) ?? 1) - 1) * defaultPerPage;
    }
    client.getEntries(options.toJS).toDart.then(
      (value) {
        console.log(value);
        jsWindow.setProperty(func.args[0].toJS, value);
        df.runFunctions();
      },
    );

    return true;
  }

  bool _fetchFor(Element element, HtmlFunction func) {
    if (!requireField(element, func.args[0])) {
      return false;
    }
    var fetchData = jsWindow.getProperty<JSObject?>(func.args[0].toJS);
    var items = fetchData?.getProperty("items".toJS);
    if (items.isA<JSArray<JSObject>>()) {
      var dartItems = (items as JSArray<JSObject>).toDart;
      final dataList = List.generate(dartItems.length, (index) {
        final item = dartItems[index];
        final itemId = (item.getProperty("sys".toJS) as JSObject)
            .getProperty('id'.toJS) as JSString;
        final fields = item.getProperty("fields".toJS) as JSObject;
        Map<String, dynamic> datum = {"id": itemId};
        for (var key in SObject.keys(fields).toDart) {
          final value = fields.getProperty(key);
          datum[key.toDart] = convertContentfulValue(value);
        }
        return datum;
      }, growable: false);

      mergeFunction(element, dataList);
    }
    return true;
  }

  bool _fetchPagination(Element element, HtmlFunction func) {
    if (!requireField(element, func.args[0])) {
      return false;
    }
    var fetchData = jsWindow.getProperty<JSObject?>(func.args[0].toJS)?.toMap;
    late num payload;
    if (fetchData
        case {
          "total": num total,
          "skip": num skip,
          "limit": num limit,
        }) {
      final page = (skip ~/ limit) + 1;
      if (func.name == 'fetchPaginationPrev') {
        if (skip == 0) {
          element.remove();
        }
        payload = page - 1;
      } else if (func.name == 'fetchPaginationCurrent') {
        payload = page;
      } else if (func.name == 'fetchPaginationNext') {
        if (skip + limit >= total) {
          element.remove();
        }
        payload = page + 1;
      }
      mergeElement(element, {"payload": payload});
    }
    return true;
  }

  // ! END FUNCTIONS

  @override
  void registerFunctions() {
    df.functionMap['fetch'] = _fetch;
    df.functionMap['fetchFor'] = _fetchFor;
    df.functionMap['get'] = _get;
    df.functionMap['getAsset'] = _getAsset;
    df.functionMap['fetchPaginationNext'] = _fetchPagination;
    df.functionMap['fetchPaginationPrev'] = _fetchPagination;
    df.functionMap['fetchPaginationCurrent'] = _fetchPagination;
  }
}

List months = [
  "-",
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

String? parseDateTimeString(String input) {
  final RegExp dateRegex = RegExp(
      r'^(\d{4})-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])T(?:[01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?(?:[+-][01]\d:[0-5]\d|Z)$');

  if (dateRegex.hasMatch(input)) {
    try {
      final dt = DateTime.parse(input);
      return "${months[dt.month]} ${dt.day}, ${dt.year}";
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  return null;
}

String convertContentfulValue(JSAny? value) {
  if (value is JSString) {
    return parseDateTimeString(value.toDart) ?? value.toDart;
  } else if (value is JSObject &&
      value.getProperty("nodeType".toJS) == "document".toJS) {
    return documentToHtmlString(value, contentfulOptions);
  } else if (value is JSObject && value.hasProperty("fields".toJS).toDart) {
    final url = value
        .getProperty("fields".toJS)
        .obj
        ?.getProperty("file".toJS)
        .obj
        ?.getProperty("url".toJS);
    if (url.isA<JSString>()) {
      return (url as JSString).toDart;
    } else {
      return "/images/placeholder.jpg";
    }
  }
  if (value is JSObject) {
    console.log(["[ContentfulPlugin] Unable to process: ".toJS, value].toJS);
    return "";
  }
  return value.toString();
}

// TODO do this the write way data-payload:'InnerHTML' data-attribute-payload: 'src,alt';
String mergeString(String inputString, Map data) {
  for (var entry in data.entries) {
    inputString =
        inputString.replaceAll("*|${entry.key}|*", entry.value.toString());
  }
  return inputString;
}

void mergeElement(Element base, dynamic datum) {
  base.innerHTML = mergeString(base.innerHTML.toString(), datum);
}

mergeFunction(Element baseElement, Iterable<dynamic> dataSet) async {
  final parent = baseElement.parentElement;
  final base = baseElement.outerHTML.toString();
  baseElement.remove();
  for (final datum in dataSet) {
    final String newElementHTML = mergeString(base, datum);
    parent?.innerHTML = "${parent.innerHTML} $newElementHTML";
  }
}

bool requireField(Element element, String fieldName) {
  if (jsWindow.hasProperty(fieldName.toJS).toDart) {
    element.classList.remove('dart-function-blinder');
    return true;
  }
  return false;
}
