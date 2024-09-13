import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

import '../functions.dart';
import './contentful.dart';

@JS("L")
external LeafletClient get leafletClient;

extension type LeafletClient._(JSObject _) implements JSObject {
  external LeafletMap map(String tagId);
  external JSObject tileLayer(String url, JSAny options);
  external LeafletMarker marker(JSArray<JSNumber> longlat);
}

extension type LeafletMarker._(JSObject _) implements JSObject {
  external LeafletMarker addTo(LeafletMap map);
  external JSObject bindPopup(String content, JSObject options);
}

extension type LeafletMap._(JSObject _) implements JSObject {
  external LeafletMap setView(JSArray<JSNumber> longlat, int zoom);
  external LeafletMap openPopup(JSObject marker);
  void addOpenStreet() {
    leafletClient
        .tileLayer(
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            {
              "maxZoom": 19,
              "attribution":
                  '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>',
            }.toJS)
        .callMethod("addTo".toJS, this);
  }
}

class LeafletMapPlugin extends DartFunctionPlugin {
  LeafletMapPlugin(super.df);
  LeafletMap? map;
  @override
  Future initializer() async {}

  // ! FUNCTIONS
  loadStuff() {
    if (map == null) {
      map = leafletClient.map("map").setView([(50).toJS, (-10).toJS].toJS, 2);
      map?.addOpenStreet();
    }
  }

  // mapFromContentful(dataSource: chapterData);
  bool _mapFromContentful(Element element, HtmlFunction func) {
    loadStuff();
    if (!requireField(element, func.args[0])) {
      return false;
    }

    var fetchData = jsWindow.getProperty<JSObject?>(func.args[0].toJS);
    var items = fetchData?.getProperty("items".toJS);
    if (items.isA<JSArray<JSObject>>()) {
      var dartItems = (items as JSArray<JSObject>).toDart;
      for (var item in dartItems) {
        final itemId = (item.getProperty("sys".toJS) as JSObject)
            .getProperty('id'.toJS) as JSString;
        JSObject fields = item.getProperty("fields".toJS);
        JSObject ll = fields.getProperty("location".toJS);
        JSNumber lon = ll.getProperty("lon".toJS);
        JSNumber lat = ll.getProperty("lat".toJS);
        var marker = leafletClient.marker([lat, lon].toJS).addTo(map!);
        marker.bindPopup(
            convertContentfulValue(fields.getProperty("content".toJS)),
            {"minWidth": 200}.toJS);

        Future.delayed(Duration(milliseconds: 250)).then(
          (value) {
            final button = document.getElementById("mapButton-$itemId");
            button?.addEventListener(
                "click",
                (JSAny? event) {
                  document.body?.scrollTop =
                      document.documentElement!.scrollTop = 100;
                  map?.setView([lat, lon].toJS, 12);
                }.toJS);
          },
        );
      }
    }
    return true;
  }

  // ! END FUNCTIONS

  @override
  void registerFunctions() {
    df.functionMap['mapFromContentful'] = _mapFromContentful;
  }
}
