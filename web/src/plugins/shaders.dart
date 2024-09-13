import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart';

import '../functions.dart';
import 'scroll.dart';

class ShaderPlugin extends DartFunctionPlugin {
  ShaderPlugin(super.df);

  // addShader()
  bool _addShaderOnScroll(HTMLElement element, HtmlFunction func) {
    final handle = ScrollHanderShader(element, func);
    handle.run();
    ScrollPlugin.scrollHandlers.add(handle);
    return true;
  }

  bool _addShader(HTMLElement element, HtmlFunction func) {
    final shaderController = ShaderController(
      parent: element,
      fragUrl: func.args[0],
      zIndex: func.args[1],
    );
    shaderController.start();

    return true;
  }

  @override
  Future<void> initializer() async {}

  @override
  void registerFunctions() {
    df.functionMap['addShader'] = _addShader;
    df.functionMap['addShaderOnScroll'] = _addShaderOnScroll;
  }
}

Future<String> loadShaderFile(String url) async {
  try {
    final response = await http.get(Uri.parse("${window.location.href}$url"));
    if (response.body case String result when result.isNotEmpty) {
      return response.body;
    }
  } catch (e) {
    print("[*] Unable to fetch data from file: $url $e");
    throw "[*] Unable to fetch data from file: $url $e";
  }
  print("[*] Body data is invalid: $url ");
  throw "[*] Body data is invalid: $url ";
}

class ScrollHanderShader extends ScrollHandle {
  static Map<Element, ShaderController> shaderMap = {};
  final HtmlFunction func;
  final String fragUrl;
  final String zIndex;
  ScrollHanderShader(super.element, this.func)
      : fragUrl = func.args[0],
        zIndex = func.args[1];

  ShaderController getShaderController() {
    return ShaderController(fragUrl: fragUrl, parent: element, zIndex: zIndex);
  }

  _removeShader() {
    shaderMap[element]?.dispose();
    shaderMap.remove(element);
  }

  @override
  bool run() {
    print(inView());
    if (inView()) {
      final ShaderController sh =
          shaderMap.putIfAbsent(element, getShaderController);
      sh.start();
    } else {
      if (shaderMap.containsKey(element)) {
        if (shaderMap[element] case ShaderController sh
            when sh.running == true) {
          sh.stop();
        }
        // _removeShader();
      }
    }

    return false;
  }
}

class ShaderController {
  final String fragUrl;
  final String zIndex;
  bool running = false;
  bool alive = true;
  final HTMLElement parent;
  late HTMLCanvasElement canvas;
  late WebGLRenderingContext gl;
  WebGLProgram? shaderProgram;
  WebGLBuffer? vertexBuffer;
  (double x, double y) mousePosition = (0.51, 0.51);
  WebGLUniformLocation? mousePositionLocation;
  WebGLUniformLocation? uniformLocation;
  WebGLUniformLocation? timeUniformLocation;
  ShaderController(
      {required this.fragUrl, required this.parent, String? zIndex})
      : zIndex = zIndex ?? "1" {
    _init();
  }

  void _mouseMove(JSObject event) {
    if (event case MouseEvent event) {
      final rect = parent.getBoundingClientRect();

      final x = (event.pageX - rect.left) / rect.width;
      final y = (event.pageY - rect.top) / rect.height;
      mousePosition = ((mousePosition.$1 + x) / 2, (mousePosition.$2 + y) / 2);
    }
  }

  void _render(num time) {
    if (!alive) {
      return;
    }
    time *= 0.001; // Convert to seconds
    gl.uniform1f(timeUniformLocation, time);
    gl.uniform2f(uniformLocation, canvas.width, canvas.height);
    gl.uniform2f(mousePositionLocation, mousePosition.$1, mousePosition.$2);
    gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, 6);

