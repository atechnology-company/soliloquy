// Stub implementation of FIDL runtime library
// This provides the basic types and traits needed for FIDL bindings

#![allow(unused)]

pub use std::os::raw::c_void;

#[derive(Debug)]
pub struct Handle;

#[derive(Debug)]
pub struct EventPair;

pub mod endpoints {
    use super::*;
    use std::marker::PhantomData;

    pub trait ProtocolMarker: Sized {
        type Proxy;
        type RequestStream;
        const DEBUG_NAME: &'static str;
    }

    pub trait DiscoverableProtocolMarker: ProtocolMarker {}
    pub trait ServiceMarker {}

    pub struct Proxy<T: ProtocolMarker> {
        _marker: PhantomData<T>,
    }

    impl<T: ProtocolMarker> std::fmt::Debug for Proxy<T> {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.debug_struct("Proxy").finish()
        }
    }

    pub struct RequestStream<T: ProtocolMarker> {
        _marker: PhantomData<T>,
    }

    impl<T: ProtocolMarker> std::fmt::Debug for RequestStream<T> {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.debug_struct("RequestStream").finish()
        }
    }

    pub struct ClientEnd<T: ProtocolMarker> {
        _marker: PhantomData<T>,
    }

    pub struct ServerEnd<T: ProtocolMarker> {
        _marker: PhantomData<T>,
    }

    pub fn create_endpoints<T: ProtocolMarker>() -> (ClientEnd<T>, ServerEnd<T>) {
        (
            ClientEnd { _marker: PhantomData },
            ServerEnd { _marker: PhantomData },
        )
    }

    pub fn create_proxy<T: ProtocolMarker>() -> (Proxy<T>, ServerEnd<T>) {
        (
            Proxy { _marker: PhantomData },
            ServerEnd { _marker: PhantomData },
        )
    }

    pub fn create_request_stream<T: ProtocolMarker>() -> (ClientEnd<T>, RequestStream<T>) {
        (
            ClientEnd { _marker: PhantomData },
            RequestStream { _marker: PhantomData },
        )
    }

    pub trait ControlHandle {}
    pub trait Responder {}
}

pub mod encoding {
    pub trait Encodable {}
    pub trait Decodable {}
}

pub mod client {
    pub struct QueryResponseFut<T> {
        _marker: std::marker::PhantomData<T>,
    }
}
