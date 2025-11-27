//! WLAN (Wireless LAN) FIDL Protocol Implementation for Fuchsia
//!
//! This module implements the WLAN PHY and MAC protocols used by WiFi drivers
//! to interface with the Fuchsia networking stack.
//!
//! Protocols:
//! - WlanPhyImpl: Physical layer interface for hardware capabilities
//! - WlanSoftmacBridge: MAC layer interface for frame transmission/reception

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

/// MAC address type
pub type MacAddress = [u8; 6];

/// Result type using Zircon status
pub type ZxResult<T> = Result<T, i32>;

const ZX_OK: i32 = 0;
const ZX_ERR_NOT_SUPPORTED: i32 = -25;
const ZX_ERR_INVALID_ARGS: i32 = -10;
const ZX_ERR_BAD_STATE: i32 = -20;

/// WiFi band
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WlanBand {
    TwoGhz = 0,
    FiveGhz = 1,
}

/// PHY type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WlanPhyType {
    Dsss = 0,
    Hr = 1,
    Ofdm = 2,
    Erp = 3,
    Ht = 4,
    Dmg = 5,
    Vht = 6,
    Tvht = 7,
    S1g = 8,
    He = 9,
}

/// MAC role
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WlanMacRole {
    Client = 0,
    Ap = 1,
    Mesh = 2,
}

/// Channel bandwidth
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChannelBandwidth {
    Cbw20 = 0,
    Cbw40 = 1,
    Cbw40Below = 2,
    Cbw80 = 3,
    Cbw160 = 4,
    Cbw80P80 = 5,
}

/// Channel specification
#[derive(Debug, Clone, Copy)]
pub struct WlanChannel {
    pub primary: u8,
    pub cbw: ChannelBandwidth,
    pub secondary80: u8,
}

impl WlanChannel {
    pub fn new(primary: u8) -> Self {
        Self {
            primary,
            cbw: ChannelBandwidth::Cbw20,
            secondary80: 0,
        }
    }

    pub fn with_bandwidth(primary: u8, cbw: ChannelBandwidth) -> Self {
        Self {
            primary,
            cbw,
            secondary80: 0,
        }
    }
}

/// TX vector (rate selection)
#[derive(Debug, Clone, Copy)]
pub struct WlanTxVector {
    pub phy: WlanPhyType,
    pub cbw: ChannelBandwidth,
    pub mcs_idx: u8,
    pub nss: u8,
    pub gi: GuardInterval,
}

/// Guard interval
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GuardInterval {
    LongGi = 0,
    ShortGi = 1,
}

/// TX info for transmitted frames
#[derive(Debug, Clone)]
pub struct WlanTxInfo {
    pub tx_flags: u32,
    pub valid_fields: u32,
    pub tx_vector: Option<WlanTxVector>,
    pub phy: WlanPhyType,
    pub cbw: ChannelBandwidth,
    pub mcs: u8,
}

impl Default for WlanTxInfo {
    fn default() -> Self {
        Self {
            tx_flags: 0,
            valid_fields: 0,
            tx_vector: None,
            phy: WlanPhyType::Ofdm,
            cbw: ChannelBandwidth::Cbw20,
            mcs: 0,
        }
    }
}

/// TX packet
#[derive(Debug, Clone)]
pub struct WlanTxPacket {
    pub data: Vec<u8>,
    pub info: WlanTxInfo,
}

/// RX info for received frames
#[derive(Debug, Clone)]
pub struct WlanRxInfo {
    pub rx_flags: u32,
    pub valid_fields: u32,
    pub phy: WlanPhyType,
    pub data_rate: u32,
    pub channel: WlanChannel,
    pub mcs: u8,
    pub rssi_dbm: i8,
    pub snr_dbh: i16,
}

impl Default for WlanRxInfo {
    fn default() -> Self {
        Self {
            rx_flags: 0,
            valid_fields: 0,
            phy: WlanPhyType::Ofdm,
            data_rate: 0,
            channel: WlanChannel::new(1),
            mcs: 0,
            rssi_dbm: -50,
            snr_dbh: 20,
        }
    }
}

/// RX packet
#[derive(Debug, Clone)]
pub struct WlanRxPacket {
    pub data: Vec<u8>,
    pub info: WlanRxInfo,
}

/// Scan types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WlanScanType {
    Active = 0,
    Passive = 1,
}

/// Scan request
#[derive(Debug, Clone)]
pub struct WlanSoftmacPassiveScanArgs {
    pub channels: Vec<u8>,
    pub min_channel_time_ms: u32,
    pub max_channel_time_ms: u32,
    pub min_home_time_ms: u32,
}

