import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:jinja/loaders.dart';
import 'package:path/path.dart' as p;
import 'package:sass/sass.dart' as sass;
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';

var environment = Environment(
  loader: FileSystemLoader(
    paths: const <String>[
      './dev/templates/',
      './dev/pages/',
      './dev/components/'
    ],
  ),
  leftStripBlocks: true,
  trimBlocks: true,
);
void main(List<String> args) async {
  List<String> foldersToWatch = [
    './dev/templates/',
    './dev/pages/',
    './dev/components/',
    './dev/styles/',
  ];

  for (String folder in foldersToWatch) {
    Directory(folder).watch(recursive: true).listen((event) {
      print(
          '[*] File ${event.path} has been ${event.type == FileSystemEvent.modify ? 'modified' : 'changed'}');
      if (event.type == FileSystemEvent.modify) {
        if (event.path.contains("dev/pages")) {
          changedPage(event.path);
        } else if (event.path.contains("dev/templates") ||
            event.path.contains("dev/components")) {
          changedPagesBuilders(event.path);
        } else if (event.path.contains("dev/styles")) {
          changedStyles(event.path);
        }
      }
    });
  }

  print('[*] Watching folders. Press Ctrl+C to stop.');
}

void changedPage(String path) async {
  print("[*] Updating Page $path!");

  try {
    final filename = p.basename(path);
    final template = environment.getTemplate(filename);
    final String buffer;
    buffer = template.render({'title': "my title", "content": "my content"});
    final nameWithoutExt = p.basenameWithoutExtension(filename);
    if (nameWithoutExt != "index") {
      Directory("./web/$nameWithoutExt").create();
      await writeStringToFile(buffer, "./web/$nameWithoutExt/index.html");
    } else {
      await writeStringToFile(buffer, "./web/index.html");
    }
  } catch (e) {
    print("[!] Unable to compile Template");
    print("[!] ${e.toString()}");
    return;
  }
}

void changedPagesBuilders(String path) async {
  print("[*] Updating All Pages!");
  final directory = Directory("./dev/pages/");
  List<File> htmlFiles = [];

  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.html')) {
      htmlFiles.add(entity);
    }
  }

  for (var f in htmlFiles) {
    changedPage(f.path);
  }
}

void changedStyles(String path) async {
  print("[*] Updating Styles!");
  try {
    final result =
        sass.compileToResult("dev/styles/styles.scss", logger: MyLogger());
    await writeStringToFile(result.css, "web/styles/styles.css");
  } catch (e) {
    print("[!] Unable to compile Styles");
    print("[!] ${e.toString()}");
    return;
  }
}

Future<String> getFileAsString(String filePath) async {
  try {
    final file = File(filePath);
    String contents = await file.readAsString();
    return contents;
  } catch (e) {
    print("[!] Error reading file: $e");
    return "";
  }
}

Future<void> writeStringToFile(String content, String filePath) async {
  try {
    final file = File(filePath);
    await file.writeAsString(content);
    print('[*] "$filePath" written successfully');
  } catch (e) {
    print('[!] Error writing to file: $e');
  }
}

class MyLogger implements sass.Logger {
  @override
  void debug(String message, SourceSpan span) {}

  @override
  void warn(String message,
      {FileSpan? span, Trace? trace, bool deprecation = false}) {}
}
