
use alloc::string::String; 
use crate::framework::event;

pub struct MyEvent {
    pub message: String
}

impl event::Event for MyEvent {
    fn get_type(&self) -> &'static str {
        "MyEvent"
    }
}
