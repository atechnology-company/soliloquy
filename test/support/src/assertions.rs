// Copyright 2025 The Soliloquy Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//! Common assertion helpers for Soliloquy tests

use std::time::Duration;

pub fn assert_within_tolerance(actual: f32, expected: f32, tolerance: f32) {
    let diff = (actual - expected).abs();
    assert!(
        diff <= tolerance,
        "Expected {} to be within {} of {}, but difference was {}",
        actual,
        tolerance,
        expected,
        diff
    );
}

pub fn assert_eventually<F>(mut predicate: F, timeout: Duration, check_interval: Duration)
where
    F: FnMut() -> bool,
{
    let start = std::time::Instant::now();
    
    while start.elapsed() < timeout {
        if predicate() {
            return;
        }
        std::thread::sleep(check_interval);
    }
    
    panic!(
        "Condition not met within timeout of {:?}",
        timeout
    );
}

pub fn assert_event_count<T>(events: &[T], expected_count: usize, event_type: &str) {
    assert_eq!(
        events.len(),
        expected_count,
        "Expected {} {} events, but got {}",
        expected_count,
        event_type,
        events.len()
    );
}

pub fn assert_no_events<T>(events: &[T], event_type: &str) {
    assert!(
        events.is_empty(),
        "Expected no {} events, but got {}",
        event_type,
        events.len()
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_assert_within_tolerance() {
        assert_within_tolerance(10.0, 10.0, 0.01);
        assert_within_tolerance(10.05, 10.0, 0.1);
        assert_within_tolerance(9.95, 10.0, 0.1);
    }

    #[test]
    #[should_panic(expected = "to be within")]
    fn test_assert_within_tolerance_fails() {
        assert_within_tolerance(10.5, 10.0, 0.1);
    }

    #[test]
    fn test_assert_eventually_success() {
        let mut counter = 0;
        assert_eventually(
            || {
                counter += 1;
                counter >= 3
            },
            Duration::from_secs(1),
            Duration::from_millis(10),
        );
    }

    #[test]
    #[should_panic(expected = "Condition not met")]
    fn test_assert_eventually_timeout() {
        assert_eventually(
            || false,
            Duration::from_millis(50),
            Duration::from_millis(10),
        );
    }

    #[test]
    fn test_assert_event_count() {
        let events = vec![1, 2, 3];
        assert_event_count(&events, 3, "test");
    }

    #[test]
    fn test_assert_no_events() {
        let events: Vec<i32> = vec![];
        assert_no_events(&events, "test");
    }
}
