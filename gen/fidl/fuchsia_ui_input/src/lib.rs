//! Fuchsia Input FIDL Protocol Implementation
//!
//! This module implements the input protocols for keyboard, mouse, and touch
//! input handling in Flatland-based applications.
//!
//! Protocols:
//! - Keyboard: Key events for text input
//! - TouchSource: Multi-touch input events
//! - MouseSource: Mouse/pointer input events

#![allow(unused)]

use std::collections::{HashMap, VecDeque};
use std::sync::{Arc, Mutex};
use std::sync::atomic::{AtomicU64, Ordering};

/// Timestamp in nanoseconds
pub type Timestamp = i64;

/// Interaction ID for input sequences
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct InteractionId(pub u64);

static NEXT_INTERACTION_ID: AtomicU64 = AtomicU64::new(1);

impl InteractionId {
    pub fn new() -> Self {
        Self(NEXT_INTERACTION_ID.fetch_add(1, Ordering::Relaxed))
    }
}

impl Default for InteractionId {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// Keyboard Input
// ============================================================================

/// Key meaning - semantic meaning of a key press
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyMeaning {
    NonPrintable(NonPrintableKey),
    Codepoint(u32),
}

/// Non-printable key types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NonPrintableKey {
    Unidentified,
    Alt,
    AltGraph,
    CapsLock,
    Control,
    Enter,
    Fn,
    FnLock,
    Meta,
    NumLock,
    ScrollLock,
    Shift,
    Symbol,
    SymbolLock,
    Hyper,
    Super,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    ArrowUp,
    End,
    Home,
    PageDown,
    PageUp,
    Backspace,
    Delete,
    Insert,
    Cancel,
    Escape,
    Execute,
    F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
    PrintScreen,
    Tab,
    ContextMenu,
}

/// Key type (pressed/released)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyEventType {
    Pressed,
    Released,
    Cancel,
    Sync,
}

/// Physical key code (USB HID)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Key(pub u32);

impl Key {
    pub const A: Key = Key(0x00070004);
    pub const B: Key = Key(0x00070005);
    pub const C: Key = Key(0x00070006);
    // ... more keys would be defined
    pub const SPACE: Key = Key(0x0007002c);
    pub const ENTER: Key = Key(0x00070028);
    pub const ESCAPE: Key = Key(0x00070029);
    pub const BACKSPACE: Key = Key(0x0007002a);
    pub const TAB: Key = Key(0x0007002b);
    pub const LEFT_CTRL: Key = Key(0x000700e0);
    pub const LEFT_SHIFT: Key = Key(0x000700e1);
    pub const LEFT_ALT: Key = Key(0x000700e2);
    pub const LEFT_META: Key = Key(0x000700e3);
    pub const RIGHT_CTRL: Key = Key(0x000700e4);
    pub const RIGHT_SHIFT: Key = Key(0x000700e5);
    pub const RIGHT_ALT: Key = Key(0x000700e6);
    pub const RIGHT_META: Key = Key(0x000700e7);
}

/// Modifiers state
#[derive(Debug, Clone, Copy, Default)]
pub struct Modifiers {
    pub caps_lock: bool,
    pub num_lock: bool,
    pub scroll_lock: bool,
    pub function: bool,
    pub symbol: bool,
    pub shift: bool,
    pub alt: bool,
    pub alt_graph: bool,
    pub meta: bool,
    pub ctrl: bool,
}

impl Modifiers {
    pub fn is_none(&self) -> bool {
        !self.shift && !self.alt && !self.meta && !self.ctrl
    }

    pub fn to_bits(&self) -> u32 {
        let mut bits = 0u32;
        if self.caps_lock { bits |= 1 << 0; }
        if self.num_lock { bits |= 1 << 1; }
        if self.scroll_lock { bits |= 1 << 2; }
        if self.shift { bits |= 1 << 5; }
        if self.alt { bits |= 1 << 6; }
        if self.meta { bits |= 1 << 7; }
        if self.ctrl { bits |= 1 << 8; }
        bits
    }
}

/// Keyboard event
#[derive(Debug, Clone)]
pub struct KeyEvent {
    pub timestamp: Timestamp,
    pub event_type: KeyEventType,
    pub key: Option<Key>,
    pub key_meaning: Option<KeyMeaning>,
    pub modifiers: Modifiers,
    pub repeat_sequence: u32,
    pub lock_state: Modifiers,
}

impl KeyEvent {
    pub fn new(event_type: KeyEventType, key: Key) -> Self {
        Self {
            timestamp: 0, // Would use monotonic clock
            event_type,
            key: Some(key),
            key_meaning: None,
            modifiers: Modifiers::default(),
            repeat_sequence: 0,
            lock_state: Modifiers::default(),
        }
    }

