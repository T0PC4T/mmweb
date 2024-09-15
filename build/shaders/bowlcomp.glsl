precision mediump float;
precision lowp int;

uniform float iTime;
uniform vec2 iMouse;
uniform vec2 iResolution;

    
vec2 hash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)),
			 dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
	const float K1 = 0.366025404; // (sqrt(3)-1)/2;
	const float K2 = 0.211324865; // (3-sqrt(3))/6;
	
	vec2 i = floor( p + (p.x+p.y)*K1 );
	
	vec2 a = p - i + (i.x+i.y)*K2;
	vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;
	
	vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	
	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
	
	return dot( n, vec3(70.0) );
}

#define numOctaves 3

float fbm( in vec2 x, in float H )
{    
    float t = 0.0;
    
    for( int i=0; i<numOctaves; i++ )
    {
        float f = pow( 2.0, float(i) );
        float a = pow( f, -H );
        t += a*noise(f*x);
    }
    return t;
}

float fbmalt( in vec2 x, in float H )
{    
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<numOctaves; i++ )
    {
        t += a*noise(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;
}

mat4 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0
  );
}

vec3 rotate(vec3 p, vec3 axis, float angle) {
    mat4 t = rotation3d(axis,angle);
    return (vec4(p,1.) * t).xyz;
    
}

float sdCutHollowSphere( vec3 p, float r, float h, float t )
{
    vec2 q = vec2( length(p.xz), p.y );
    
    float w = sqrt(r*r-h*h);
    
    return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                            abs(length(q)-r) ) - t;
}

float map( in vec3 pos )
{
    // size
    float r = 0.61;
    // height -.5 => .5;
    float h = -0.05;
    // thickness
    float t = 0.01;
    return sdCutHollowSphere(pos, r, h, t );
}


// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
					  e.yyx*map( pos + e.yyx*eps ) + 
					  e.yxy*map( pos + e.yxy*eps ) + 
					  e.xxx*map( pos + e.xxx*eps ) );
}


void main() {
    const vec3 clay = vec3(214, 135, 90) / 255.;
    const vec3 grey = vec3(27, 29, 28) / 255.;
    // vec2 uv = gl_FragCoord.xy/iResolution.xy;
    // set the camera a little back and up
	vec3 ro = vec3( 0.0, 0.6, -1.0);
    
    vec2 p = (2.0*gl_FragCoord.xy-iResolution.xy)/iResolution.y;

    // create view ray
    vec3 rd = normalize(vec3(p.x, p.y - 1.2, 1.));

    // raymarch
    const float tmax = 2.;
    float t = 0.0;
    
    // number of steps
    vec3 pos;
    float noiseadd = 0.0;
    for( int i=0; i<18; i++ )
    {
        // The start position
        pos = ro + t*rd;
        pos = rotate(pos, vec3(0.02,0.2,0.0), iTime);
        float d = map(pos);
        noiseadd = noise((pos.xy - iTime * 0.2) * 3.5) * 0.005;
        d += noiseadd;
        if( d<0.001 || t>tmax ) break;
        t += d;
    }
    

    // shading/lighting	
    vec4 col = vec4(0.0);
    if( t<tmax )
    {
        vec3 nor = calcNormal(pos);
        vec3 lig = normalize(vec3(0., 3., 1.));
        float dif = pow(clamp(dot(nor,lig), 0.1, 1.), 3.) + .05;
        col = mix(vec4(grey,0.05), vec4(clay,1.0), dif - noiseadd * 20.);
    }

	gl_FragColor = col;
}
