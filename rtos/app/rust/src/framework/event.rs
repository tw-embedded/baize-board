use core::any::Any;

pub trait Event {
    fn get_type(&self) -> &'static str;
    fn as_any(&self) -> &dyn Any;
}

pub trait EventHandler {
    fn handle(&self, event: &dyn Event);
}