    pub fn is_pressed(&self) -> bool {
        self.event_type == KeyEventType::Pressed
    }

    pub fn is_modifier_key(&self) -> bool {
        if let Some(key) = self.key {
            matches!(key, 
                Key::LEFT_CTRL | Key::RIGHT_CTRL |
                Key::LEFT_SHIFT | Key::RIGHT_SHIFT |
                Key::LEFT_ALT | Key::RIGHT_ALT |
                Key::LEFT_META | Key::RIGHT_META
            )
        } else {
            false
        }
    }
}

/// Keyboard listener - receives key events
pub struct KeyboardListener {
    events: VecDeque<KeyEvent>,
    modifiers: Modifiers,
    max_queue_size: usize,
}

impl KeyboardListener {
    pub fn new() -> Self {
        Self {
            events: VecDeque::with_capacity(64),
            modifiers: Modifiers::default(),
            max_queue_size: 256,
        }
    }

    pub fn push_event(&mut self, event: KeyEvent) {
        // Update modifier state
        self.update_modifiers(&event);
        
        if self.events.len() >= self.max_queue_size {
            self.events.pop_front();
        }
        self.events.push_back(event);
    }

    fn update_modifiers(&mut self, event: &KeyEvent) {
        let pressed = event.is_pressed();
        if let Some(key) = event.key {
            match key {
                Key::LEFT_CTRL | Key::RIGHT_CTRL => self.modifiers.ctrl = pressed,
                Key::LEFT_SHIFT | Key::RIGHT_SHIFT => self.modifiers.shift = pressed,
                Key::LEFT_ALT | Key::RIGHT_ALT => self.modifiers.alt = pressed,
                Key::LEFT_META | Key::RIGHT_META => self.modifiers.meta = pressed,
                _ => {}
            }
        }
    }

    pub fn pop_event(&mut self) -> Option<KeyEvent> {
        self.events.pop_front()
    }

    pub fn get_modifiers(&self) -> Modifiers {
        self.modifiers
    }

    pub fn pending_count(&self) -> usize {
        self.events.len()
    }
}

impl Default for KeyboardListener {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// Touch Input
// ============================================================================

/// Touch interaction status
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TouchInteractionStatus {
    Denied,
    Granted,
}

/// Touch interaction result
#[derive(Debug, Clone, Copy)]
pub struct TouchInteractionResult {
    pub interaction_id: InteractionId,
    pub status: TouchInteractionStatus,
}

/// Touch pointer sample (single finger position)
#[derive(Debug, Clone, Copy)]
pub struct TouchPointerSample {
    pub interaction_id: InteractionId,
    pub phase: TouchPhase,
    pub position_in_viewport: [f32; 2],
}

impl TouchPointerSample {
    pub fn new(id: InteractionId, phase: TouchPhase, x: f32, y: f32) -> Self {
        Self {
            interaction_id: id,
            phase,
            position_in_viewport: [x, y],
        }
    }

    pub fn x(&self) -> f32 {
        self.position_in_viewport[0]
    }

    pub fn y(&self) -> f32 {
        self.position_in_viewport[1]
    }
}

/// Touch phase
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TouchPhase {
    Add,    // Finger touched
    Change, // Finger moved
    Remove, // Finger lifted
    Cancel, // Touch cancelled
}

/// Touch event with multiple pointers
#[derive(Debug, Clone)]
pub struct TouchEvent {
    pub timestamp: Timestamp,
    pub trace_flow_id: u64,
    pub pointer_sample: Option<TouchPointerSample>,
    pub interaction_result: Option<TouchInteractionResult>,
    pub view_parameters: Option<ViewParameters>,
}

impl TouchEvent {
    pub fn new(sample: TouchPointerSample) -> Self {
        Self {
            timestamp: 0,
            trace_flow_id: 0,
            pointer_sample: Some(sample),
            interaction_result: None,
            view_parameters: None,
        }
    }
}

/// View parameters for coordinate conversion
#[derive(Debug, Clone, Copy)]
pub struct ViewParameters {
    pub view_size: [f32; 2],
    pub viewport_to_view_transform: [f32; 9], // 3x3 matrix row-major
}

impl ViewParameters {
    pub fn identity(width: f32, height: f32) -> Self {
        Self {
            view_size: [width, height],
            viewport_to_view_transform: [
                1.0, 0.0, 0.0,
                0.0, 1.0, 0.0,
                0.0, 0.0, 1.0,
            ],
        }
    }

