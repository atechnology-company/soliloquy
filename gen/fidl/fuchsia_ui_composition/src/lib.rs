// Generated bindings for fuchsia.ui.composition
// To generate actual bindings, ensure Fuchsia SDK is installed
// and FIDL sources are available, then run:
//   ./tools/soliloquy/gen_fidl_bindings.sh

#![allow(unused)]

use fidl::endpoints::{ControlHandle as _, Responder as _};
pub use fidl::endpoints::{
    create_endpoints, create_proxy, create_request_stream, ClientEnd, DiscoverableProtocolMarker,
    Proxy, RequestStream, ServerEnd, ServiceMarker,
};

pub mod fidl_fuchsia_ui_composition {
    use super::*;
    use fidl::encoding::{Decodable, Encodable};

    pub const MAX_TRANSFORM_CHILDREN: u32 = 64;
    pub const MAX_CONTENT_SIZE: u64 = 1024 * 1024;

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct FlatlandMarker;
    
    impl fidl::endpoints::ProtocolMarker for FlatlandMarker {
        type Proxy = FlatlandProxy;
        type RequestStream = FlatlandRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) Flatland";
    }

    pub type FlatlandProxy = fidl::endpoints::Proxy<FlatlandMarker>;
    pub type FlatlandRequestStream = fidl::endpoints::RequestStream<FlatlandMarker>;

    #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
    #[repr(transparent)]
    pub struct TransformId {
        pub value: u64,
    }

    impl TransformId {
        pub fn new(value: u64) -> Self {
            Self { value }
        }
    }

    #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
    #[repr(transparent)]
    pub struct ContentId {
        pub value: u64,
    }

    impl ContentId {
        pub fn new(value: u64) -> Self {
            Self { value }
        }
    }

    #[derive(Debug, Clone)]
    pub struct ImageProperties {
        pub size: Vec2,
    }

    #[derive(Debug, Clone, Copy)]
    pub struct Vec2 {
        pub x: f32,
        pub y: f32,
    }

    impl Vec2 {
        pub fn new(x: f32, y: f32) -> Self {
            Self { x, y }
        }
    }

    #[derive(Debug, Clone, Copy)]
    pub struct ColorRgba {
        pub red: f32,
        pub green: f32,
        pub blue: f32,
        pub alpha: f32,
    }

    #[derive(Debug, Clone, Copy)]
    pub struct PresentArgs {
        pub requested_presentation_time: i64,
        pub acquire_fences: u32,
        pub release_fences: u32,
        pub unsquashable: bool,
    }

    #[derive(Debug, Clone)]
    pub enum FlatlandError {
        BadOperation,
        NoPresent,
    }

    #[derive(Debug, Copy, Clone, Eq, PartialEq, Ord, PartialOrd, Hash)]
    pub struct AllocatorMarker;
    
    impl fidl::endpoints::ProtocolMarker for AllocatorMarker {
        type Proxy = AllocatorProxy;
        type RequestStream = AllocatorRequestStream;
        const DEBUG_NAME: &'static str = "(anonymous) Allocator";
    }

    pub type AllocatorProxy = fidl::endpoints::Proxy<AllocatorMarker>;
    pub type AllocatorRequestStream = fidl::endpoints::RequestStream<AllocatorMarker>;

    #[derive(Debug)]
    pub struct BufferCollectionExportToken {
        pub value: fidl::Handle,
    }

    #[derive(Debug)]
    pub struct BufferCollectionImportToken {
        pub value: fidl::Handle,
    }
}

pub use fidl_fuchsia_ui_composition::*;
