
#include "common/common.glsl"

float terrainFunction(vec2 xy) {
    return fbmalt(xy, 1.5);
}

bool castRay( vec3 ro, vec3 rd, inout float resT )
{
    float dt = 0.01;
    const float mint = 0.001;
    const float maxt = 3.0;
    float lh = 0.0;
    float ly = 0.0;
    for( float t = mint; t < maxt; t += dt )
    {
        vec3  p = ro + rd*t;
        float h = terrainFunction( p.xz );
        if( p.y < h )
        {
            // interpolate the intersection distance
            resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);
            return true;
        }
        // allow the error to be proportinal to the distance
        dt = 0.01f*t;
        lh = h;
        ly = p.y;
    }
    return false;
}