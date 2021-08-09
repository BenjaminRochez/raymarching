uniform float time;
uniform float progress;
uniform sampler2D texture1;
uniform vec4 resolution;
varying vec2 vUv;
float PI = 3.141592653589793238;
uniform sampler2D matcap;
uniform vec2 mouse;

// ROTATE 3D function - https://gist.github.com/yiwenl/3f804e80d0930e34a0b33359259b556c
mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}


// Function matcap  - https://github.com/hughsk/matcap

vec2 getmatcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}

// Functions sphere creation - https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere(vec3 p, float r){
	return length(p)-r;
}

// Function BOX - https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Polynomial minimum function - https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// Function create object
float sdf(vec3 p){
	vec3 p1 = rotate(p, vec3(1.), time/5.);
	float box = sdBox(p1, vec3(0.3));
	float sphere = sdSphere(p - vec3(mouse * 1.5, 0.), 0.2);
	return smin(box, sphere, 0.5);
}

// Normales vectors to have the 3D effect - https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(sdf(p+h.xyy) - sdf(p-h.xyy),
                           sdf(p+h.yxy) - sdf(p-h.yxy),
                           sdf(p+h.yyx) - sdf(p-h.yyx) ) );
}



void main()	{
	vec2 newUV = (vUv - vec2(0.5))*resolution.zw + vec2(0.5); 

	// Camera position
	vec3 camPos = vec3(0., 0., 2.);

	//Ray fired to the object
	vec3 ray = normalize(vec3( (vUv - vec2(0.5)) , -1));
	//vec3 ray = normalize(vec3( (vUv - vec2(0.5))*resolution.zw , -1));
	vec3 rayPos = camPos;

	float t = 0.;
	float tMax = 5.;
	for(int i=0; i<256; ++i){
		vec3 pos = camPos + t*ray;
		float h = sdf(pos);
		if(h<0.0001 || t>tMax) break;
		t+=h;
	}

	vec3 color = vec3(0.);
	if(t<tMax){
		vec3 pos = camPos + t*ray; 
		color = vec3(1.);
		vec3 normal = calcNormal(pos);
		color = normal;
		float diff = dot(vec3(1.), normal);
		vec2 matcapUV = getmatcap(ray, normal);
		color = vec3(diff);
		color = vec3(matcapUV, 0.); 
		color = texture2D(matcap, matcapUV).rgb;
	}

	gl_FragColor = vec4(color,1.); 
}