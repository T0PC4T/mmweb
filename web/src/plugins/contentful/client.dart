import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../../functions.dart';

extension type Entries._(JSObject _) implements JSObject {
  external JSArray<JSObject> get items;
}

extension type ContentfulClient._(JSObject _) implements JSObject {
  external JSObject createClient(JSObject config);
  external JSPromise<Entries> getEntries([JSObject? query]);
  external JSPromise<JSObject> getAsset(String assetID);
  external JSPromise<JSObject> getEntry(JSString id, [JSObject? query]);
}

extension type ContentfulObj._(JSObject _) implements JSObject {
  external ContentfulClient createClient(JSObject config);
}

@JS()
external String documentToHtmlString(JSObject nodeTree, JSObject options);

@JS()
external ContentfulObj get contentful;

@JS('BLOCKS')
extension type Blocks._(JSObject _) implements JSObject {
  external static JSString get EMBEDDED_ASSET;
  external static JSString get EMBEDDED_ENTRY;
  external static JSString get PARAGRAPH;
  external static JSString get HEADING_1;
  external static JSString get HEADING_2;
  external static JSString get HEADING_3;
  external static JSString get HEADING_4;
}

@JS('INLINES')
extension type INLINES._(JSObject _) implements JSObject {
  external static JSString get ASSET_HYPERLINK;
  external static JSString get EMBEDDED_ENTRY;
  external static JSString get EMBEDDED_RESOURCE;
  external static JSString get ENTRY_HYPERLINK;
  external static JSString get HYPERLINK;
  external static JSString get RESOURCE_HYPERLINK;
}

JSObject get contentfulOptions => <dynamic, dynamic>{
      "renderNode": <dynamic, dynamic>{
        INLINES.ASSET_HYPERLINK: (JSObject node, JSAny next) {
          final title = documentToHtmlString(node, {}.toJS);
          final fields = node
              .getProperty<JSObject>("data".toJS)
              .getProperty<JSObject>("target".toJS)
              .getProperty<JSObject>("fields".toJS);
          // final title = fields.getProperty("title".toJS);
          final url = fields
              .getProperty<JSObject>("file".toJS)
              .getProperty<JSString>("url".toJS);
          return '<a href="$url">$title</a>'.toJS;
        }.toJS,
        Blocks.EMBEDDED_ENTRY: (JSObject node, JSAny next) {
          final fields = node
              .getProperty<JSObject>("data".toJS)
              .getProperty<JSObject>("target".toJS)
              .getProperty<JSObject>("fields".toJS);

          if (fields.hasProperty("html".toJS).toDart) {
            return fields.getProperty<JSString>("html".toJS);
          }
        }.toJS,
        Blocks.EMBEDDED_ASSET: (JSObject node, JSAny next) {
          final url = node
              .getProperty<JSObject>("data".toJS)
              .getProperty<JSObject>("target".toJS)
              .getProperty<JSObject>("fields".toJS)
              .getProperty<JSObject>("file".toJS)
              .getProperty<JSString>("url".toJS);
          //   return """<div class="columns is-fullwidth">
          //   <div
          //     class="column is-8-mobile is-6-desktop is-offset-2-mobile is-offset-3-desktop"
          //   >
          //     <figure class="image is-fullwidth">
          //       <img
          //         class="m-2"
          //         src=$url
          //         alt=""
          //         srcset=""
          //       />
          //     </figure>
          //   </div>
          // </div>
          // """
          return """
          <div class="m-1 is-flex is-flex-direction-column is-align-items-center is-justify-content-center">
            <figure class="image is-flex is-flex-direction-column is-align-items-center is-justify-content-center">
              <img
                class="m-2"
                src=$url
                alt=""
                srcset=""
                style="width:auto; height:auto; max-width: 90%; max-height: 600px;"
              />
            </figure>
          </div>
        """
              .toJS;
        }.toJS
      }.toJS
    }.toJS;
