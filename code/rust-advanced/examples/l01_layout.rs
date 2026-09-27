use rust_advanced_course::{CompactPacket, Packet};
use std::mem::{align_of, offset_of, size_of};
use std::num::NonZeroUsize;

fn main() {
    println!("target_pointer_width={}", usize::BITS);
    println!(
        "Packet size={} align={} offsets={},{},{}",
        size_of::<Packet>(),
        align_of::<Packet>(),
        offset_of!(Packet, tag),
        offset_of!(Packet, count),
        offset_of!(Packet, ready),
    );
    println!(
        "CompactPacket size={} align={} offsets={},{},{}",
        size_of::<CompactPacket>(),
        align_of::<CompactPacket>(),
        offset_of!(CompactPacket, count),
        offset_of!(CompactPacket, tag),
        offset_of!(CompactPacket, ready),
    );
    println!("Option<usize> size={}", size_of::<Option<usize>>());
    println!(
        "Option<NonZeroUsize> size={}",
        size_of::<Option<NonZeroUsize>>()
    );
}
