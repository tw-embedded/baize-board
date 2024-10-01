#[cfg(target_arch = "aarch64")]
use crate::println;
use crate::framework::init;

use framework_macros::feature_definition;

#[feature_definition]
struct Feat1;

impl init::Feature for Feat1 {
    fn init(&self) {
        println!("feat 1 init!");
    }
    fn event_type(&self) {}
    fn handler(&self) {}
}

