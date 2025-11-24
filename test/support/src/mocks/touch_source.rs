

use futures::channel::mpsc;
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone)]
pub enum TouchEvent {
    Down { x: f32, y: f32, pointer_id: u32 },
    Move { x: f32, y: f32, pointer_id: u32 },
    Up { pointer_id: u32 },
}

#[derive(Debug, Clone)]
pub struct TouchInteraction {
    pub device_id: u32,
    pub pointer_id: u32,
    pub phase: TouchPhase,
    pub position_x: f32,
    pub position_y: f32,
}

#[derive(Debug, Clone, PartialEq)]
pub enum TouchPhase {
    Add,
    Change,
    Remove,
    Cancel,
}

pub struct MockTouchSource {
    events: Arc<Mutex<Vec<TouchEvent>>>,
    pending_interactions: Arc<Mutex<Vec<TouchInteraction>>>,
    sender: mpsc::UnboundedSender<TouchEvent>,
}

impl MockTouchSource {
    pub fn new() -> (Self, mpsc::UnboundedReceiver<TouchEvent>) {
        let (sender, receiver) = mpsc::unbounded();
        (
            Self {
                events: Arc::new(Mutex::new(Vec::new())),
                pending_interactions: Arc::new(Mutex::new(Vec::new())),
                sender,
            },
            receiver,
        )
    }

    pub fn inject_touch_down(&self, x: f32, y: f32, pointer_id: u32) {
        let event = TouchEvent::Down { x, y, pointer_id };
        self.events.lock().unwrap().push(event.clone());
        
        let interaction = TouchInteraction {
            device_id: 0,
            pointer_id,
            phase: TouchPhase::Add,
            position_x: x,
            position_y: y,
        };
        self.pending_interactions.lock().unwrap().push(interaction);
        
        let _ = self.sender.unbounded_send(event);
    }

    pub fn inject_touch_move(&self, x: f32, y: f32, pointer_id: u32) {
        let event = TouchEvent::Move { x, y, pointer_id };
        self.events.lock().unwrap().push(event.clone());
        
        let interaction = TouchInteraction {
            device_id: 0,
            pointer_id,
            phase: TouchPhase::Change,
            position_x: x,
            position_y: y,
        };
        self.pending_interactions.lock().unwrap().push(interaction);
        
        let _ = self.sender.unbounded_send(event);
    }

    pub fn inject_touch_up(&self, pointer_id: u32) {
        let event = TouchEvent::Up { pointer_id };
        self.events.lock().unwrap().push(event.clone());
        
        let interaction = TouchInteraction {
            device_id: 0,
            pointer_id,
            phase: TouchPhase::Remove,
            position_x: 0.0,
            position_y: 0.0,
        };
        self.pending_interactions.lock().unwrap().push(interaction);
        
        let _ = self.sender.unbounded_send(event);
    }

    pub fn watch_for_interactions(&self) -> Vec<TouchInteraction> {
        let mut pending = self.pending_interactions.lock().unwrap();
        let interactions = pending.clone();
        pending.clear();
        interactions
    }

    pub fn get_events(&self) -> Vec<TouchEvent> {
        self.events.lock().unwrap().clone()
    }

    pub fn clear_events(&self) {
        self.events.lock().unwrap().clear();
        self.pending_interactions.lock().unwrap().clear();
    }
}

impl Default for MockTouchSource {
    fn default() -> Self {
        Self::new().0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mock_touch_source_down() {
        let (touch_source, _receiver) = MockTouchSource::new();
        touch_source.inject_touch_down(100.0, 200.0, 1);
        
        let events = touch_source.get_events();
        assert_eq!(events.len(), 1);
        
        match &events[0] {
            TouchEvent::Down { x, y, pointer_id } => {
                assert_eq!(*x, 100.0);
                assert_eq!(*y, 200.0);
                assert_eq!(*pointer_id, 1);
            }
            _ => panic!("Expected TouchDown event"),
        }
    }

    #[test]
    fn test_mock_touch_source_interactions() {
        let (touch_source, _receiver) = MockTouchSource::new();
        touch_source.inject_touch_down(50.0, 75.0, 1);
        
        let interactions = touch_source.watch_for_interactions();
        assert_eq!(interactions.len(), 1);
        assert_eq!(interactions[0].phase, TouchPhase::Add);
        assert_eq!(interactions[0].position_x, 50.0);
        assert_eq!(interactions[0].position_y, 75.0);
        
        let empty = touch_source.watch_for_interactions();
        assert_eq!(empty.len(), 0);
    }

    #[test]
    fn test_mock_touch_source_gesture() {
        let (touch_source, _receiver) = MockTouchSource::new();
        touch_source.inject_touch_down(0.0, 0.0, 1);
        touch_source.inject_touch_move(10.0, 10.0, 1);
        touch_source.inject_touch_move(20.0, 20.0, 1);
        touch_source.inject_touch_up(1);
        
        let events = touch_source.get_events();
        assert_eq!(events.len(), 4);
    }
}
