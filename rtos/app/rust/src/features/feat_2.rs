#[cfg(target_arch = "aarch64")]
use crate::println;
use crate::register;
use crate::framework::init;

struct Feat2;

impl init::Feature for Feat2 {
    fn init(&self) {
        println!("feat 2 init!");
    }
    fn event_type(&self) {}
    fn handler(&self) {}
}

register!(Feat2, rb_init_f2);

