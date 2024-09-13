precision mediump float;
precision lowp int;

uniform float iTime;
uniform vec2 iMouse;
uniform vec2 iResolution;


vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

vec3 blue = vec3(120, 210, 240) / 255.;
vec3 pink = vec3(210, 240, 120) / 255.;

void main() {
    vec2 uv = gl_FragCoord.xy/iResolution.xy;
    vec2 ouv = uv;
    uv.x *= iResolution.x/iResolution.y;
    ouv.y = 1. - ouv.y;
    // float diff = abs(iResolution.x - iResolution.y) / iResolution.x;
    // uv.x = (uv.x - diff *.5) * (iResolution.x / iResolution.y);

    float centerX = 0.5 * iResolution.x/iResolution.y;
    vec2 vIMouse = iMouse.xy;
    
    float r = dot(normalize(ouv-0.5), normalize(vIMouse-0.5));
    r += 1.;
    r = pow(r,2.0);
    
    float noise = snoise(uv*3. + iTime * 0.1);
    vec3 wc = mix(pink, blue, ouv.x + vIMouse.x - .5); 
    vec3 wColor = mix(wc *.9, wc, noise * 0.5 + 0.5);
    
    float wave = sin(iTime*0.5);
    float f = distance(vec2(centerX, 0.5), uv) * 1.4 + noise * 0.1;
    f = f - r*0.05 + wave*0.02;
    f = clamp(0.,1.,f);
    
    vec4 col = vec4(1.,0.,0.,1.);
      
    gl_FragColor = col;
    
}