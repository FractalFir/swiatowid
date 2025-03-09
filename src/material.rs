use crate::{f, vec3, Color, Float};

#[derive(Hash,Clone,Copy)]
pub struct Material{
    color:Color,
    emission:Color,
    roughness:Float,
}
impl Material {
    pub(crate) fn body(&self) -> String {
        let (r,g,b) = self.color;
        let rough = self.roughness;
        let (er,eg,eb) = self.emission;
        format!("res.col = vec3({r:?}, {g:?},{b:?}); res.rough = {rough:?}; res.emission = vec3({er:?},{eg:?},{eb});")
    }
}
impl Default for Material{
    fn default() -> Self {
        Self { color: vec3!(0.8,0.8,0.8), emission: Default::default(), roughness: f!(0.1) }
    }
}