/// Scan result
#[derive(Debug, Clone)]
pub struct WlanScanResult {
    pub bssid: MacAddress,
    pub ssid: Vec<u8>,
    pub rssi_dbm: i8,
    pub channel: WlanChannel,
    pub capability_info: u16,
    pub beacon_period: u16,
}

/// BSS (Basic Service Set) config for joining a network
#[derive(Debug, Clone)]
pub struct WlanBssConfig {
    pub bssid: MacAddress,
    pub bss_type: BssType,
    pub remote: bool,
}

/// BSS type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BssType {
    Infrastructure = 0,
    Independent = 1,
    Mesh = 2,
    Personal = 3,
}

/// Key configuration for security
#[derive(Debug, Clone)]
pub struct WlanKeyConfig {
    pub protection: KeyProtection,
    pub cipher_type: CipherSuiteType,
    pub key_type: KeyType,
    pub peer_addr: MacAddress,
    pub key_idx: u8,
    pub key: Vec<u8>,
    pub rsc: u64,
}

/// Key protection level
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyProtection {
    None = 0,
    Rx = 1,
    Tx = 2,
    RxTx = 3,
}

/// Cipher suite type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CipherSuiteType {
    None = 0,
    Wep40 = 1,
    Tkip = 2,
    Reserved = 3,
    Ccmp128 = 4,
    Wep104 = 5,
    BipCmac128 = 6,
    Gcmp128 = 8,
    Gcmp256 = 9,
    Ccmp256 = 10,
    BipGmac128 = 11,
    BipGmac256 = 12,
    BipCmac256 = 13,
}

/// Key type
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyType {
    Pairwise = 0,
    Group = 1,
    Igtk = 2,
    PeerKey = 3,
}

/// Driver capabilities
#[derive(Debug, Clone)]
pub struct WlanSoftmacInfo {
    pub sta_addr: MacAddress,
    pub mac_role: WlanMacRole,
    pub supported_phys: Vec<WlanPhyType>,
    pub hardware_capability: u32,
    pub band_caps: Vec<WlanBandCapability>,
}

/// Band capabilities
#[derive(Debug, Clone)]
pub struct WlanBandCapability {
    pub band: WlanBand,
    pub basic_rates: Vec<u8>,
    pub operating_channels: Vec<u8>,
    pub ht_supported: bool,
    pub ht_caps: Option<HtCapabilities>,
    pub vht_supported: bool,
    pub vht_caps: Option<VhtCapabilities>,
}

/// HT capabilities
#[derive(Debug, Clone, Copy)]
pub struct HtCapabilities {
    pub ht_capability_info: u16,
    pub ampdu_params: u8,
    pub supported_mcs_set: [u8; 16],
    pub ht_ext_capabilities: u16,
    pub tx_beamforming_capabilities: u32,
    pub asel_capabilities: u8,
}

/// VHT capabilities
#[derive(Debug, Clone, Copy)]
pub struct VhtCapabilities {
    pub vht_capability_info: u32,
    pub supported_vht_mcs_and_nss_set: u64,
}

/// WLAN Softmac Bridge - main interface for MAC layer
pub struct WlanSoftmacBridge {
    info: WlanSoftmacInfo,
    started: bool,
    current_channel: Option<WlanChannel>,
    current_bss: Option<WlanBssConfig>,
    installed_keys: HashMap<u8, WlanKeyConfig>,
    scan_results: Vec<WlanScanResult>,
    rx_callback: Option<Box<dyn Fn(WlanRxPacket) + Send + Sync>>,
}

