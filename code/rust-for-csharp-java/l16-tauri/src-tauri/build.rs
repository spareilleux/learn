fn main() {
    embed_manifest_in_tests();
    tauri_build::build()
}

/// tauri-build embeds a Windows application manifest (Common Controls v6) in the
/// binaries only. Test executables need it too, or they fail to start with
/// `STATUS_ENTRYPOINT_NOT_FOUND`: https://github.com/tauri-apps/tauri/issues/13419
fn embed_manifest_in_tests() {
    const MANIFEST: &str = r#"<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0"
        processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*" />
    </dependentAssembly>
  </dependency>
</assembly>
"#;
    if std::env::var("CARGO_CFG_TARGET_ENV").as_deref() != Ok("msvc") {
        return;
    }
    let out_dir = std::env::var("OUT_DIR").expect("Cargo sets OUT_DIR for build scripts");
    let path = std::path::Path::new(&out_dir).join("test-manifest.xml");
    std::fs::write(&path, MANIFEST).expect("OUT_DIR is writable");
    println!("cargo:rustc-link-arg-tests=/MANIFEST:EMBED");
    println!(
        "cargo:rustc-link-arg-tests=/MANIFESTINPUT:{}",
        path.display()
    );
}
