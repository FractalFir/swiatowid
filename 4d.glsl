const vec4 CAMERA_ORIGIN = vec4(0.0);
const float START_EPS = 0.01;
const int STEPS = 300;
const int SAMPLES = 1;
const float DRAW_DISTANCE = 25.0;
const float NOISE_FACTOR = 0.005;
float hash(float i){
	return fract(sin(i*3344.343)*5334.344);
}
float hash(vec2 i){
	return hash(hash(i.x)*42.2 - hash(i.y));
}
float hash(vec4 i){
	return hash(hash(i.x)*2.2 - hash(i.y)*3.12 + hash(i.z)*2.45  + hash(i.w)*3.45);
}
struct Ray{
	vec4 pos;
	vec4 dir;
	vec3 energy;
	vec3 emission;
	float eps;
};
struct SDFRes{
	vec3 col;
	vec3 emission;
	float rough;
	float dst;
	float trans;
};
Ray camera_ray(vec2 uv,float w){
	Ray r;
	r.pos = normalize(vec4(uv.x, uv.y, 1.0,w));
	r.dir = r.pos;
	r.pos += CAMERA_ORIGIN;
	r.energy = vec3(1.0);
	r.eps = START_EPS;
	return r;
}
SDFRes world_main(vec4 pos);
vec4 sdf_dir(vec4 pos, float c){
	float cx = world_main(pos + vec4(0.005,0,0,0)).dst;
	float cy = world_main(pos + vec4(0,0.005,0,0)).dst;
	float cz = world_main(pos + vec4(0,0,0.005,0)).dst;
	float cw = world_main(pos + vec4(0,0,0,0.005)).dst;
	return normalize(vec4(c - cx, c - cy, c - cz, c - cw));
}
vec4 randvec3(vec4 pos){
	float h = hash(pos);
	return vec4(hash(h),hash(-h), hash(h*32.3433), hash(-h*32.3433)) - vec4(0.5);
}
void ray_step(inout Ray r){
	SDFRes s = world_main(r.pos);
	r.emission += s.emission * r.energy * s.dst;
	if(abs(s.dst) < r.eps){
		vec4 sdir = sdf_dir(r.pos,s.dst) * sign(s.dst);
		if (hash(r.pos + vec4(1.0)) < s.trans){
			vec4 reflected = reflect(-r.dir,sdir);
             r.pos += r.eps * sdir * 2.0;
			if(hash(r.pos) < s.rough){
				r.dir = normalize(reflected + randvec3(r.pos) * 0.35);
			}
			else{
				r.dir =reflected;
			}
            
		}
		else{
			vec4 reflected = reflect(r.dir,sdir);
             r.eps *= 1.5;
             r.pos -= r.eps * sdir * 2.0;
			if(hash(r.pos) < s.rough){
				r.dir = normalize(reflected + randvec3(r.pos) * 0.35);
                 
			}
			else{
				r.dir = reflected;
			}
			
		}
	
			
        r.energy *= s.col;
	}
	r.pos += r.dir * abs(s.dst);
	if(hash(r.pos) > 1.0 - NOISE_FACTOR){
        r.dir = normalize(mix(r.dir,randvec3(r.dir),s.dst * NOISE_FACTOR));
    }
	
}
vec3 world_color(vec4 dir){
	vec4 sun = normalize(vec4(0.3,1.0,-0.2,0.1));
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
	vec2 offset = pixel_size*vec2(hash(float(sam)+ iTime + hash(uv)),hash(float(sam) + hash(uv)));
	Ray r = camera_ray(uv + offset,hash(iTime * 35.43 + hash(offset)) * 0.006125);
	vec3 res = sim_ray(r);
	is_miss = r.eps == START_EPS;
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
			rhs.col = mix(rhs.col,lhs.col, 1.0 - diff / smooth_factor); 
		}else{
			lhs.col = mix(lhs.col,rhs.col, clamp(diff / smooth_factor,0.0,1.0));
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
}SDFRes n734b972a86473784(vec4 pos){
	SDFRes res;
	res.dst = distance(pos,vec4(0.5,0.0,3.5,0.2)) - 1.0;
	res.col = vec3(0.8, 0.8,0.8); res.rough = 0.1; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}
    SDFRes offset(vec4 pos){
	SDFRes res;
	res.dst = distance(pos,vec4(0.0,0.0,3.5,0.0)) - 1.0;
	res.col = vec3(0.8, 0.8,0.8); res.rough = 0.1; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}SDFRes ndcb67f67b2d2554e(vec4 pos){
	SDFRes res;
	vec4 q = abs(pos - vec4(0.5,-0.4,0.5,0.5)) - vec4(0.5,0.05,0.5,0.5) + 0.1;
	res.dst = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - 0.1;res.col = pos.xzw; res.rough = 0.9; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}SDFRes n28a1a5e938e21eb3(vec4 pos){
	SDFRes res;
	pos.xzw = mod(pos.xzw,vec3(1.0,1.0,1.0));
	res = ndcb67f67b2d2554e(pos);
	return res;}SDFRes n1cf3245e6e66996f(vec4 pos){
	SDFRes res;
	res.dst = dot(pos,vec4(0.0,1.0,0.0,0.0)) - -0.4;
	res.col = vec3(0.3, 0.5,0.4); res.rough = 0.1; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}SDFRes nbf1ff9781ef7fdc1(vec4 pos){
	SDFRes res;
	vec4 q = abs(pos - vec4(4.5,0.4,0.5,0.0)) - vec4(0.5,3.4028235e38,3.4028235e38,0.5) + 0.1;
	res.dst = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - 0.1;res.col = vec3(0.8, 0.7,0.78); res.rough = 0.9; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}SDFRes n848c56bc87dad6f9(vec4 pos){
	SDFRes res;
	pos.x = mod(pos.x,8.0);
	res = nbf1ff9781ef7fdc1(pos);
	return res;}SDFRes n448377d2a88e9bc1(vec4 pos){
	SDFRes res;
	vec4 q = abs(pos - vec4(0.0,0.4,4.5,0.0)) - vec4(3.4028235e38,3.4028235e38,0.5,0.5) + 0.1;
	res.dst = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - 0.1;res.col = vec3(0.8, 0.7,0.78); res.rough = 0.9; res.emission = vec3(0.0,0.0,0) / max(res.dst * res.dst,1.0); res.trans = 0.0;
	return res;}SDFRes nc6d4f76042464d34(vec4 pos){
	SDFRes res;
	pos.z = mod(pos.z,8.0);
	res = n448377d2a88e9bc1(pos);
	return res;}SDFRes nbed7d5da61888803(vec4 pos){
	SDFRes res;
	res = sdf_union(smooth_sdf_union(sdf_union(n734b972a86473784(pos),n28a1a5e938e21eb3(pos)),offset(pos),0.1),sdf_union(n1cf3245e6e66996f(pos),sdf_union(n848c56bc87dad6f9(pos),nc6d4f76042464d34(pos))));
	return res;}SDFRes world_main(vec4 pos){return nbed7d5da61888803(pos);}void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    float res = max(iResolution.x,iResolution.y);
    vec2 uv = (fragCoord - iResolution.xy / 2.0)/res;
    fragColor = vec4(sim_pixel(uv, vec2(1.0 / res,1.0 / res)),1.0);
}