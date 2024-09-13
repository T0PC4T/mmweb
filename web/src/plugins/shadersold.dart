// import 'dart:js_interop';

// import 'package:http/http.dart' as http;
// import 'package:web/web.dart';

// import '../functions.dart';
// import 'scroll.dart';

// class ShaderPluginOld extends DartFunctionPlugin {
//   ShaderPluginOld(super.df);

//   // addShader()
//   bool _addShader(HTMLElement element, HtmlFunction func) {
//     final handle = ScrollHanderShader(element, func);
//     handle.run();
//     ScrollPlugin.scrollHandlers.add(handle);
//     return true;
//   }

//   @override
//   Future<void> initializer() async {}

//   @override
//   void registerFunctions() {
//     df.functionMap['addShader'] = _addShader;
//   }
// }

// Future<String> loadShaderFile(String url) async {
//   try {
//     final response = await http.get(Uri.parse("${window.location.href}$url"));
//     if (response.body case String result when result.isNotEmpty) {
//       print("[*] FOUND: ${response.body}");
//       return response.body;
//     }
//   } catch (e) {
//     print("[*] Unable to fetch data from file: $url $e");
//     throw "[*] Unable to fetch data from file: $url $e";
//   }
//   print("[*] Body data is invalid: $url ");
//   throw "[*] Body data is invalid: $url ";
// }

// class ScrollHanderShader implements ScrollHandle {
//   static Map<Element, ShaderHandler> shaderMap = {};
//   final HTMLElement element;
//   final HtmlFunction func;
//   final String fragUrl;
//   final String zIndex;
//   ScrollHanderShader(this.element, this.func)
//       : fragUrl = func.args[0],
//         zIndex = func.args[1];

//   _startShader() {
//     print("_startShader");
//     shaderMap[element] =
//         ShaderHandler(fragUrl: fragUrl, parent: element, zIndex: zIndex);
//   }

//   _removeShader() {
//     shaderMap[element]?.dispose();
//     shaderMap.remove(element);
//   }

//   @override
//   bool run() {
//     print("run");
//     final topDistance =
//         element.getBoundingClientRect().top - window.innerHeight;
//     final bottomDistance = element.getBoundingClientRect().bottom;
//     if (topDistance < 50 && bottomDistance > -50) {
//       if (shaderMap.containsKey(element)) {
//         if (shaderMap[element] case ShaderHandler sh when sh.running == false) {
//           sh.start();
//         }
//       } else {
//         _startShader();
//       }
//     } else {
//       if (shaderMap.containsKey(element)) {
//         if (shaderMap[element] case ShaderHandler sh when sh.running == true) {
//           sh.stop();
//         }
//         // _removeShader();
//       }
//     }

//     return false;
//   }
// }

// class ShaderHandler {
//   final String fragUrl;
//   final String zIndex;
//   final HTMLElement parent;
//   late HTMLCanvasElement canvas;
//   late WebGLBuffer positionBuffer;
//   late WebGLRenderingContext gl;
//   late WebGLShader vertexShader;
//   late WebGLShader fragmentShader;
//   WebGLProgram? shaderProgram;
//   bool alive = true;
//   bool running = false;

//   (double x, double y) mousePosition = (0.51, 0.51);
//   // Variable Locations
//   late int positionAttributeLocation;

//   WebGLUniformLocation? mousePositionLocation;
//   WebGLUniformLocation? uniformLocation;
//   WebGLUniformLocation? timeUniformLocation;

//   ShaderHandler({required this.fragUrl, required this.parent, String? zIndex})
//       : zIndex = zIndex ?? "1" {
//     init();
//   }

//   void _mouseMove(JSObject event) {
//     if (event case MouseEvent event) {
//       final rect = parent.getBoundingClientRect();

//       final x = (event.pageX - rect.left) / rect.width;
//       final y = (event.pageY - rect.top) / rect.height;
//       mousePosition = ((mousePosition.$1 + x) / 2, (mousePosition.$2 + y) / 2);
//     }
//   }

//   void init() async {
//     print("init");
//     parent.addEventListener(
//       "mousemove",
//       _mouseMove.toJS,
//     );

//     parent.style.position = "relative";
//     canvas = HTMLCanvasElement();
//     canvas.style
//       ..position = "absolute"
//       ..top = "0"
//       ..left = "0"
//       ..width = "100%"
//       ..height = "100%"
//       ..opacity = "0"
//       ..zIndex = zIndex;
//     parent.append(canvas);

//     const vsSource = """
//             attribute vec4 a_position;
//             // varying vec2 v_texCoord;
//             void main() {
//                 gl_Position = a_position;
//                 // v_texCoord = a_position.xy * 0.5 + 0.5;
//             }
//         """;
//     final fsSource = await loadShaderFile(fragUrl);

