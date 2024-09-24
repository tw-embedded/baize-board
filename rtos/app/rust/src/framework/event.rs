use core::any::Any;

pub trait Event {
    fn get_type(&self) -> &'static str;
}

pub trait EventHandler {
    fn handle(&self, event: &dyn Event);
}