    if (running) {
      window.requestAnimationFrame(_render.toJS);
    }
  }

  void start() {
    if (!running) {
      running = true;
      window.requestAnimationFrame(_render.toJS);
    }
  }

  void stop() {
    if (running) {
      running = false;
    }
  }

  void _resizeCanvas(JSObject? e) {
    canvas.width = parent.getBoundingClientRect().width.toInt();
    canvas.height = parent.getBoundingClientRect().width.toInt();
    gl.viewport(0, 0, canvas.width, canvas.height);
  }

  void _init() async {
    // sets canvas and gl
    _createCanvasAndGL();
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);
    final vsSource = """
    attribute vec4 aVertexPosition;
    void main(void) {
        gl_Position = aVertexPosition;
    }""";
    final fsSource = await loadShaderFile(fragUrl);
    final vertexShader =
        _loadShader(gl, WebGLRenderingContext.VERTEX_SHADER, vsSource);
    final fragmentShader =
        _loadShader(gl, WebGLRenderingContext.FRAGMENT_SHADER, fsSource);
    final shaderProgram = _initShaderProgram(gl, vertexShader, fragmentShader);
    _initVertexBuffers(gl);
    gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);
    // set up
    uniformLocation = gl.getUniformLocation(shaderProgram!, 'iResolution');
    // TODO check to see if shaderProgram contains word iMouse and only create listener accordingly.
    mousePositionLocation = gl.getUniformLocation(shaderProgram, 'iMouse');
    timeUniformLocation = gl.getUniformLocation(shaderProgram, 'iTime');

    final vertexPosition =
        gl.getAttribLocation(shaderProgram, 'aVertexPosition');
    gl.vertexAttribPointer(
        vertexPosition, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexPosition);

    gl.useProgram(shaderProgram);

    parent.addEventListener("mousemove", _mouseMove.toJS);
    window.addEventListener('resize', _resizeCanvas.toJS);
    _resizeCanvas(null);
    // shows canvas
    canvas.style.opacity = "1";
    start();
  }

  WebGLBuffer? _initVertexBuffers(WebGLRenderingContext gl) {
    final vertices = runJS(
            """new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1])""")
        as JSFloat32Array;
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, vertices,
        WebGLRenderingContext.STATIC_DRAW);

    return vertexBuffer;
  }

  WebGLShader? _loadShader(WebGLRenderingContext gl, type, source) {
    final shader = gl.createShader(type)!;

    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (gl.getShaderParameter(shader, WebGLRenderingContext.COMPILE_STATUS) !=
        true.toJS) {
      // console.error('An error occurred compiling the shaders:', gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }

    return shader;
  }

  WebGLProgram? _initShaderProgram(WebGLRenderingContext gl, vs, fs) {
    shaderProgram = gl.createProgram()!;
    gl.attachShader(shaderProgram!, vs);
    gl.attachShader(shaderProgram!, fs);
    gl.linkProgram(shaderProgram!);

    if (gl.getProgramParameter(
            shaderProgram!, WebGLRenderingContext.LINK_STATUS) !=
        true.toJS) {
      // console.error('Unable to initialize the shader program:', gl.getProgramInfoLog(shaderProgram));
      return null;
    }

    return shaderProgram;
  }

  WebGLRenderingContext _createCanvasAndGL() {
    canvas = HTMLCanvasElement();
    canvas.style
      ..width = "100%"
      ..height = "100%"
      ..zIndex = zIndex
      ..opacity = "0";
    parent.append(canvas);

    gl = (canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl'))
        as WebGLRenderingContext;

    return gl;
  }

  void dispose() {
    if (alive == false) {
      return;
    }
    alive = false;

    window.removeEventListener('resize', _resizeCanvas.toJS);
    parent.removeEventListener("mousemove", _mouseMove.toJS);

    // Delete shader program
    gl.deleteProgram(shaderProgram);
    shaderProgram = null;

    // Delete buffers
    gl.deleteBuffer(vertexBuffer);

    // Lose the WebGL context
    var loseContextExtension = gl.getExtension('WEBGL_lose_context');
    if (loseContextExtension != null) {
      print(loseContextExtension);
      // loseContextExtension.loseContext();
    }
    canvas.remove();
  }
}

@JS('eval')
external JSAny runJS(String input);
