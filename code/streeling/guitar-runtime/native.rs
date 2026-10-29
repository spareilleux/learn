#[path = "vendor/lib.rs"]
mod engine;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let frames: usize = args[1].parse().unwrap();
    let block: usize = args[2].parse().unwrap();
    let mode = &args[3];
    assert!(frames > 0 && block > 0);
    assert!(["baseline", "candidate", "silence"].contains(&mode.as_str()));
    let pointer = engine::engine_init(44100.0);
    assert!(!pointer.is_null());
    if mode == "candidate" { engine::engine_set_decay(pointer, 0.9976); }
    if mode != "silence" { engine::engine_note_on(pointer, 82.4069, 0.1); }
    let mut samples = vec![0.0_f32; frames];
    for chunk in samples.chunks_mut(block) {
        engine::engine_render(pointer, chunk.as_mut_ptr(), chunk.len());
    }
    let bytes: Vec<u8> = samples.iter().flat_map(|v| v.to_le_bytes()).collect();
    std::fs::write(&args[4], bytes).unwrap();
    // This exact pinned source allocates Engine with Box::into_raw in engine_init.
    // Cleanup belongs to this native teaching adapter, not the exported WASM ABI.
    unsafe { drop(Box::from_raw(pointer)); }
}
