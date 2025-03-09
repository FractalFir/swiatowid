use std::{collections::HashSet, hash::{Hash, Hasher}, io::Write};

use ordered_float::OrderedFloat;

mod sphere;
mod material;
use sphere::*;
use material::*;
type Float = OrderedFloat<f32>;
type Vec3 = (Float,Float,Float);
type Color = Vec3;
#[derive(Clone,Copy)]
enum AnySdf{
    Sphere(Sphere),
}
impl std::hash::Hash for AnySdf{
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        match self{
            AnySdf::Sphere(sphere) => sphere.hash(state),
        }
    }
}
trait SDF:Hash{
    fn id(&self)->u64{
        let mut hasher = std::hash::DefaultHasher::new();
        self.hash(&mut hasher);
        hasher.finish()
    }
    fn ensure_present(&self, set:&mut HashSet<u64>,source:&mut String){
        let id = self.id();
        if set.insert(id){
            let body = self.body(set, source);
            source.push_str(&format!("SDFRes n{id:x}(vec3 pos){{\n\tSDFRes res;\n\t{body}\n\treturn res;}}"));
        }
    }
    fn body(&self,set:&mut HashSet<u64>,source:&mut String)->String;
}

#[macro_export]
macro_rules! f {
    ($v:expr) => {
        ordered_float::OrderedFloat($v)
    };
}
#[macro_export]
macro_rules! vec3 {
    ($x:expr, $y:expr, $z:expr) => {
        ($crate::f!($x),$crate::f!($y),crate::f!($z))
    };
}
fn export_sdf(sdf:&impl SDF)->String{
    let mut src = String::new();
    let mut present = HashSet::default();
    sdf.ensure_present(&mut present, &mut src);
    src.push_str(&format!("SDFRes world_main(vec3 pos){{return n{id:x}(pos);}}", id = sdf.id()));
    src
}
fn main() {
    let mut res = std::fs::File::create("res.glsl").unwrap();
    res.write(include_bytes!("prefix.glsl")).unwrap();
    let sdf = Sphere{ pos:vec3!(0.0,0.0,3.5), rad: f!(1.0), mat: Material::default() };
    res.write(export_sdf(&sdf).as_bytes()).unwrap();
    res.write(include_bytes!("shadertoy.glsl")).unwrap();
}
