
pub fn call_mass_send(addr: [u8; 20], amt: &U) ->  bool {
    call_unit(addr, &[0x66, 0x4e, 0x01, 0x40], amt, u64::MAX)
}
