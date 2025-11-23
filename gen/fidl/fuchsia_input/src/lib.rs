// Generated bindings for fuchsia.input
// To generate actual bindings, ensure Fuchsia SDK is installed
// and FIDL sources are available, then run:
//   ./tools/soliloquy/gen_fidl_bindings.sh

#![allow(unused)]

use fidl::endpoints::{ControlHandle as _, Responder as _};
pub use fidl::endpoints::{
    create_endpoints, create_proxy, create_request_stream, ClientEnd, DiscoverableProtocolMarker,
    Proxy, RequestStream, ServerEnd, ServiceMarker,
};

pub mod fidl_fuchsia_input {
    use super::*;

    pub const MAX_EVENT_COUNT: u32 = 128;

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum Key {
        A = 4,
        B = 5,
        C = 6,
        D = 7,
        E = 8,
        F = 9,
        Escape = 41,
        Enter = 40,
        Space = 44,
        LeftShift = 225,
        LeftCtrl = 224,
        LeftAlt = 226,
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum EventPhase {
        Add = 0,
        Change = 1,
        Remove = 2,
        Cancel = 3,
    }

    #[derive(Debug, Clone)]
    pub struct KeyEvent {
        pub timestamp: i64,
        pub key: Key,
        pub phase: EventPhase,
        pub modifiers: u32,
    }

    #[derive(Debug, Clone, Copy)]
    pub struct PointerEvent {
        pub timestamp: i64,
        pub x: f32,
        pub y: f32,
        pub phase: EventPhase,
        pub pointer_id: u32,
    }

    #[derive(Debug, Clone, Copy)]
    pub struct TouchEvent {
        pub timestamp: i64,
        pub x: f32,
        pub y: f32,
        pub phase: EventPhase,
        pub touch_id: u32,
    }

    #[derive(Debug, Clone)]
    pub enum InputEvent {
        Key(KeyEvent),
        Pointer(PointerEvent),
        Touch(TouchEvent),
    }

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct KeyboardMarker;
    
    impl fidl::endpoints::ProtocolMarker for KeyboardMarker {
        type Proxy = KeyboardProxy;
        type RequestStream = KeyboardRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) Keyboard";
    }

    pub type KeyboardProxy = fidl::endpoints::Proxy<KeyboardMarker>;
    pub type KeyboardRequestStream = fidl::endpoints::RequestStream<KeyboardMarker>;

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct MouseMarker;
    
    impl fidl::endpoints::ProtocolMarker for MouseMarker {
        type Proxy = MouseProxy;
        type RequestStream = MouseRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) Mouse";
    }

    pub type MouseProxy = fidl::endpoints::Proxy<MouseMarker>;
    pub type MouseRequestStream = fidl::endpoints::RequestStream<MouseMarker>;

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct TouchSourceMarker;
    
    impl fidl::endpoints::ProtocolMarker for TouchSourceMarker {
        type Proxy = TouchSourceProxy;
        type RequestStream = TouchSourceRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) TouchSource";
    }

    pub type TouchSourceProxy = fidl::endpoints::Proxy<TouchSourceMarker>;
    pub type TouchSourceRequestStream = fidl::endpoints::RequestStream<TouchSourceMarker>;
}

pub use fidl_fuchsia_input::*;
