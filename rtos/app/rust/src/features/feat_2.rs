#[cfg(target_arch = "aarch64")]
use crate::println;
use crate::framework::init;

use customize_macros::feature_definition;

#[feature_definition]
struct Feat2;

impl init::Feature for Feat2 {
    fn init(&self) {
        println!("feat 2 init!");
    }
    fn event_type(&self) {}
    fn handler(&self) {}
}

