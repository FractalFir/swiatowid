use crate::*;
#[derive(Hash, Clone, Copy)]
pub struct BoxSDF {
    pub pos: Vec3,
    pub size:Vec3,
    pub round: Float,
    pub mat: Material,
}
impl SDF for BoxSDF {
    fn body(&self, _: &mut HashSet<u64>, _: &mut String) -> String {
        let mat = self.mat.body();
        if self.round == 0.0{
            let (x,y,z) = self.pos;
            let (sx,sy,sz) = self.size;
            format!("vec3 q = abs(pos - vec3({x:?},{y:?},{z:?})) - vec3({sx:?},{sy:?},{sz:?});\n\tres.dst = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);{mat}")
        }
       else{
        let (x,y,z) = self.pos;
            let (sx,sy,sz) = self.size;
            let r = self.round;
            format!("vec3 q = abs(pos - vec3({x:?},{y:?},{z:?})) - vec3({sx:?},{sy:?},{sz:?}) + {r};\n\tres.dst = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - {r};{mat}")
       }
    }
}
