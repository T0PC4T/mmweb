// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
	float res = 1.0;
    float t = tmin;
    for( int i=0; i<64; i++ )
    {
		float h = map( ro + rd*t );
        res = min( res, k*h/t );
        t += clamp( h, 0.01, 0.10 );
        if( res<0.002 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}