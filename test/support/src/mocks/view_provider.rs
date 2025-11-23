// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

use futures::channel::mpsc;
use std::sync::{Arc, Mutex};

#[derive(Debug, Clone)]
pub struct ViewCreationToken {
    pub value: u64,
}

#[derive(Debug, Clone)]
pub struct ViewportCreationToken {
    pub value: u64,
}

#[derive(Debug, Clone)]
pub enum ViewProviderEvent {
    CreateView {
        view_creation_token: ViewCreationToken,
    },
    CreateView2 {
        view_creation_token: ViewCreationToken,
        viewport_creation_token: ViewportCreationToken,
    },
}

pub struct MockViewProvider {
    events: Arc<Mutex<Vec<ViewProviderEvent>>>,
    view_created_count: Arc<Mutex<usize>>,
    sender: mpsc::UnboundedSender<ViewProviderEvent>,
}

impl MockViewProvider {
    pub fn new() -> (Self, mpsc::UnboundedReceiver<ViewProviderEvent>) {
        let (sender, receiver) = mpsc::unbounded();
        (
            Self {
                events: Arc::new(Mutex::new(Vec::new())),
                view_created_count: Arc::new(Mutex::new(0)),
                sender,
            },
            receiver,
        )
    }

    pub fn create_view(&self, view_creation_token: ViewCreationToken) {
        *self.view_created_count.lock().unwrap() += 1;
        let event = ViewProviderEvent::CreateView {
            view_creation_token,
        };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn create_view2(
        &self,
        view_creation_token: ViewCreationToken,
        viewport_creation_token: ViewportCreationToken,
    ) {
        *self.view_created_count.lock().unwrap() += 1;
        let event = ViewProviderEvent::CreateView2 {
            view_creation_token,
            viewport_creation_token,
        };
        self.events.lock().unwrap().push(event.clone());
        let _ = self.sender.unbounded_send(event);
    }

    pub fn get_events(&self) -> Vec<ViewProviderEvent> {
        self.events.lock().unwrap().clone()
    }

    pub fn get_view_created_count(&self) -> usize {
        *self.view_created_count.lock().unwrap()
    }

    pub fn clear_events(&self) {
        self.events.lock().unwrap().clear();
    }
}

impl Default for MockViewProvider {
    fn default() -> Self {
        Self::new().0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mock_view_provider_create_view() {
        let (view_provider, _receiver) = MockViewProvider::new();
        
        let token = ViewCreationToken { value: 123 };
        view_provider.create_view(token);
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        
        let events = view_provider.get_events();
        assert_eq!(events.len(), 1);
        
        match &events[0] {
            ViewProviderEvent::CreateView { view_creation_token } => {
                assert_eq!(view_creation_token.value, 123);
            }
            _ => panic!("Expected CreateView event"),
        }
    }

    #[test]
    fn test_mock_view_provider_create_view2() {
        let (view_provider, _receiver) = MockViewProvider::new();
        
        let view_token = ViewCreationToken { value: 456 };
        let viewport_token = ViewportCreationToken { value: 789 };
        
        view_provider.create_view2(view_token, viewport_token);
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        
        let events = view_provider.get_events();
        assert_eq!(events.len(), 1);
        
        match &events[0] {
            ViewProviderEvent::CreateView2 {
                view_creation_token,
                viewport_creation_token,
            } => {
                assert_eq!(view_creation_token.value, 456);
                assert_eq!(viewport_creation_token.value, 789);
            }
            _ => panic!("Expected CreateView2 event"),
        }
    }

    #[test]
    fn test_mock_view_provider_multiple_views() {
        let (view_provider, _receiver) = MockViewProvider::new();
        
        view_provider.create_view(ViewCreationToken { value: 1 });
        view_provider.create_view(ViewCreationToken { value: 2 });
        view_provider.create_view(ViewCreationToken { value: 3 });
        
        assert_eq!(view_provider.get_view_created_count(), 3);
        assert_eq!(view_provider.get_events().len(), 3);
    }
}