    pub fn transform_point(&self, x: f32, y: f32) -> (f32, f32) {
        let m = &self.viewport_to_view_transform;
        let new_x = m[0] * x + m[1] * y + m[2];
        let new_y = m[3] * x + m[4] * y + m[5];
        (new_x, new_y)
    }
}

/// Touch response for event acknowledgment
#[derive(Debug, Clone, Copy)]
pub struct TouchResponse {
    pub response_type: TouchResponseType,
    pub trace_flow_id: u64,
}

/// Touch response type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TouchResponseType {
    Yes,     // Will handle this touch
    YesPrioritize, // Will handle and wants priority
    Maybe,   // Might handle
    MaybePrioritize, // Might handle, wants priority if so
    MaybePrioritizeSuppress, // Might handle, suppress if not
    No,      // Will not handle
    Hold,    // Need more info
    HoldSuppress, // Need more info, suppress if not granted
}

/// Touch source - provides touch events to a view
pub struct TouchSource {
    view_ref_koid: u64,
    events: VecDeque<TouchEvent>,
    active_interactions: HashMap<InteractionId, TouchPhase>,
    view_parameters: Option<ViewParameters>,
}

impl TouchSource {
    pub fn new(view_ref_koid: u64) -> Self {
        Self {
            view_ref_koid,
            events: VecDeque::with_capacity(64),
            active_interactions: HashMap::new(),
            view_parameters: None,
        }
    }

    pub fn set_view_parameters(&mut self, params: ViewParameters) {
        self.view_parameters = Some(params);
    }

    pub fn inject_event(&mut self, sample: TouchPointerSample) {
        // Track interaction state
        match sample.phase {
            TouchPhase::Add => {
                self.active_interactions.insert(sample.interaction_id, sample.phase);
            }
            TouchPhase::Remove | TouchPhase::Cancel => {
                self.active_interactions.remove(&sample.interaction_id);
            }
            TouchPhase::Change => {
                self.active_interactions.insert(sample.interaction_id, sample.phase);
            }
        }

        let event = TouchEvent {
            timestamp: 0,
            trace_flow_id: 0,
            pointer_sample: Some(sample),
            interaction_result: None,
            view_parameters: self.view_parameters,
        };
        self.events.push_back(event);
    }

    /// Watch for touch events (returns batch)
    pub fn watch(&mut self) -> Vec<TouchEvent> {
        self.events.drain(..).collect()
    }

    /// Update response for touch events
    pub fn update_response(&mut self, _interaction: InteractionId, _response: TouchResponse) {
        // In real impl, this would participate in gesture disambiguation
    }

    pub fn active_touches(&self) -> usize {
        self.active_interactions.len()
    }
}

// ============================================================================
// Mouse Input
// ============================================================================

/// Mouse button state
#[derive(Debug, Clone, Copy, Default)]
pub struct MouseButtons {
    pub primary: bool,   // Left
    pub secondary: bool, // Right
    pub tertiary: bool,  // Middle
}

impl MouseButtons {
    pub fn any_pressed(&self) -> bool {
        self.primary || self.secondary || self.tertiary
    }

    pub fn to_bits(&self) -> u32 {
        let mut bits = 0u32;
        if self.primary { bits |= 1; }
        if self.secondary { bits |= 2; }
        if self.tertiary { bits |= 4; }
        bits
    }
}

/// Mouse event phase
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MousePhase {
    Move,
    Down,
    Up,
    Wheel,
    Cancel,
}

/// Mouse pointer sample
#[derive(Debug, Clone, Copy)]
pub struct MousePointerSample {
    pub device_id: u32,
    pub position_in_viewport: [f32; 2],
    pub scroll_v: i64,
    pub scroll_h: i64,
    pub scroll_v_physical_pixel: Option<f64>,
    pub scroll_h_physical_pixel: Option<f64>,
    pub is_precision_scroll: Option<bool>,
    pub pressed_buttons: MouseButtons,
    pub relative_motion: Option<[f32; 2]>,
}

impl MousePointerSample {
    pub fn new(x: f32, y: f32) -> Self {
        Self {
            device_id: 0,
            position_in_viewport: [x, y],
            scroll_v: 0,
            scroll_h: 0,
            scroll_v_physical_pixel: None,
            scroll_h_physical_pixel: None,
            is_precision_scroll: None,
            pressed_buttons: MouseButtons::default(),
            relative_motion: None,
        }
    }

    pub fn x(&self) -> f32 {
        self.position_in_viewport[0]
    }

    pub fn y(&self) -> f32 {
        self.position_in_viewport[1]
    }
}

/// Mouse event
#[derive(Debug, Clone)]
pub struct MouseEvent {
    pub timestamp: Timestamp,
    pub trace_flow_id: u64,
    pub pointer_sample: Option<MousePointerSample>,
    pub view_parameters: Option<ViewParameters>,
    pub device_info: Option<MouseDeviceInfo>,
    pub stream_info: Option<MouseEventStreamInfo>,
}

