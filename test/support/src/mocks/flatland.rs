// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

use futures::channel::mpsc;
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone)]
pub enum FlatlandEvent {
    CreateTransform { transform_id: u64 },
    SetContent { transform_id: u64, content_id: u64 },
    SetTranslation { transform_id: u64, x: f32, y: f32 },
    Present { args: PresentArgs },
}

#[derive(Debug, Clone)]
pub struct PresentArgs {
    pub requested_presentation_time: i64,
    pub acquire_fences: Vec<u64>,
    pub release_fences: Vec<u64>,
}

pub struct MockFlatland {
    events: Arc<Mutex<Vec<FlatlandEvent>>>,
    present_count: Arc<Mutex<usize>>,
    sender: mpsc::UnboundedSender<FlatlandEvent>,
}

impl MockFlatland {
    pub fn new() -> (Self, mpsc::UnboundedReceiver<FlatlandEvent>) {
        let (sender, receiver) = mpsc::unbounded();
        (
            Self {
                events: Arc::new(Mutex::new(Vec::new())),
                present_count: Arc::new(Mutex::new(0)),
                sender,
            },
            receiver,
        )
    }

    pub fn create_transform(&self, transform_id: u64) {
        let event = FlatlandEvent::CreateTransform { transform_id };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn set_content(&self, transform_id: u64, content_id: u64) {
        let event = FlatlandEvent::SetContent {
            transform_id,
            content_id,
        };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn set_translation(&self, transform_id: u64, x: f32, y: f32) {
        let event = FlatlandEvent::SetTranslation {
            transform_id,
            x,
            y,
        };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn present(&self, args: PresentArgs) {
        *self.present_count.lock().unwrap() += 1;
        let event = FlatlandEvent::Present { args };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn get_events(&self) -> Vec<FlatlandEvent> {
        self.events.lock().unwrap().clone()
    }

    pub fn get_present_count(&self) -> usize {
        *self.present_count.lock().unwrap()
    }

    pub fn clear_events(&self) {
        self.events.lock().unwrap().clear();
    }
}

impl Default for MockFlatland {
    fn default() -> Self {
        Self::new().0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mock_flatland_create_transform() {
        let (flatland, _receiver) = MockFlatland::new();
        flatland.create_transform(1);
        
        let events = flatland.get_events();
        assert_eq!(events.len(), 1);
        
        match &events[0] {
            FlatlandEvent::CreateTransform { transform_id } => {
                assert_eq!(*transform_id, 1);
            }
            _ => panic!("Expected CreateTransform event"),
        }
    }

    #[test]
    fn test_mock_flatland_present() {
        let (flatland, _receiver) = MockFlatland::new();
        
        let args = PresentArgs {
            requested_presentation_time: 0,
            acquire_fences: vec![],
            release_fences: vec![],
        };
        
        flatland.present(args);
        assert_eq!(flatland.get_present_count(), 1);
    }

    #[test]
    fn test_mock_flatland_clear_events() {
        let (flatland, _receiver) = MockFlatland::new();
        flatland.create_transform(1);
        flatland.set_content(1, 2);
        
        assert_eq!(flatland.get_events().len(), 2);
        
        flatland.clear_events();
        assert_eq!(flatland.get_events().len(), 0);
    }
}
