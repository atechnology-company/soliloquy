mod zircon_window;
mod servo_embedder;
mod v8_runtime;

#[cfg(test)]
mod integration_tests;

use fuchsia_component::server::ServiceFs;
use fuchsia_async as fasync;
use futures::StreamExt;
use log::{info, error, debug};
use servo_embedder::{ServoEmbedder, InputEvent};
use zircon_window::ZirconWindow;

#[cfg(feature = "fuchsia")]
use fuchsia_ui_app::fidl_fuchsia_ui_app::{ViewProviderMarker, ViewProviderRequest, ViewProviderRequestStream};
#[cfg(feature = "fuchsia")]
use fidl::endpoints::ServiceMarker;

#[cfg(feature = "fuchsia")]
enum IncomingService {
    ViewProvider(ViewProviderRequestStream),
}

#[fasync::run_singlethreaded]
async fn main() {
    fuchsia_syslog::init().unwrap();
    info!("Soliloquy Shell starting...");

    #[cfg(feature = "fuchsia")]
    {
        info!("Running with Fuchsia feature enabled");
    }
    
    #[cfg(not(feature = "fuchsia"))]
    {
        info!("Running without Fuchsia feature (host build)");
    }

    let mut embedder = match ServoEmbedder::new() {
        Ok(embedder) => {
            info!("Servo embedder initialized successfully");
            embedder
        }
        Err(e) => {
            error!("Failed to initialize Servo embedder: {}", e);
            return;
        }
    };

    match embedder.load_url("https://example.com") {
        Ok(_) => info!("Initial URL loaded successfully"),
        Err(e) => error!("Failed to load initial URL: {}", e),
    }

    match embedder.execute_js("console.log('V8 is working in Soliloquy!'); 'V8 Test Success'") {
        Ok(result) => info!("V8 test result: {}", result),
        Err(e) => error!("V8 test failed: {}", e),
    }

    let window = ZirconWindow::new();
    
    embedder.handle_input(InputEvent::Touch { x: 100.0, y: 200.0 });
    embedder.handle_input(InputEvent::Key { code: 13 });

    match embedder.present() {
        Ok(_) => debug!("Frame presented successfully"),
        Err(e) => error!("Failed to present frame: {}", e),
    }

    info!("Embedder state: {:?}", embedder.get_state());
    if let Some(url) = embedder.get_current_url() {
        info!("Current URL: {}", url);
    }
    
    if let Some(webview_info) = embedder.get_webview_info() {
        info!("Webview info: {:?}", webview_info);
    }

    #[cfg(feature = "fuchsia")]
    {
        info!("Setting up ViewProvider service");
        let mut fs = ServiceFs::new_local();
        
        fs.dir("svc").add_fidl_service(IncomingService::ViewProvider);
        
        fs.take_and_serve_directory_handle()
            .expect("Failed to serve directory handle");
        
        info!("Soliloquy Shell running with ViewProvider service exposed");
        
        fs.for_each_concurrent(None, |request: IncomingService| async {
            match request {
                IncomingService::ViewProvider(stream) => {
                    info!("Received ViewProvider connection");
                    handle_view_provider(stream).await;
                }
            }
        })
        .await;
    }
    
    #[cfg(not(feature = "fuchsia"))]
    {
        info!("Soliloquy Shell running (no ViewProvider on host build)");
        let mut fs = ServiceFs::new_local();
        fs.collect::<()>().await;
    }
}

#[cfg(feature = "fuchsia")]
async fn handle_view_provider(mut stream: ViewProviderRequestStream) {
    info!("Handling ViewProvider request stream");
    
    while let Some(request) = stream.next().await {
        match request {
            Ok(ViewProviderRequest::CreateView { token, control_handle }) => {
                info!("Received CreateView request (legacy)");
                
                let window = ZirconWindow::new_with_view_token(token);
                window.setup_scene_graph();
                
                info!("CreateView handled successfully");
            }
            Ok(ViewProviderRequest::CreateView2 { args, control_handle }) => {
                info!("Received CreateView2 request");
                
                let window = ZirconWindow::new_with_view_token(args.view_creation_token);
                window.setup_scene_graph();
                
                info!("CreateView2 handled successfully");
            }
            Err(e) => {
                error!("ViewProvider request error: {:?}", e);
                break;
            }
        }
    }
    
    info!("ViewProvider stream closed");
}
