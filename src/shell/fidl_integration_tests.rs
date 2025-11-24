

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

    #[test]
    fn test_shell_with_mock_view_provider() {
        let (view_provider, _view_rx) = soliloquy_test_support::MockViewProvider::new();
        let (flatland, _flatland_rx) = soliloquy_test_support::MockFlatland::new();
        
        let view_token = soliloquy_test_support::mocks::view_provider::ViewCreationToken { value: 42 };
        let viewport_token = soliloquy_test_support::mocks::view_provider::ViewportCreationToken { value: 100 };
        
        view_provider.create_view2(view_token.clone(), viewport_token.clone());
        
        let events = view_provider.get_events();
        assert_eq!(events.len(), 1);
        
        match &events[0] {
            soliloquy_test_support::mocks::view_provider::ViewProviderEvent::CreateView2 {
                view_creation_token,
                viewport_creation_token,
            } => {
                assert_eq!(view_creation_token.value, 42);
                assert_eq!(viewport_creation_token.value, 100);
            }
            _ => panic!("Expected CreateView2 event"),
        }
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        
        info!("Shell with mock ViewProvider test passed");
    }

    #[test]
    fn test_view_provider_flatland_handshake() {
        let (view_provider, _view_rx) = soliloquy_test_support::MockViewProvider::new();
        let (flatland, _flatland_rx) = soliloquy_test_support::MockFlatland::new();
        
        let view_token = soliloquy_test_support::mocks::view_provider::ViewCreationToken { value: 123 };
        let viewport_token = soliloquy_test_support::mocks::view_provider::ViewportCreationToken { value: 456 };
        
        view_provider.create_view2(view_token, viewport_token);
        
        flatland.create_transform(1);
        flatland.set_content(1, 200);
        
        let present_args = soliloquy_test_support::mocks::flatland::PresentArgs {
            requested_presentation_time: 0,
            acquire_fences: vec![],
            release_fences: vec![],
        };
        flatland.present(present_args);
        
        assert_eq!(view_provider.get_view_created_count(), 1);
        assert_eq!(flatland.get_present_count(), 1);
        
        let flatland_events = flatland.get_events();
        assert_eq!(flatland_events.len(), 2);
        
        info!("ViewProvider/Flatland handshake test passed");
    }

    #[test]
    fn test_multiple_view_provider_calls() {
        let (view_provider, _view_rx) = soliloquy_test_support::MockViewProvider::new();
        
        for i in 0..5 {
            let view_token = soliloquy_test_support::mocks::view_provider::ViewCreationToken { value: i };
            let viewport_token = soliloquy_test_support::mocks::view_provider::ViewportCreationToken { value: i + 100 };
            view_provider.create_view2(view_token, viewport_token);
        }
        
        assert_eq!(view_provider.get_view_created_count(), 5);
        assert_eq!(view_provider.get_events().len(), 5);
        
        info!("Multiple ViewProvider calls test passed");
    }

    #[test]
    fn test_flatland_connection_observable() {
        let (flatland, _flatland_rx) = soliloquy_test_support::MockFlatland::new();
        
        flatland.create_transform(1);
        flatland.create_transform(2);
        flatland.set_content(1, 300);
        
        let events = flatland.get_events();
        assert_eq!(events.len(), 3);
        
        let present_args = soliloquy_test_support::mocks::flatland::PresentArgs {
            requested_presentation_time: 1000,
            acquire_fences: vec![],
            release_fences: vec![],
        };
        flatland.present(present_args);
        
        assert_eq!(flatland.get_present_count(), 1);
        
        info!("Flatland connection observable test passed");
    }
}
