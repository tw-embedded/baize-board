#[cfg(target_arch = "aarch64")]
use crate::println;
use crate::register;
use crate::framework::init;

struct Feat1;

impl init::Feature for Feat1 {
    fn init(&self) {
        println!("feat 1 init!");
    }
    fn event_type(&self) {}
    fn handler(&self) {}
}

register!(Feat1);
