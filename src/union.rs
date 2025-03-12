use crate::{AnySdf, Float, SDF};

#[derive(Clone, Hash)]
pub struct Union {
    sdf: Vec<AnySdf>,
    smooth: Float,
}

impl Union {
    pub fn new(sdf: Vec<AnySdf>, smooth: Float) -> Self {
        Self { sdf, smooth }
    }
}
impl SDF for Union {
    fn body(&self, set: &mut std::collections::HashSet<u64>, source: &mut String) -> String {
        fn i(
            sdf: &[AnySdf],
            set: &mut std::collections::HashSet<u64>,
            source: &mut String,
            smooth: Float,
        ) -> String {
            assert!(!sdf.is_empty());
            let [sdf] = sdf else {
                let (lhs, rhs) = sdf.split_at(sdf.len() / 2);
                let lhs = i(lhs, set, source, smooth);
                let rhs = i(rhs, set, source, smooth);
                if smooth == 0.0 {
                    return format!("sdf_union({lhs},{rhs})");
                } else {
                    return format!("smooth_sdf_union({lhs},{rhs},{smooth:?})");
                }
            };
            sdf.ensure_present(set, source);
            format!("n{id:x}(pos)", id = sdf.id())
        }
        format!("res = {};", i(&self.sdf, set, source, self.smooth))
    }
}
