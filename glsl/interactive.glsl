uniform vec2 resolution;
uniform float time;
uniform float fov;
uniform float raymarchMaximumDistance;
uniform float raymarchPrecision;
uniform vec3 camera;
uniform vec3 target;

uniform vec3 color0;
uniform vec3 color1;

uniform vec3 light0;
uniform vec3 light1;


//uses most of the StackGL methods
//https://github.com/stackgl

//https://github.com/hughsk/glsl-square-frame

vec2 squareFrame(vec2 screenSize) {
  vec2 position = 2.0 * (gl_FragCoord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}
vec2 squareFrame(vec2 screenSize, vec2 coord) {
  vec2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

//https://github.com/stackgl/glsl-look-at/blob/gh-pages/index.glsl

mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));
  return mat3(uu, vv, ww);
}

//https://github.com/stackgl/glsl-camera-ray

vec3 getRay(mat3 camMat, vec2 screenPos, float lensLength) {
  return normalize(camMat * vec3(screenPos, lensLength));
}
vec3 getRay(vec3 origin, vec3 target, vec2 screenPos, float lensLength) {
  mat3 camMat = calcLookAtMatrix(origin, target, 0.0);
  return getRay(camMat, screenPos, lensLength);
}

/////////////////////////////////////////////////////////////////////////

mat3 rotationMatrix3(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}

/////////////////////////////////////////////////////////////////////////

//primitives

float sphere( vec3 p, float radius, vec3 pos)
{
   return length( p - pos ) - radius;
}

float roundBox(vec3 p, vec3 size, float corner, vec3 pos)
{
    return length( max( abs( p-pos )-size, 0.0 ) )-corner;
}

float torus( vec3 p, vec2 radii, vec3 pos)
{
    vec3 pp = ( p - pos );
    return length( vec2( length( pp.xz ) - radii.x, pp.y ) ) - radii.y;
}

// http://www.pouet.net/topic.php?post=365312
float cylinder( vec3 p, float h, float r, vec3 pos)
{
    vec3 pp = (p - pos );
    return max(length(pp.xz)-r, abs(pp.y)-h);
}


//operations

vec2 unionAB(vec2 a, vec2 b){return vec2(min(a.x, b.x),1.);}
vec2 intersectionAB(vec2 a, vec2 b){return vec2(max(a.x, b.x),1.);}
vec2 blendAB( vec2 a, vec2 b, float t ){ return vec2(mix(a.x, b.x, t ),1.);}
vec2 subtract(vec2 a, vec2 b){ return vec2(max(-a.x, b.x),1.); }
//http://iquilezles.org/www/articles/smin/smin.htm
vec2 smin( vec2 a, vec2 b, float k ) { float h = clamp( 0.5+0.5*(b.x-a.x)/k, 0.0, 1.0 ); return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), 1. ); }

//utils

vec3 twist( vec3 pos, float amount )
{
    vec3 p = normalize( pos );
    float c = cos(amount * p.y);
    float s = sin(amount * p.y);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*pos.xz,pos.y);
    return q;
}
vec3 repeat( vec3 p, vec3 r )
{
    return mod( p, r ) - .5 * r;
}

//http://www.pouet/..net/topic.php?post=367360
const vec3 pa = vec3(1., 57., 21.);
const vec4 pb = vec4(0., 57., 21., 78.);
float perlin(vec3 p) {
	vec3 i = floor(p);
	vec4 a = dot( i, pa ) + pb;
	vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
	a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
	a.xy = mix(a.xz, a.yw, f.y);
	return mix(a.x, a.y, f.z);
}

/////////////////////////////////////////////////////////////////////////

// STOP ! ! !

// HAMMER TIME !

/////////////////////////////////////////////////////////////////////////


const int raymarchSteps = 50;

const int shadowSteps = 4;
const int ambienOcclusionSteps = 3;
const float PI = 3.14159;
/////////////////////////////////////////////////////////////////////////

// the methods below this need the field function

/////////////////////////////////////////////////////////////////////////
vec2 field(vec3 position){
				return vec2(sdf(position), 1.);
}

//the actual raymarching from:
//https://github.com/stackgl/glsl-raytrace/blob/master/index.glsl

vec2 raymarching( vec3 rayOrigin, vec3 rayDir, float maxd, float precis ) {

    float latest = precis * 2.0;
    float dist   = 0.0;
    float type   = -1.0;
    for (int i = 0; i < raymarchSteps; i++) {

        if (latest < precis || dist > maxd) break;

        vec2 result = field( rayOrigin + rayDir * dist );
        latest = result.x;
        dist  += latest;

        type = result.y;
    }

    vec2 res    = vec2(-1.0, -1.0 );
    if (dist < maxd) { res = vec2( dist, type ); }
    return res;

}

//https://github.com/stackgl/glsl-sdf-normal

vec3 calcNormal(vec3 pos, float eps) {
  const vec3 v1 = vec3( 1.0,-1.0,-1.0);
  const vec3 v2 = vec3(-1.0,-1.0, 1.0);
  const vec3 v3 = vec3(-1.0, 1.0,-1.0);
  const vec3 v4 = vec3( 1.0, 1.0, 1.0);

  return normalize( v1 * field( pos + v1*eps ).x +
                    v2 * field( pos + v2*eps ).x +
                    v3 * field( pos + v3*eps ).x +
                    v4 * field( pos + v4*eps ).x );
}

vec3 calcNormal(vec3 pos) {
  return calcNormal(pos, 0.002);
}


//shadows & AO

//https://www.shadertoy.com/view/Xds3zN

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax, in float K )
{
	float res = 1.0;
    float t = mint;
    for( int i=0; i<shadowSteps; i++ )
    {
		float h = field( ro + rd*t ).x;
        res = min( res, K * h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<ambienOcclusionSteps; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/float( ambienOcclusionSteps );
        vec3 aopos =  nor * hr + pos;
        float dd = field( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}


vec3 rimlight( vec3 pos, vec3 nor )
{
    vec3 v = normalize(-pos);
    float vdn = 1.0 - max(dot(v, nor), 0.0);
    return vec3(smoothstep(0., 1.0, vdn));
}



void main() {

    vec2  screenPos    = squareFrame( resolution );

    vec3  rayDirection = getRay( camera, target, screenPos, fov );

    vec2 collision = raymarching( camera, rayDirection, raymarchMaximumDistance, raymarchPrecision );

    gl_FragColor = vec4( mix( color0, color1, sin( screenPos.y + 1.5 ) ) * 2., 1. );
    if ( collision.x > -0.5)
    {

        //"world" position
        vec3 pos = camera + rayDirection * collision.x;

        //diffuse color
        vec3 col = vec3( collision.y );

        //normal vector
        vec3 nor = calcNormal( pos );

        vec3 lig0 = normalize( light0 );
        vec3 lightColor0 =  max( 0.0, dot( lig0, nor) ) * color0;

        vec3 lightColor1 = max( 0.0, dot( normalize( light1 ), nor) ) * color1;

        float depth = 1./ log( collision.x );

        gl_FragColor = vec4( ( col + lightColor0 + lightColor1 ) * depth, 1. );

    }

}
