#ifndef MODE_4D
#define vec vec3
#else
#define vec vec4
#endif 
#define col vec3
const vec CAMERA_ORIGIN = vec(0.0);
const float START_EPS = 0.005;
const int STEPS = 200;
const int SAMPLES = 2;
const float DRAW_DISTANCE = 100.0;
const float NOISE_FACTOR = 0.005;
float hash(float i){
	return fract(sin(i*3344.343)*5334.344);
}
float hash(vec2 i){
	return hash(hash(i.x)*42.2 - hash(i.y));
}
float hash(vec3 i){
	return hash(hash(i.x)*2.2 - hash(i.y)*3.12 + hash(i.z)*2.45);
}
float hash(vec4 i){
	return hash(hash(i.x)*2.2 - hash(i.y)*3.12 + hash(i.z)*2.45 - hash(i.z)*5.45);
}
struct Ray{
	vec pos;
	vec dir;
	col energy;
	col emission;
	float eps;
};
Ray camera_ray(vec2 uv){
	Ray r;
	r.pos = normalize(vec(uv.x, uv.y, 1.0));
	r.dir = r.pos;
	r.pos += CAMERA_ORIGIN;
	r.energy = col(1.0);
	r.eps = START_EPS;
	return r;
}
struct SDFRes{
	col clr;
	col emission;
	float rough;
	float dst;
	float trans;
};

SDFRes world_main(vec pos);
vec sdf_dir(vec pos, float c){
	float cx = world_main(pos + vec3(0.005,0,0)).dst;
	float cy = world_main(pos + vec3(0,0.005,0)).dst;
	float cz = world_main(pos + vec3(0,0,0.005)).dst;
	return normalize(vec3(c - cx, c - cy, c - cz));
}
vec randvec(vec pos){
	float h = hash(pos);
	return vec(hash(h),hash(-h), hash(h*32.3433)) - vec(0.5);
}
void ray_step(inout Ray r){
	SDFRes s = world_main(r.pos);
	r.emission += s.emission * r.energy * s.dst;
	if(abs(s.dst) < r.eps){
		vec sdir = sdf_dir(r.pos,s.dst) * sign(s.dst);
		if (hash(r.pos + vec(1.0)) < s.trans){
			vec reflected = reflect(-r.dir,sdir);
             r.pos += r.eps * sdir * 2.0;
			if(hash(r.pos) < s.rough){
				r.dir = normalize(reflected + randvec(r.pos) * 0.35);
			}
			else{
				r.dir =reflected;
			}
            
		}
		else{
			vec reflected = reflect(r.dir,sdir);
             r.eps *= 1.5;
             r.pos -= r.eps * sdir * 2.0;
			if(hash(r.pos) < s.rough){
				r.dir = normalize(reflected + randvec(r.pos) * 0.35);
                 
			}
			else{
				r.dir = reflected;
			}
			
		}
	
			
        r.energy *= s.clr;
	}
	r.pos += r.dir * abs(s.dst);
	if(hash(r.pos) > 1.0 - NOISE_FACTOR){
        r.dir = normalize(mix(r.dir,randvec(r.dir),s.dst * NOISE_FACTOR));
    }
	
}
col world_color(vec dir){
	vec sun = normalize(vec(0.3,1.0,-0.2));
	float sun_factor = clamp(pow(dot(sun,dir) + 0.05,9.0),0.0,1.0);
	col sun_color = col(0.95,0.9,0.8);
	col sky_color = col(0.7,0.6,0.6);
	col ground_color = col(0.2,0.2,0.2);
	col atm_color = mix(sky_color,sun_color,sun_factor);
	return mix(atm_color,ground_color,clamp(-dir.y,0.0,1.0));
}
col ray_color(in Ray r){
	col emission = r.emission;
	col sky = r.energy * world_color(r.dir);
	return max(sky,emission);
}
col sim_ray(inout Ray r){
	for(int i = 0; i < STEPS; i++){
		ray_step(r);
		if(distance(r.pos, CAMERA_ORIGIN) > DRAW_DISTANCE){
            break; 
        }
	}
	return ray_color(r);
}
col sim_sample(vec2 uv, vec2 pixel_size, int sam, out bool is_miss){
	vec2 offset = pixel_size*vec2(hash(float(sam)+ iTime + hash(uv)),hash(float(sam) + hash(uv)));
	Ray r = camera_ray(uv + offset);
	vec3 res = sim_ray(r);
	is_miss = r.eps == START_EPS;
	return res;
}
col sim_pixel(vec2 uv, vec2 pixel_size){
	vec3 clr = vec3(0);
	for (int i = 0; i < SAMPLES; i++){
		bool is_miss = true;
		clr += sim_sample(uv,pixel_size,i,is_miss);
		if(is_miss){
			clr /= float(i + 1);
			return clr;
		}
	}
	return clr / float(SAMPLES);
}
SDFRes sdf_union(SDFRes lhs, SDFRes rhs){
	if (lhs.dst < rhs.dst){
		lhs.emission = max(lhs.emission,rhs.emission);
		return lhs;
	}else{
		rhs.emission = max(lhs.emission,rhs.emission);
		return rhs;
	}
}
SDFRes smooth_sdf_union(SDFRes lhs, SDFRes rhs,float smooth_factor){
	float h = clamp( 0.5 + 0.5*(rhs.dst-lhs.dst)/smooth_factor, 0.0, 1.0 );
    float dst = mix( rhs.dst, lhs.dst, h ) - smooth_factor*h*(1.0-h);
	float diff = lhs.dst - rhs.dst;
	if (abs(diff) < smooth_factor){
		if (diff > 0.0){
			rhs.clr = mix(rhs.clr,lhs.clr, 1.0 - diff / smooth_factor); 
		}else{
			lhs.clr = mix(lhs.clr,rhs.clr, clamp(diff / smooth_factor,0.0,1.0));
		}
	}
	if (lhs.dst < rhs.dst){
		lhs.dst = dst;
		lhs.emission = max(lhs.emission,rhs.emission);
		return lhs;
	}else{
		rhs.dst = dst;
		rhs.emission = max(lhs.emission,rhs.emission);
		return rhs;
	}
}
