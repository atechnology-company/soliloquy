// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//! FIDL integration tests using mock servers

#[cfg(test)]
mod tests {
    use futures::StreamExt;
    use log::info;

    #[test]
    fn test_mock_flatland_basic() {
        let (flatland, mut receiver) = soliloquy_test_support::MockFlatland::new();
        
        flatland.create_transform(1);
        flatland.set_content(1, 100);
        
        let events = flatland.get_events();
        assert_eq!(events.len(), 2);
        
        info!("MockFlatland basic test passed");
    }

    #[test]
    fn test_mock_flatland_presentation() {
        let (flatland, _receiver) = soliloquy_test_support::MockFlatland::new();
        
        flatland.create_transform(1);
        let args = soliloquy_test_support::mocks::flatland::PresentArgs {
            requested_presentation_time: 0,
            acquire_fences: vec![],
            release_fences: vec![],
        };
        flatland.present(args);
        
        assert_eq!(flatland.get_present_count(), 1);
        
        info!("MockFlatland presentation test passed");
    }

    #[test]
    fn test_mock_touch_source_basic() {
        let (touch_source, mut receiver) = soliloquy_test_support::MockTouchSource::new();
        
        touch_source.inject_touch_down(100.0, 200.0, 1);
        touch_source.inject_touch_move(150.0, 250.0, 1);
        touch_source.inject_touch_up(1);
        
        let events = touch_source.get_events();
        assert_eq!(events.len(), 3);
        
        info!("MockTouchSource basic test passed");
    }

    #[test]
    fn test_mock_touch_source_interactions() {
        let (touch_source, _receiver) = soliloquy_test_support::MockTouchSource::new();
        
        touch_source.inject_touch_down(50.0, 75.0, 1);
        
        let interactions = touch_source.watch_for_interactions();
        assert_eq!(interactions.len(), 1);
        assert_eq!(interactions[0].phase, soliloquy_test_support::mocks::touch_source::TouchPhase::Add);
        
        soliloquy_test_support::assertions::assert_within_tolerance(
            interactions[0].position_x,
            50.0,
            0.01
        );
        
        info!("MockTouchSource interactions test passed");
    }

    #[test]
    fn test_mock_view_provider_basic() {
        let (view_provider, _receiver) = soliloquy_test_support::MockViewProvider::new();
        
        let token = soliloquy_test_support::mocks::view_provider::ViewCreationToken { value: 123 };
        view_provider.create_view(token);
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        
        info!("MockViewProvider basic test passed");
    }

    #[test]
    fn test_assertion_helpers() {
        use soliloquy_test_support::assertions::*;
        
        assert_within_tolerance(10.0, 10.05, 0.1);
        
        let events: Vec<i32> = vec![];
        assert_no_events(&events, "test");
        
        let events = vec![1, 2, 3];
        assert_event_count(&events, 3, "test");
        
        info!("Assertion helpers test passed");
    }

    #[test]
    fn test_complete_fidl_workflow() {
        let (flatland, _flatland_rx) = soliloquy_test_support::MockFlatland::new();
        let (touch_source, _touch_rx) = soliloquy_test_support::MockTouchSource::new();
        let (view_provider, _view_rx) = soliloquy_test_support::MockViewProvider::new();
        
        let view_token = soliloquy_test_support::mocks::view_provider::ViewCreationToken { value: 1 };
        view_provider.create_view(view_token);
        
        flatland.create_transform(1);
        flatland.set_content(1, 100);
        
        touch_source.inject_touch_down(100.0, 100.0, 1);
        touch_source.inject_touch_up(1);
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        assert_eq!(flatland.get_events().len(), 2);
        assert_eq!(touch_source.get_events().len(), 2);
        
        info!("Complete FIDL workflow test passed");
    }
}
