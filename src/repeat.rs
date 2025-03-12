use std::collections::HashSet;

use crate::{AnySdf, Float, SDF};

#[derive(Clone,Hash)]
pub struct Repeat{
    sdf:Box<AnySdf>,
    size_x:Option<Float>,
    size_y:Option<Float>,
    size_z:Option<Float>,
}

impl Repeat {
    pub fn new(sdf: AnySdf,  size_x:Option<Float>,
        size_y:Option<Float>,
        size_z:Option<Float>) -> Self {
        Self { sdf:sdf.into(), size_x,size_y,size_z}
    }
}
impl SDF for Repeat{
    fn body(&self, set: &mut HashSet<u64>, source: &mut String) -> String {
        self.sdf.ensure_present(set, source);
        let inner = self.sdf.id();
        let md = match (self.size_x,self.size_y,self.size_z){
            (None, None, None) => todo!(),
            (None, None, Some(z)) =>  {
                format!("pos.z = mod(pos.z,{z:?});")
            },
            (None, Some(_), None) => todo!(),
            (None, Some(_), Some(_)) => todo!(),
            (Some(x), None, None) => {
                format!("pos.x = mod(pos.x,{x:?});")
            },
            (Some(x), None, Some(z)) => {
                format!("pos.xz = mod(pos.xz,vec2({x:?},{z:?}));")
            }
            (Some(_), Some(_), None) => todo!(),
            (Some(_), Some(_), Some(_)) => todo!(),
        };
        format!("{md}\n\tres = n{inner:x}(pos);")
    }
}