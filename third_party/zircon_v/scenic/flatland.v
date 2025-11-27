// Zircon Flatland - Compositor FIDL bindings
//
// This module provides bindings to fuchsia.ui.composition.Flatland protocol
// for UI composition and rendering.
//
// Reference: sdk/fidl/fuchsia.ui.composition/flatland.fidl

module scenic

import ipc { ZxStatus, Channel, create_channel_pair, endpoint_0, endpoint_1, KernelObjectId }
import os

// Flatland service path
const flatland_service = 'fuchsia.ui.composition.Flatland'
const flatland_allocator_service = 'fuchsia.ui.composition.Allocator'

// Transform ID type
pub type TransformId = u64

// Content ID type
pub type ContentId = u64

// Invalid IDs
pub const invalid_transform_id = TransformId(0)
pub const invalid_content_id = ContentId(0)

// Present arguments
pub struct PresentArgs {
pub:
	requested_presentation_time i64
	acquire_fences             []KernelObjectId
	release_fences             []KernelObjectId
	unsquashable               bool
}

// Present result from Flatland
pub struct FuturePresentationTimes {
pub:
	future_presentations       []PresentationInfo
	remaining_presents_in_flight_allowed u32
}

// Presentation timing info
pub struct PresentationInfo {
pub:
	latch_point    i64
	presentation_time i64
}

// Flatland error codes
pub enum FlatlandError {
	bad_operation          = 1
	no_presents_remaining  = 2
	bad_hanging_get        = 3
}

// Blend modes for image composition
pub enum BlendMode {
	src      = 1  // Source replaces destination (opaque)
	src_over = 2  // Source over destination with alpha
}

// Image flip modes
pub enum ImageFlip {
	none       = 0
	left_right = 1
	up_down    = 2
}

// Flatland client connection
pub struct FlatlandClient {
mut:
	channel         Channel
	next_transform_id TransformId
	next_content_id ContentId
	root_transform  TransformId
	connected       bool
}

// Create a new Flatland client
pub fn FlatlandClient.new() ?FlatlandClient {
	$if fuchsia {
		service_path := '/svc/${flatland_service}'
		
		if !os.exists(service_path) {
			return none
		}
		
		// Create channel for FIDL communication
		pair := create_channel_pair(0x1000)
		
		return FlatlandClient{
			channel: pair.channel
			next_transform_id: 1
			next_content_id: 1
			root_transform: invalid_transform_id
			connected: true
		}
	} $else {
		return none
	}
}

// Check if client is connected
pub fn (c &FlatlandClient) is_connected() bool {
	return c.connected
}

// Create a new transform
pub fn (mut c FlatlandClient) create_transform() ?TransformId {
	if !c.connected {
		return none
	}
	
	id := c.next_transform_id
	c.next_transform_id++
	
	// Send CreateTransform FIDL message
	request := build_create_transform_request(id)
	status := c.channel.write(endpoint_0, request, [])
	
	if status != .ok {
		return none
	}
	
	return id
}

// Set root transform
pub fn (mut c FlatlandClient) set_root_transform(id TransformId) ZxStatus {
	if !c.connected {
		return .err_bad_state
	}
	
	c.root_transform = id
	
	// Send SetRootTransform FIDL message
	request := build_set_root_transform_request(id)
	return c.channel.write(endpoint_0, request, [])
}

// Get current layout info
pub fn (mut c FlatlandClient) get_layout() ?LayoutInfo {
	if !c.connected {
		return none
	}
	
	// Send GetLayout request
	request := build_get_layout_request()
	status := c.channel.write(endpoint_0, request, [])
	
	if status != .ok {
		return none
	}
	
	// Read response (blocking)
	response, read_status := c.channel.read(endpoint_1, false) or {
		return none
	}
	
	if read_status != .ok {
		return none
	}
	
	return parse_layout_response(response.data)
}

// Present pending changes
pub fn (mut c FlatlandClient) present(args PresentArgs) ?FuturePresentationTimes {
	if !c.connected {
		return none
	}
	
	// Build and send Present request
	request := build_present_request(args)
	status := c.channel.write(endpoint_0, request, [])
	
	if status != .ok {
		return none
	}
	
	// For now, return default timing
	// Real implementation would wait for OnNextFrameBegin event
	return FuturePresentationTimes{
		future_presentations: []
		remaining_presents_in_flight_allowed: 1
	}
}

