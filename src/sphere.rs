use crate::*;
#[derive(Hash, Clone, Copy)]
pub struct Sphere {
    pub pos: Vec3,
    pub rad: Float,
    pub mat: Material,
}
impl SDF for Sphere {
    fn body(&self, _: &mut HashSet<u64>, _: &mut String) -> String {
        let mat = self.mat.body();
        format!(
            "res.dst = distance(pos,vec3({x:?},{y:?},{z:?})) - {rad:?};\n\t{mat}",
            x = self.pos.0,
            y = self.pos.1,
            z = self.pos.2,
            rad = self.rad
        )
    }
}