impl WlanSoftmacBridge {
    /// Create a new Softmac bridge
    pub fn new(sta_addr: MacAddress) -> Self {
        let info = WlanSoftmacInfo {
            sta_addr,
            mac_role: WlanMacRole::Client,
            supported_phys: vec![WlanPhyType::Ofdm, WlanPhyType::Ht],
            hardware_capability: 0,
            band_caps: vec![
                WlanBandCapability {
                    band: WlanBand::TwoGhz,
                    basic_rates: vec![2, 4, 11, 22, 12, 18, 24, 36, 48, 72, 96, 108],
                    operating_channels: (1..=13).collect(),
                    ht_supported: true,
                    ht_caps: Some(HtCapabilities {
                        ht_capability_info: 0x016e,
                        ampdu_params: 0x17,
                        supported_mcs_set: [0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        ht_ext_capabilities: 0,
                        tx_beamforming_capabilities: 0,
                        asel_capabilities: 0,
                    }),
                    vht_supported: false,
                    vht_caps: None,
                },
            ],
        };

        Self {
            info,
            started: false,
            current_channel: None,
            current_bss: None,
            installed_keys: HashMap::new(),
            scan_results: Vec::new(),
            rx_callback: None,
        }
    }

    /// Query device information
    pub fn query(&self) -> ZxResult<&WlanSoftmacInfo> {
        Ok(&self.info)
    }

    /// Query MAC sublayer support
    pub fn query_mac_sublayer_support(&self) -> MacSublayerSupport {
        MacSublayerSupport {
            rate_selection_offload: RateSelectionOffloadExtension {
                supported: false,
            },
            data_plane: DataPlaneExtension {
                data_plane_type: DataPlaneType::Ethernet,
            },
            device: DeviceExtension {
                is_synthetic: false,
                tx_status_report_supported: true,
            },
        }
    }

    /// Start the device
    pub fn start(&mut self, rx_callback: Box<dyn Fn(WlanRxPacket) + Send + Sync>) -> ZxResult<WlanChannel> {
        if self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        self.rx_callback = Some(rx_callback);
        self.started = true;
        
        // Default to channel 1
        let channel = WlanChannel::new(1);
        self.current_channel = Some(channel);
        
        Ok(channel)
    }

    /// Stop the device
    pub fn stop(&mut self) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        self.started = false;
        self.rx_callback = None;
        Ok(())
    }

    /// Set channel
    pub fn set_channel(&mut self, channel: WlanChannel) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        // Validate channel
        let valid_channels: Vec<u8> = self.info.band_caps
            .iter()
            .flat_map(|b| b.operating_channels.iter().copied())
            .collect();

        if !valid_channels.contains(&channel.primary) {
            return Err(ZX_ERR_INVALID_ARGS);
        }

        self.current_channel = Some(channel);
        Ok(())
    }

    /// Join BSS
    pub fn join_bss(&mut self, config: WlanBssConfig) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        self.current_bss = Some(config);
        Ok(())
    }

    /// Leave BSS
    pub fn leave_bss(&mut self) -> ZxResult<()> {
        if self.current_bss.is_none() {
            return Err(ZX_ERR_BAD_STATE);
        }

        self.current_bss = None;
        self.installed_keys.clear();
        Ok(())
    }

    /// Install key
    pub fn install_key(&mut self, key: WlanKeyConfig) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        self.installed_keys.insert(key.key_idx, key);
        Ok(())
    }

    /// Start passive scan
    pub fn start_passive_scan(&mut self, args: WlanSoftmacPassiveScanArgs) -> ZxResult<u64> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        // Clear previous results
        self.scan_results.clear();

        // In real implementation, this would start hardware scanning
        // Return scan ID
        Ok(1)
    }

    /// Cancel scan
    pub fn cancel_scan(&mut self, scan_id: u64) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        // Cancel ongoing scan
        Ok(())
    }

    /// Queue TX packet
    pub fn queue_tx(&mut self, packet: WlanTxPacket) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        // In real implementation, this would queue the packet for transmission
        Ok(())
    }

    /// Enable beaconing (AP mode)
    pub fn enable_beaconing(&mut self, beacon_packet: WlanTxPacket) -> ZxResult<()> {
        if self.info.mac_role != WlanMacRole::Ap {
            return Err(ZX_ERR_NOT_SUPPORTED);
        }

        Ok(())
    }

    /// Disable beaconing
    pub fn disable_beaconing(&mut self) -> ZxResult<()> {
        Ok(())
    }

    /// Configure BSS (AP mode)
    pub fn configure_bss(&mut self, config: WlanBssConfig) -> ZxResult<()> {
        self.current_bss = Some(config);
        Ok(())
    }

    /// Set association (for AP mode)
    pub fn configure_association(&mut self, assoc_ctx: AssociationContext) -> ZxResult<()> {
        if !self.started {
            return Err(ZX_ERR_BAD_STATE);
        }

        Ok(())
    }

    /// Clear association
    pub fn clear_association(&mut self, peer_addr: MacAddress) -> ZxResult<()> {
        Ok(())
    }

    /// Update WMM parameters
    pub fn update_wmm_parameters(&mut self, params: WmmParameters) -> ZxResult<()> {
        Ok(())
    }

    /// Notify RX packet (called by driver)
    pub fn notify_rx(&self, packet: WlanRxPacket) {
        if let Some(ref callback) = self.rx_callback {
            callback(packet);
        }
    }

    /// Report TX status
    pub fn report_tx_status(&self, status: WlanTxStatus) {
        // Notify upper layers of TX completion
    }

    /// Get current channel
    pub fn get_channel(&self) -> Option<WlanChannel> {
        self.current_channel
    }

    /// Is device started
    pub fn is_started(&self) -> bool {
        self.started
    }
}