impl MouseEvent {
    pub fn new(sample: MousePointerSample) -> Self {
        Self {
            timestamp: 0,
            trace_flow_id: 0,
            pointer_sample: Some(sample),
            view_parameters: None,
            device_info: None,
            stream_info: None,
        }
    }
}

/// Mouse device info
#[derive(Debug, Clone, Copy)]
pub struct MouseDeviceInfo {
    pub id: u32,
    pub buttons: u32, // Bitmask of available buttons
    pub has_scroll_v: bool,
    pub has_scroll_h: bool,
}

/// Mouse event stream info
#[derive(Debug, Clone, Copy)]
pub struct MouseEventStreamInfo {
    pub device_id: u32,
    pub status: MouseViewStatus,
}

/// Mouse view status
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MouseViewStatus {
    Entered,
    Exited,
}

/// Mouse source - provides mouse events to a view
pub struct MouseSource {
    view_ref_koid: u64,
    events: VecDeque<MouseEvent>,
    view_parameters: Option<ViewParameters>,
    last_position: Option<[f32; 2]>,
    buttons: MouseButtons,
}

impl MouseSource {
    pub fn new(view_ref_koid: u64) -> Self {
        Self {
            view_ref_koid,
            events: VecDeque::with_capacity(64),
            view_parameters: None,
            last_position: None,
            buttons: MouseButtons::default(),
        }
    }

    pub fn set_view_parameters(&mut self, params: ViewParameters) {
        self.view_parameters = Some(params);
    }

    pub fn inject_event(&mut self, sample: MousePointerSample) {
        self.buttons = sample.pressed_buttons;
        self.last_position = Some(sample.position_in_viewport);

        let event = MouseEvent {
            timestamp: 0,
            trace_flow_id: 0,
            pointer_sample: Some(sample),
            view_parameters: self.view_parameters,
            device_info: None,
            stream_info: None,
        };
        self.events.push_back(event);
    }

    /// Watch for mouse events
    pub fn watch(&mut self) -> Vec<MouseEvent> {
        self.events.drain(..).collect()
    }

    pub fn get_position(&self) -> Option<[f32; 2]> {
        self.last_position
    }

    pub fn get_buttons(&self) -> MouseButtons {
        self.buttons
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keyboard_event() {
        let event = KeyEvent::new(KeyEventType::Pressed, Key::A);
        assert!(event.is_pressed());
        assert!(!event.is_modifier_key());
        
        let modifier_event = KeyEvent::new(KeyEventType::Pressed, Key::LEFT_CTRL);
        assert!(modifier_event.is_modifier_key());
    }

    #[test]
    fn test_keyboard_listener() {
        let mut listener = KeyboardListener::new();
        
        let event = KeyEvent::new(KeyEventType::Pressed, Key::LEFT_SHIFT);
        listener.push_event(event);
        
        assert!(listener.get_modifiers().shift);
        
        let release = KeyEvent::new(KeyEventType::Released, Key::LEFT_SHIFT);
        listener.push_event(release);
        
        assert!(!listener.get_modifiers().shift);
    }

    #[test]
    fn test_touch_source() {
        let mut source = TouchSource::new(100);
        
        let id = InteractionId::new();
        let sample = TouchPointerSample::new(id, TouchPhase::Add, 100.0, 200.0);
        source.inject_event(sample);
        
        assert_eq!(source.active_touches(), 1);
        
        let events = source.watch();
        assert_eq!(events.len(), 1);
        
        let remove = TouchPointerSample::new(id, TouchPhase::Remove, 100.0, 200.0);
        source.inject_event(remove);
        
        assert_eq!(source.active_touches(), 0);
    }

    #[test]
    fn test_mouse_source() {
        let mut source = MouseSource::new(100);
        
        let mut sample = MousePointerSample::new(150.0, 250.0);
        sample.pressed_buttons.primary = true;
        source.inject_event(sample);
        
        assert!(source.get_buttons().primary);
        assert_eq!(source.get_position(), Some([150.0, 250.0]));
    }

    #[test]
    fn test_view_parameters_transform() {
        let params = ViewParameters {
            view_size: [800.0, 600.0],
            viewport_to_view_transform: [
                2.0, 0.0, 10.0,
                0.0, 2.0, 20.0,
                0.0, 0.0, 1.0,
            ],
        };
        
        let (x, y) = params.transform_point(50.0, 100.0);
        assert_eq!(x, 110.0); // 2*50 + 10
        assert_eq!(y, 220.0); // 2*100 + 20
    }

    #[test]
    fn test_modifiers() {
        let mut mods = Modifiers::default();
        assert!(mods.is_none());
        
        mods.ctrl = true;
        mods.shift = true;
        assert!(!mods.is_none());
        
        let bits = mods.to_bits();
        assert!(bits & (1 << 5) != 0); // shift
        assert!(bits & (1 << 8) != 0); // ctrl
    }
}
