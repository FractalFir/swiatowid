use std::{
    collections::HashSet,
    hash::{Hash, Hasher},
    io::Write,
};

use acc::AcceleartionYPlane;
use r#box::BoxSDF;
use ordered_float::OrderedFloat;
mod plane;
mod material;
mod sphere;
mod acc;
mod r#box;
mod union;
mod repeat;
use material::*;
use plane::Plane;
use repeat::Repeat;
use sphere::*;
use union::*;
type Float = OrderedFloat<f32>;
type Vec3 = (Float, Float, Float);
type Color = Vec3;
#[derive(Clone)]
enum AnySdf {
    Sphere(Sphere),
    Union(Union),
    Plane(Plane),
    AcceleartionYPlane(AcceleartionYPlane),
    BoxSDF(BoxSDF),
    Repeat(Repeat),
}
impl std::hash::Hash for AnySdf {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        match self {
            AnySdf::Sphere(sphere) => sphere.hash(state),
            AnySdf::Union(union) => union.hash(state),
            AnySdf::Plane(plane) => plane.hash(state),
            AnySdf::AcceleartionYPlane(acceleartion_yplane) => acceleartion_yplane.hash(state),
            AnySdf::BoxSDF(box_sdf) => box_sdf.hash(state),
            AnySdf::Repeat(repeat) => repeat.hash(state),
        }
    }
}
impl SDF for AnySdf {
    fn body(&self, set: &mut HashSet<u64>, source: &mut String) -> String {
        match self {
            AnySdf::Sphere(sphere) => sphere.body(set, source),
            AnySdf::Union(union) => union.body(set, source),
            AnySdf::Plane(plane) => plane.body(set, source),
            AnySdf::AcceleartionYPlane(acceleartion_yplane) => acceleartion_yplane.body(set, source),
            AnySdf::BoxSDF(box_sdf)=>box_sdf.body(set, source),
            AnySdf::Repeat(repeat) => repeat.body(set, source),
        }
    }
}
trait SDF: Hash {
    fn id(&self) -> u64 {
        let mut hasher = std::hash::DefaultHasher::new();
        self.hash(&mut hasher);
        hasher.finish()
    }
    fn ensure_present(&self, set: &mut HashSet<u64>, source: &mut String) {
        let id = self.id();
        if set.insert(id) {
            let body = self.body(set, source);
            source.push_str(&format!(
                "SDFRes n{id:x}(vec3 pos){{\n\tSDFRes res;\n\t{body}\n\treturn res;}}"
            ));
        }
    }
    fn body(&self, set: &mut HashSet<u64>, source: &mut String) -> String;
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
        ($crate::f!($x), $crate::f!($y), crate::f!($z))
    };
}
fn export_sdf(sdf: &impl SDF) -> String {
    let mut src = String::new();
    let mut present = HashSet::default();
    sdf.ensure_present(&mut present, &mut src);
    src.push_str(&format!(
        "SDFRes world_main(vec3 pos){{return n{id:x}(pos);}}",
        id = sdf.id()
    ));
    src
}
fn main() {
    let mut res = std::fs::File::create("res.glsl").unwrap();
    res.write(include_bytes!("prefix.glsl")).unwrap();
    let mut mat = Material::default();
    //mat.transparency.0 = 0.7;
    let a = AnySdf::Sphere(Sphere {
        pos: vec3!(0.0, 0.0, 3.5),
        rad: f!(1.0),
        mat,
    });
    let mut mat = Material::default();
    mat.color = vec3!(0.7, 0.6, 0.7);
    let b = AnySdf::Sphere(Sphere {
        pos: vec3!(1.125, 0.0, 3.5),
        rad: f!(0.5),
        mat,
    });
    let mut mat = Material::default();
    mat.color = vec3!(0.4, 0.5, 0.4);
    let ground = AnySdf::Plane(Plane{ dir: vec3!(0.0,1.0,0.0), height:f!(-0.4), mat });
    let mut mat = Material::default();
    mat.color = vec3!(0.8, 0.7, 0.78);
    mat.roughness.0 = 0.9;
    let b = AnySdf::BoxSDF(BoxSDF { pos: vec3!(0.5,-0.4,0.5), size: vec3!(0.5,0.05,0.5), round:f!(0.1), mat });
    let r = AnySdf::Repeat(Repeat::new(b, Some(f!(1.0)), None, Some(f!(1.0))));
    let wallx_spacing = 4.5;
    let wallx = AnySdf::BoxSDF(BoxSDF { pos: vec3!(4.5,0.4,0.5), size: vec3!(0.5,f32::MAX,f32::MAX), round:f!(0.1), mat });
    let wallx = AnySdf::Repeat(Repeat::new(wallx, Some(f!(8.0)), None, None));
    let wallz = AnySdf::BoxSDF(BoxSDF { pos: vec3!(0.0,0.4,wallx_spacing), size: vec3!(f32::MAX,f32::MAX,0.5), round:f!(0.1), mat });
    let wallz = AnySdf::Repeat(Repeat::new(wallz,  None, None,Some(f!(8.0))));
    res.write(export_sdf(&Union::new(vec![a, r,ground,wallx,wallz], f!(0.0))).as_bytes())
        .unwrap();
    res.write(include_bytes!("shadertoy.glsl")).unwrap();
}
