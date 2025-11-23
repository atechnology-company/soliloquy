// Generated bindings for fuchsia.ui.views
// To generate actual bindings, ensure Fuchsia SDK is installed
// and FIDL sources are available, then run:
//   ./tools/soliloquy/gen_fidl_bindings.sh

#![allow(unused)]

use fidl::endpoints::{ControlHandle as _, Responder as _};
pub use fidl::endpoints::{
    create_endpoints, create_proxy, create_request_stream, ClientEnd, DiscoverableProtocolMarker,
    Proxy, RequestStream, ServerEnd, ServiceMarker,
};

pub mod fidl_fuchsia_ui_views {
    use super::*;

    #[derive(Debug)]
    pub struct ViewCreationToken {
        pub value: fidl::EventPair,
    }

    impl ViewCreationToken {
        pub fn new(value: fidl::EventPair) -> Self {
            Self { value }
        }
    }

    #[derive(Debug)]
    pub struct ViewportCreationToken {
        pub value: fidl::EventPair,
    }

    impl ViewportCreationToken {
        pub fn new(value: fidl::EventPair) -> Self {
            Self { value }
        }
    }

    #[derive(Debug)]
    pub struct ViewRef {
        pub reference: fidl::EventPair,
    }

    impl ViewRef {
        pub fn new(reference: fidl::EventPair) -> Self {
            Self { reference }
        }
    }

    #[derive(Debug)]
    pub struct ViewRefControl {
        pub reference: fidl::EventPair,
    }

    #[derive(Debug)]
    pub struct ViewIdentityOnCreation {
        pub view_ref: ViewRef,
        pub view_ref_control: ViewRefControl,
    }

    #[derive(Debug, Clone, Copy)]
    pub struct ViewBoundProtocols {
        pub view_focuser: bool,
        pub view_ref_focused: bool,
        pub touch_source: bool,
        pub mouse_source: bool,
    }

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct ViewProviderMarker;
    
    impl fidl::endpoints::ProtocolMarker for ViewProviderMarker {
        type Proxy = ViewProviderProxy;
        type RequestStream = ViewProviderRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) ViewProvider";
    }

    pub type ViewProviderProxy = fidl::endpoints::Proxy<ViewProviderMarker>;
    pub type ViewProviderRequestStream = fidl::endpoints::RequestStream<ViewProviderMarker>;

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct ViewRefFocusedMarker;
    
    impl fidl::endpoints::ProtocolMarker for ViewRefFocusedMarker {
        type Proxy = ViewRefFocusedProxy;
        type RequestStream = ViewRefFocusedRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) ViewRefFocused";
    }

    pub type ViewRefFocusedProxy = fidl::endpoints::Proxy<ViewRefFocusedMarker>;
    pub type ViewRefFocusedRequestStream = fidl::endpoints::RequestStream<ViewRefFocusedMarker>;

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct FocuserMarker;
    
    impl fidl::endpoints::ProtocolMarker for FocuserMarker {
        type Proxy = FocuserProxy;
        type RequestStream = FocuserRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) Focuser";
    }

    pub type FocuserProxy = fidl::endpoints::Proxy<FocuserMarker>;
    pub type FocuserRequestStream = fidl::endpoints::RequestStream<FocuserMarker>;
}

pub use fidl_fuchsia_ui_views::*;
