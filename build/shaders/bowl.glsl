#include "common/common.glsl"
#include "common/3d.glsl"

precision mediump float;
precision lowp int;

uniform float iTime;
uniform vec2 iMouse;
uniform vec2 iResolution;

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
    float r = 0.6;
    // height -.5 => .5;
    float h = -0.1;
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
    // vec2 uv = gl_FragCoord.xy/iResolution.xy;
    // set the camera a little back and up
	vec3 ro = vec3( 0.0, 0.2, -1.0);
    vec2 p = (2.0*gl_FragCoord.xy-iResolution.xy)/iResolution.y;

    // create view ray
    vec3 rd = normalize(vec3(p.x, p.y - 0.5, 1.));

    // raymarch
    const float tmax = 2.0;
    float t = 0.0;
    
    // number of steps
    vec3 pos;
    for( int i=0; i<20; i++ )
    {
        // The start position
        pos = ro + t*rd;
        pos = rotate(pos, vec3(0.02,0.2,0.0), iTime);
        float d = map(pos);
        if( d<0.001 || t>tmax ) break;
        t += d;
    }
    

    // shading/lighting	
    vec4 col = vec4(0.0);
    if( t<tmax )
    {
        vec3 nor = calcNormal(pos);
        vec3 lig = normalize(vec3(1., 1., 1.5));
        float dif = clamp( dot(nor,lig), 0.1, .9 );
        col = vec4(vec3(0.9,0.5,0.2)*dif - noise(pos.xy * 5.) * 0.02, 1.);
    }

	gl_FragColor = col;
}