/// MAC sublayer support
#[derive(Debug, Clone)]
pub struct MacSublayerSupport {
    pub rate_selection_offload: RateSelectionOffloadExtension,
    pub data_plane: DataPlaneExtension,
    pub device: DeviceExtension,
}

#[derive(Debug, Clone)]
pub struct RateSelectionOffloadExtension {
    pub supported: bool,
}

#[derive(Debug, Clone)]
pub struct DataPlaneExtension {
    pub data_plane_type: DataPlaneType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DataPlaneType {
    Ethernet = 0,
    Generic = 1,
}

#[derive(Debug, Clone)]
pub struct DeviceExtension {
    pub is_synthetic: bool,
    pub tx_status_report_supported: bool,
}

/// Association context
#[derive(Debug, Clone)]
pub struct AssociationContext {
    pub peer_addr: MacAddress,
    pub aid: u16,
    pub ht_caps: Option<HtCapabilities>,
    pub vht_caps: Option<VhtCapabilities>,
    pub rates: Vec<u8>,
}

/// WMM parameters
#[derive(Debug, Clone)]
pub struct WmmParameters {
    pub ap_wmm_ps: bool,
    pub ac_be_params: WmmAcParams,
    pub ac_bk_params: WmmAcParams,
    pub ac_vi_params: WmmAcParams,
    pub ac_vo_params: WmmAcParams,
}

#[derive(Debug, Clone, Copy)]
pub struct WmmAcParams {
    pub ecw_min: u8,
    pub ecw_max: u8,
    pub aifsn: u8,
    pub txop_limit: u16,
    pub acm: bool,
}

/// TX status
#[derive(Debug, Clone)]
pub struct WlanTxStatus {
    pub peer_addr: MacAddress,
    pub success: bool,
    pub result: WlanTxResult,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WlanTxResult {
    Success = 0,
    Failed = 1,
    Dropped = 2,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_softmac_bridge() {
        let mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55];
        let bridge = WlanSoftmacBridge::new(mac);
        
        let info = bridge.query().unwrap();
        assert_eq!(info.sta_addr, mac);
        assert_eq!(info.mac_role, WlanMacRole::Client);
    }

    #[test]
    fn test_start_stop() {
        let mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55];
        let mut bridge = WlanSoftmacBridge::new(mac);
        
        assert!(!bridge.is_started());
        
        let channel = bridge.start(Box::new(|_| {})).unwrap();
        assert!(bridge.is_started());
        assert_eq!(channel.primary, 1);
        
        bridge.stop().unwrap();
        assert!(!bridge.is_started());
    }

    #[test]
    fn test_set_channel() {
        let mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55];
        let mut bridge = WlanSoftmacBridge::new(mac);
        
        bridge.start(Box::new(|_| {})).unwrap();
        
        // Valid channel
        let channel = WlanChannel::new(6);
        bridge.set_channel(channel).unwrap();
        assert_eq!(bridge.get_channel().unwrap().primary, 6);
        
        // Invalid channel
        let invalid = WlanChannel::new(50);
        assert!(bridge.set_channel(invalid).is_err());
    }

    #[test]
    fn test_join_leave_bss() {
        let mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55];
        let mut bridge = WlanSoftmacBridge::new(mac);
        
        bridge.start(Box::new(|_| {})).unwrap();
        
        let bss = WlanBssConfig {
            bssid: [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff],
            bss_type: BssType::Infrastructure,
            remote: false,
        };
        
        bridge.join_bss(bss).unwrap();
        bridge.leave_bss().unwrap();
    }

    #[test]
    fn test_install_key() {
        let mac = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55];
        let mut bridge = WlanSoftmacBridge::new(mac);
        
        bridge.start(Box::new(|_| {})).unwrap();
        
        let key = WlanKeyConfig {
            protection: KeyProtection::RxTx,
            cipher_type: CipherSuiteType::Ccmp128,
            key_type: KeyType::Pairwise,
            peer_addr: [0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff],
            key_idx: 0,
            key: vec![0; 16],
            rsc: 0,
        };
        
        bridge.install_key(key).unwrap();
    }
}