//     gl = canvas.getContext('webgl') as WebGLRenderingContext;
//     vertexShader = loadShader(WebGLRenderingContext.VERTEX_SHADER, vsSource);
//     fragmentShader =
//         loadShader(WebGLRenderingContext.FRAGMENT_SHADER, fsSource);
//     shaderProgram = gl.createProgram();
//     gl.attachShader(shaderProgram!, vertexShader);
//     gl.attachShader(shaderProgram!, fragmentShader);
//     gl.linkProgram(shaderProgram!);

//     if (gl.getProgramParameter(
//             shaderProgram!, WebGLRenderingContext.LINK_STATUS) ==
//         false.toJS) {
//       throw 'Unable to initialize the shader program: ${gl.getProgramInfoLog(shaderProgram!)}';
//     }

//     positionAttributeLocation =
//         gl.getAttribLocation(shaderProgram!, 'a_position');
//     uniformLocation = gl.getUniformLocation(shaderProgram!, 'iResolution');
//     mousePositionLocation = gl.getUniformLocation(shaderProgram!, 'iMouse');
//     timeUniformLocation = gl.getUniformLocation(shaderProgram!, 'iTime');

//     // Create buffer and set up attributes
//     positionBuffer = createPositionBuffer();

//     // RENDER OVER TIME

//     window.addEventListener('resize', _resizeCanvas.toJS);
//     _resizeCanvas(null);

//     // This was in render
//     // ! Removed this because we don't really need to clear the buffer in this case
//     // ? gl.clearColor(0, 0, 0, 0);
//     // ? gl.clear(webgl.WebGL.COLOR_BUFFER_BIT);

//     gl.useProgram(shaderProgram);
//     gl.enableVertexAttribArray(positionAttributeLocation);
//     gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, positionBuffer);
//     gl.vertexAttribPointer(
//         positionAttributeLocation, 2, WebGLRenderingContext.FLOAT, false, 0, 0);

//     // end this was in render

//     start();
//     canvas.style.opacity = "1";
//   }

//   WebGLShader loadShader(int type, String source) {
//     print("loadShader");
//     if (gl.createShader(type) case WebGLShader shader) {
//       gl.shaderSource(shader, source);
//       gl.compileShader(shader);

//       if (gl.getShaderParameter(shader, WebGLRenderingContext.COMPILE_STATUS) ==
//           false) {
//         gl.deleteShader(shader);
//         throw 'An error occurred compiling the shaders: ${gl.getShaderInfoLog(shader)}';
//       }

//       return shader;
//     }
//     throw "Unable to create shader";
//   }

//   WebGLBuffer createPositionBuffer() {
//     if (gl.createBuffer() case WebGLBuffer buffer) {
//       gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, buffer);

//       // List<double> positions = [-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1];

//       gl.bufferData(
//         WebGLRenderingContext.ARRAY_BUFFER,
//         [-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]
//             .map<JSNumber>(
//               (e) => e.toJS,
//             )
//             .toList()
//             .toJS,
//         WebGLRenderingContext.STATIC_DRAW,
//       );

//       return buffer;
//     }
//     throw "Unable to create shader";
//   }

//   void render(num time) {
//     print("render");
//     if (!alive) {
//       return;
//     }
//     time *= 0.001; // Convert to seconds
//     gl.uniform1f(timeUniformLocation, time);
//     gl.uniform2f(uniformLocation, canvas.width, canvas.height);
//     gl.uniform2f(mousePositionLocation, mousePosition.$1, mousePosition.$2);
//     gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, 6);

//     if (running) {
//       window.requestAnimationFrame(render.toJS);
//     }
//   }

//   void start() {
//     running = true;
//     window.requestAnimationFrame(render.toJS);
//   }

//   void stop() {
//     running = false;
//   }

//   void _resizeCanvas(JSObject? e) {
//     canvas.width = window.innerWidth;
//     canvas.height = window.innerHeight;
//     console.log(window.innerWidth.toJS);
//     console.log(window.innerHeight.toJS);
//     gl.viewport(0, 0, canvas.width, canvas.height);
//   }

//   void dispose() {
//     if (alive == false) {
//       return;
//     }
//     alive = false;

//     window.removeEventListener('resize', _resizeCanvas.toJS);
//     parent.removeEventListener("mousemove", _mouseMove.toJS);

//     // Delete shader program
//     gl.deleteProgram(shaderProgram);
//     shaderProgram = null;

//     // Delete buffers
//     gl.deleteBuffer(positionBuffer);

//     // Lose the WebGL context
//     var loseContextExtension = gl.getExtension('WEBGL_lose_context');
//     if (loseContextExtension != null) {
//       print(loseContextExtension);
//       // loseContextExtension.loseContext();
//     }
//     canvas.remove();
//   }
// }
