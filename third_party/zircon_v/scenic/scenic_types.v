// Zircon Scenic Types - Core type definitions for UI composition
//
// This module defines the types used by Scenic display and composition services.
// Based on fuchsia.ui.display.singleton and fuchsia.ui.composition FIDL protocols.
//
// Reference: sdk/fidl/fuchsia.ui.display.singleton/info.fidl
//            sdk/fidl/fuchsia.ui.composition/flatland.fidl

module scenic

import ipc { ZxStatus }

// Display metrics from fuchsia.ui.display.singleton.Metrics
pub struct DisplayMetrics {
pub:
	// Physical display resolution in pixels
	extent_in_px_width  u32
	extent_in_px_height u32
	// Physical display size in millimeters
	extent_in_mm_width  u32
	extent_in_mm_height u32
	// Recommended device pixel ratio (for logical to physical pixel mapping)
	recommended_dpr_x   f32
	recommended_dpr_y   f32
	// Maximum refresh rate in millihertz (1000 = 1 Hz)
	max_refresh_rate_mhz u32
}

// Display connection types
pub enum DisplayConnection {
	none      = 0  // No display connected
	hdmi      = 1  // HDMI connection
	dp        = 2  // DisplayPort
	dsi       = 3  // DSI (Mobile Interface)
	edp       = 4  // Embedded DisplayPort
	lvds      = 5  // LVDS
	internal  = 6  // Internal/built-in display
	virtual_  = 7  // Virtual/software display
}

// Display state from Scenic perspective
pub enum DisplayState {
	disconnected = 0
	connected    = 1
	active       = 2  // Display is rendering
	standby      = 3  // Display connected but in power save
}

// Complete display information
pub struct DisplayInfo {
pub:
	// Unique display ID (from /dev/class/display/<id>)
	id               u64
	// Display name from EDID or driver
	name             string
	// Connection type
	connection       DisplayConnection
	// Current state
	state            DisplayState
	// Display metrics
	metrics          DisplayMetrics
	// Whether display is primary
	is_primary       bool
	// Whether display supports hardware composition
	supports_composition bool
}

// Display query result
pub enum DisplayQueryResult {
	success            = 0
	no_displays        = 1
	service_unavailable = 2
	permission_denied  = 3
	internal_error     = 4
}

// Convert ZxStatus to DisplayQueryResult
pub fn status_to_query_result(status ZxStatus) DisplayQueryResult {
	return match status {
		.ok { .success }
		.err_not_found { .no_displays }
		.err_unavailable { .service_unavailable }
		.err_access_denied { .permission_denied }
		else { .internal_error }
	}
}

// FIDL ordinals for fuchsia.ui.display.singleton.Info protocol
pub const fidl_display_info_get_metrics = u64(0x1f3a_beef_0001)

// FIDL ordinals for fuchsia.ui.composition.Flatland protocol
pub const fidl_flatland_present = u64(0x1f3a_beef_0100)
pub const fidl_flatland_create_view = u64(0x1f3a_beef_0101)
pub const fidl_flatland_set_root_transform = u64(0x1f3a_beef_0102)
pub const fidl_flatland_get_layout = u64(0x1f3a_beef_0103)

// Size type for display dimensions
pub struct Size {
pub:
	width  u32
	height u32
}

// Layout info from Flatland
pub struct LayoutInfo {
pub:
	// Logical size in pixels (may differ from physical due to DPR)
	logical_size Size
	// Device pixel ratio
	device_pixel_ratio f32
}

// Orientation for display content
pub enum Orientation {
	ccw_0_degrees   = 1
	ccw_90_degrees  = 2
	ccw_180_degrees = 3
	ccw_270_degrees = 4
}

// Create default metrics (1080p 60Hz as fallback)
pub fn DisplayMetrics.default_1080p() DisplayMetrics {
	return DisplayMetrics{
		extent_in_px_width: 1920
		extent_in_px_height: 1080
		extent_in_mm_width: 527   // ~24" diagonal at 16:9
		extent_in_mm_height: 296
		recommended_dpr_x: 1.0
		recommended_dpr_y: 1.0
		max_refresh_rate_mhz: 60000  // 60 Hz
	}
}

// Create metrics for Radxa Cubie A5E (typical 7" display)
pub fn DisplayMetrics.radxa_cubie_7inch() DisplayMetrics {
	return DisplayMetrics{
		extent_in_px_width: 1024
		extent_in_px_height: 600
		extent_in_mm_width: 154   // ~7" diagonal
		extent_in_mm_height: 90
		recommended_dpr_x: 1.0
		recommended_dpr_y: 1.0
		max_refresh_rate_mhz: 60000
	}
}

// Tests
fn test_display_metrics_default() {
	m := DisplayMetrics.default_1080p()
	assert m.extent_in_px_width == 1920
	assert m.extent_in_px_height == 1080
	assert m.max_refresh_rate_mhz == 60000
}

fn test_status_conversion() {
	assert status_to_query_result(.ok) == .success
	assert status_to_query_result(.err_not_found) == .no_displays
	assert status_to_query_result(.err_unavailable) == .service_unavailable
}

fn test_display_connection_enum() {
	assert int(DisplayConnection.none) == 0
	assert int(DisplayConnection.hdmi) == 1
	assert int(DisplayConnection.dsi) == 3
}
