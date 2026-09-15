//! Helpers shared by the integration tests: build an app on Tauri's mock runtime
//! and call its commands through the real IPC layer, without a window or a webview.

use serde_json::Value;
use tauri::ipc::{CallbackFn, InvokeBody};
use tauri::test::{INVOKE_KEY, MockRuntime, mock_context, noop_assets};
use tauri::webview::InvokeRequest;
use tauri::{App, Builder, WebviewWindow, WebviewWindowBuilder};

/// Builds the app and a `main` window. Keep the `App` alive for the whole test.
pub fn launch(builder: Builder<MockRuntime>) -> (App<MockRuntime>, WebviewWindow<MockRuntime>) {
    let app = builder
        .build(mock_context(noop_assets()))
        .expect("the mock app builds");
    let webview = WebviewWindowBuilder::new(&app, "main", Default::default())
        .build()
        .expect("the mock window builds");
    (app, webview)
}

/// What `invoke(cmd, args)` resolves (`Ok`) or rejects (`Err`) with in JavaScript.
pub fn invoke(
    webview: &WebviewWindow<MockRuntime>,
    cmd: &str,
    args: Value,
) -> Result<Value, Value> {
    let request = InvokeRequest {
        cmd: cmd.into(),
        callback: CallbackFn(0),
        error: CallbackFn(1),
        url: "http://tauri.localhost".parse().unwrap(),
        body: InvokeBody::Json(args),
        headers: Default::default(),
        invoke_key: INVOKE_KEY.to_string(),
    };
    tauri::test::get_ipc_response(webview, request).map(|body| body.deserialize().unwrap())
}
