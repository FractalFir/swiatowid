use crate::{Color, Float, f, vec3};

#[derive(Hash, Clone, Copy)]
pub struct Material {
    pub color: Color,
    pub emission: Color,
    pub roughness: Float,
    pub transparency: Float,
}
impl Material {
    pub(crate) fn body(&self) -> String {
        let (r, g, b) = self.color;
        let rough = self.roughness;
        let (er, eg, eb) = self.emission;
        let trans = self.transparency;
        format!(
            "res.clr = vec3({r:?}, {g:?},{b:?}); res.rough = {rough:?}; res.emission = vec3({er:?},{eg:?},{eb}) / max(res.dst * res.dst,1.0); res.trans = {trans:?};"
        )
    }
}
impl Default for Material {
    fn default() -> Self {
        Self {
            color: vec3!(0.8, 0.8, 0.8),
            emission: Default::default(),
            roughness: f!(0.1),
            transparency: f!(0.0),
        }
    }
}
