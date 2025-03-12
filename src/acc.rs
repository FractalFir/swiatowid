use crate::*;
#[derive(Clone,Hash)]
pub struct AcceleartionYPlane{
    sdf:Box<AnySdf>,
    height:Float,
    margin:Float
}

impl AcceleartionYPlane {
    pub fn new(sdf: AnySdf, height: Float, margin: Float) -> Self {
        Self { sdf:sdf.into(), height, margin }
    }
}
impl SDF for AcceleartionYPlane{
    fn body(&self, set: &mut HashSet<u64>, source: &mut String) -> String {
        let upper_end = self.height + self.margin;
        self.sdf.ensure_present(set, source);
        format!("if (pos.y > {upper_end:?}){{SDFResult r; r.dst = pos.y - {height};}}else{{return {sdf}(pos);}}",sdf = self.sdf.id(), height = self.height)
    }
}