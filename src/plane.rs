use crate::*;
#[derive(Hash, Clone, Copy)]
pub struct Plane {
    pub dir: Vec3,
    pub height: Float,
    pub mat: Material,
}
impl SDF for Plane {
    fn body(&self, _: &mut HashSet<u64>, _: &mut String) -> String {
        let mat = self.mat.body();
        format!(
            "res.dst = dot(pos,vec3({x:?},{y:?},{z:?})) - {height:?};\n\t{mat}",
            x = self.dir.0,
            y = self.dir.1,
            z = self.dir.2,
            height = self.height
        )
    }
}