// Close the Flatland connection
pub fn (mut c FlatlandClient) close() {
	if c.connected {
		c.channel.close_endpoint(endpoint_0)
		c.connected = false
	}
}

// Build CreateTransform FIDL request
fn build_create_transform_request(id TransformId) []u8 {
	mut request := []u8{cap: 24}
	
	// FIDL header
	request << u8(0x01) << u8(0x00) << u8(0x00) << u8(0x00)  // txid
	request << u8(0x00) << u8(0x01)  // flags + magic
	request << u8(0x00) << u8(0x00)  // reserved
	
	// Ordinal for CreateTransform
	ordinal := u64(0x1f3a_beef_0110)
	for i in 0 .. 8 {
		request << u8((ordinal >> (i * 8)) & 0xFF)
	}
	
	// TransformId payload
	for i in 0 .. 8 {
		request << u8((id >> (i * 8)) & 0xFF)
	}
	
	return request
}

// Build SetRootTransform FIDL request
fn build_set_root_transform_request(id TransformId) []u8 {
	mut request := []u8{cap: 24}
	
	// FIDL header
	request << u8(0x02) << u8(0x00) << u8(0x00) << u8(0x00)  // txid
	request << u8(0x00) << u8(0x01)  // flags + magic
	request << u8(0x00) << u8(0x00)  // reserved
	
	// Ordinal for SetRootTransform
	ordinal := fidl_flatland_set_root_transform
	for i in 0 .. 8 {
		request << u8((ordinal >> (i * 8)) & 0xFF)
	}
	
	// TransformId payload
	for i in 0 .. 8 {
		request << u8((id >> (i * 8)) & 0xFF)
	}
	
	return request
}

// Build GetLayout FIDL request
fn build_get_layout_request() []u8 {
	mut request := []u8{cap: 16}
	
	// FIDL header (no payload for GetLayout)
	request << u8(0x03) << u8(0x00) << u8(0x00) << u8(0x00)  // txid
	request << u8(0x00) << u8(0x01)  // flags + magic
	request << u8(0x00) << u8(0x00)  // reserved
	
	ordinal := fidl_flatland_get_layout
	for i in 0 .. 8 {
		request << u8((ordinal >> (i * 8)) & 0xFF)
	}
	
	return request
}

// Build Present FIDL request
fn build_present_request(args PresentArgs) []u8 {
	mut request := []u8{cap: 32}
	
	// FIDL header
	request << u8(0x04) << u8(0x00) << u8(0x00) << u8(0x00)  // txid
	request << u8(0x00) << u8(0x01)  // flags + magic
	request << u8(0x00) << u8(0x00)  // reserved
	
	ordinal := fidl_flatland_present
	for i in 0 .. 8 {
		request << u8((ordinal >> (i * 8)) & 0xFF)
	}
	
	// PresentArgs payload (simplified)
	for i in 0 .. 8 {
		request << u8((args.requested_presentation_time >> (i * 8)) & 0xFF)
	}
	
	return request
}

// Parse LayoutInfo from FIDL response
fn parse_layout_response(data []u8) ?LayoutInfo {
	if data.len < 24 {
		return none
	}
	
	// Skip FIDL header
	payload := data[16..]
	
	// Parse logical_size (2x u32)
	width := u32(payload[0]) | (u32(payload[1]) << 8) | (u32(payload[2]) << 16) | (u32(payload[3]) << 24)
	height := u32(payload[4]) | (u32(payload[5]) << 8) | (u32(payload[6]) << 16) | (u32(payload[7]) << 24)
	
	return LayoutInfo{
		logical_size: Size{
			width: width
			height: height
		}
		device_pixel_ratio: 1.0
	}
}

// Tests
fn test_flatland_client_creation() {
	// On non-Fuchsia, should return none
	$if !fuchsia {
		client := FlatlandClient.new()
		assert client == none
	}
}

fn test_build_create_transform() {
	request := build_create_transform_request(42)
	assert request.len == 24
	assert request[5] == 0x01  // FIDL magic
}

fn test_transform_ids() {
	assert invalid_transform_id == 0
	assert invalid_content_id == 0
}
