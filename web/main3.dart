//   DartFunction().runFunctions();
import 'dart:js_interop';

import 'package:web/web.dart';

void main() {
  final gl = initWebGL();
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);
  final vsSource = """
    attribute vec4 aVertexPosition;

    void main(void) {
        gl_Position = aVertexPosition;
    }""";

  final fsSource = """
    void main(void) {

        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);  // Red color
    }
""";

  final vertexShader =
      loadShader(gl, WebGLRenderingContext.VERTEX_SHADER, vsSource);
  final fragmentShader =
      loadShader(gl, WebGLRenderingContext.FRAGMENT_SHADER, fsSource);
  final shaderProgram = initShaderProgram(gl, vertexShader, fragmentShader);
  final vertexBuffer = initBuffers(gl);
  drawScene(gl, shaderProgram, vertexBuffer);
}

@JS('eval')
external JSAny runJS(String input);

initBuffers(WebGLRenderingContext gl) {
  final vertices =
      runJS("""new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1])""")
          as JSFloat32Array;
  final vertexBuffer = gl.createBuffer();
  gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexBuffer);
  gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, vertices,
      WebGLRenderingContext.STATIC_DRAW);
}

drawScene(WebGLRenderingContext gl, shaderProgram, vertexBuffer) {
  gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);

  final vertexPosition = gl.getAttribLocation(shaderProgram, 'aVertexPosition');
  // gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexBuffer);
  gl.vertexAttribPointer(
      vertexPosition, 2, WebGLRenderingContext.FLOAT, false, 0, 0);
  gl.enableVertexAttribArray(vertexPosition);

  gl.useProgram(shaderProgram);

  gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, 6);
}

WebGLShader? loadShader(WebGLRenderingContext gl, type, source) {
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

WebGLProgram? initShaderProgram(WebGLRenderingContext gl, vs, fs) {
  final shaderProgram = gl.createProgram()!;
  gl.attachShader(shaderProgram, vs);
  gl.attachShader(shaderProgram, fs);
  gl.linkProgram(shaderProgram);

  if (gl.getProgramParameter(
          shaderProgram, WebGLRenderingContext.LINK_STATUS) !=
      true.toJS) {
    // console.error('Unable to initialize the shader program:', gl.getProgramInfoLog(shaderProgram));
    return null;
  }

  return shaderProgram;
}

WebGLRenderingContext initWebGL() {
  final canvas = document.getElementById('glCanvas') as HTMLCanvasElement?;
  final gl = (canvas?.getContext('webgl') ??
      canvas?.getContext('experimental-webgl')) as WebGLRenderingContext?;

  if (gl == null) {
    throw 'Unable to initialize WebGL. Your browser may not support it.'.toJS;
  }

  return gl;
}
