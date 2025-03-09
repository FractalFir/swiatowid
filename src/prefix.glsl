const vec3 CAMERA_ORIGIN = vec3(0.0);
const float START_EPS = 0.005;
const int STEPS = 128;
const int SAMPLES = 2;
const float DRAW_DISTANCE = 500.0;
float hash(float i){
	return fract(sin(i*334.343)*534.344);
}
float hash(vec2 i){
	return hash(hash(i.x)*42.2 - hash(i.y));
}
float hash(vec3 i){
	return hash(hash(i.x)*2.2 - hash(i.y)*3.12 + hash(i.z)*2.45);
}
struct Ray{
	vec3 pos;
	vec3 dir;
	vec3 energy;
	vec3 emission;
	float eps;
};
struct SDFRes{
	vec3 col;
	vec3 emission;
	float rough;
	float dst;
};
Ray camera_ray(vec2 uv){
	Ray r;
	r.pos = normalize(vec3(uv.x, uv.y, 1.0));
	r.dir = r.pos;
	r.pos += CAMERA_ORIGIN;
	r.energy = vec3(1.0);
	r.eps = START_EPS;
	return r;
}
SDFRes world_main(vec3 pos);
vec3 sdf_dir(vec3 pos, float c){
	float cx = world_main(pos + vec3(0.005,0,0)).dst;
	float cy = world_main(pos + vec3(0,0.005,0)).dst;
	float cz = world_main(pos + vec3(0,0,0.005)).dst;
	return normalize(vec3(c - cx, c - cy, c - cz));
}
vec3 randvec3(vec3 pos){
	float h = hash(pos);
	return vec3(hash(h),hash(-h), hash(h*32.3433)) - vec3(0.5);
}
void ray_step(inout Ray r){
	SDFRes s = world_main(r.pos);
	r.emission += s.emission * r.energy * s.dst;
	if(s.dst < r.eps){
		vec3 sdir = sdf_dir(r.pos,s.dst);
		vec3 reflected = reflect(r.dir,sdir);
		if(hash(r.pos) < s.rough){
			r.dir = normalize(reflected + randvec3(r.pos) * 0.35);
		}
		else{
			r.dir =reflected;
		}
		r.eps *= 2.0;
		r.pos += r.eps * r.dir * 16.0;
		r.energy *= s.col;
	}
	r.pos += r.dir * s.dst;
}
vec3 world_color(vec3 dir){
	vec3 sun = normalize(vec3(0.3,1.0,-0.2));
	float sun_factor = clamp(pow(dot(sun,dir) + 0.05,9.0),0.0,1.0);
	vec3 sun_color = vec3(0.95,0.9,0.8);
	vec3 sky_color = vec3(0.7,0.6,0.6);
	vec3 ground_color = vec3(0.2,0.2,0.2);
	vec3 atm_color = mix(sky_color,sun_color,sun_factor);
	return mix(atm_color,ground_color,clamp(-dir.y,0.0,1.0));
}
vec3 ray_color(in Ray r){
	vec3 emission = r.emission;
	vec3 sky = r.energy * world_color(r.dir);
	return max(sky,emission);
}
vec3 sim_ray(inout Ray r){
	for(int i = 0; i < STEPS; i++){
		ray_step(r);
		if(distance(r.pos, CAMERA_ORIGIN) > DRAW_DISTANCE){
            break; 
        }
	}
	return ray_color(r);
}
vec3 sim_sample(vec2 uv, vec2 pixel_size, int sam, out bool is_miss){
	vec2 offset = pixel_size*vec2(hash(float(sam) + uv.y),hash(float(sam) + uv.x));
	Ray r = camera_ray(uv);
	vec3 res = sim_ray(r);
	is_miss = r.eps != START_EPS;
	return res;
}
vec3 sim_pixel(vec2 uv, vec2 pixel_size){
	vec3 col = vec3(0);
	for (int i = 0; i < SAMPLES; i++){
		bool is_miss = true;
		col += sim_sample(uv,pixel_size,i,is_miss);
		if(is_miss){
			col /= float(i + 1);
			return col;
		}
	}
	return col / float(SAMPLES);
}