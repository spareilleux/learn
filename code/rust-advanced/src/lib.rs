//! Compile-time checks for the Advanced Rust course.
//!
//! A transparent wrapper may have only one non-zero-sized field. The compiler
//! rejects a second field because callers could no longer rely on one layout.
//!
//! ```compile_fail,E0690
//! #[repr(transparent)]
//! struct InvalidTransparent(u32, u32);
//! ```

/// A C-compatible packet whose field order leaves two padding regions.
#[repr(C)]
pub struct Packet {
    pub tag: u8,
    pub count: u32,
    pub ready: bool,
}

/// The same fields ordered from strictest to loosest alignment.
#[repr(C)]
pub struct CompactPacket {
    pub count: u32,
    pub tag: u8,
    pub ready: bool,
}

#[cfg(test)]
mod tests {
    use super::{CompactPacket, Packet};
    use std::mem::{align_of, offset_of, size_of};

    #[test]
    fn measured_layout_matches_the_lesson() {
        assert_eq!((size_of::<Packet>(), align_of::<Packet>()), (12, 4));
        assert_eq!(
            (
                offset_of!(Packet, tag),
                offset_of!(Packet, count),
                offset_of!(Packet, ready)
            ),
            (0, 4, 8),
        );
        assert_eq!(
            (size_of::<CompactPacket>(), align_of::<CompactPacket>()),
            (8, 4)
        );
        assert_eq!(
            (
                offset_of!(CompactPacket, count),
                offset_of!(CompactPacket, tag),
                offset_of!(CompactPacket, ready),
            ),
            (0, 4, 5),
        );
    }
}
