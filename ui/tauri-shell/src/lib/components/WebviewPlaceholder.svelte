<script lang="ts">
    import { onMount } from 'svelte';
    
    let isHovered = false;
    let webviewUrl = 'servo://localhost/shell';
    
    async function handleWebviewClick() {
        console.log('Webview clicked - would load:', webviewUrl);
        // In a real implementation, this would tell Servo to load the URL
        // For now, we'll just log it
    }
</script>

<section class="webview-section p-4">
    <div 
        class="webview-placeholder"
        class:hover={isHovered}
        onclick={handleWebviewClick}
        role="button"
        tabindex="0"
        onkeydown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
                handleWebviewClick();
            }
        }}
    >
        <div class="webview-content">
            <div class="webview-icon">
                <svg class="w-16 h-16 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"/>
                </svg>
            </div>
            
            <div class="webview-text">
                <h3 class="text-lg font-semibold text-gray-200 mb-2">Servo Webview</h3>
                <p class="text-sm text-gray-400 mb-4 text-center max-w-md">
                    This area will display the Servo-rendered web content. In the full Soliloquy, 
                    this would show web applications and the desktop environment.
                </p>
                
                <div class="webview-details">
                    <div class="text-xs text-gray-500 mb-2">
                        <strong>Runtime:</strong> Servo Browser Engine
                    </div>
                    <div class="text-xs text-gray-500 mb-2">
                        <strong>Graphics:</strong> WebRender + Vulkan (Mali-G57)
                    </div>
                    <div class="text-xs text-gray-500 mb-4">
                        <strong>JavaScript:</strong> V8 Engine
                    </div>
                    
                    <div class="url-bar">
                        <input 
                            type="text" 
                            bind:value={webviewUrl}
                            class="w-full px-3 py-2 bg-gray-800 border border-gray-700 rounded text-sm text-gray-300 focus:outline-none focus:border-blue-500"
                            placeholder="Enter URL..."
                            onclick={(e) => e.stopPropagation()}
                        />
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="webview-info mt-4 text-center">
        <p class="text-xs text-gray-500">
            💡 <strong>Development Note:</strong> This is a mock webview. In production, Servo will render 
            web content here using the Zircon graphics stack.
        </p>
    </div>
</section>

<style>
    .webview-section {
        flex: 0 0 auto;
    }
    
    .webview-placeholder {
        background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
        border: 2px dashed #374151;
        border-radius: 0.75rem;
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 300px;
        position: relative;
        overflow: hidden;
        cursor: pointer;
        transition: all 0.3s ease;
        outline: none;
    }
    
    .webview-placeholder:hover {
        border-color: #4b5563;
        background: linear-gradient(135deg, #1e293b 0%, #1a1f2e 100%);
    }
    
    .webview-placeholder:focus {
        --tw-ring-color: rgb(59, 130, 246);
        --tw-ring-offset-shadow: var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);
        --tw-ring-shadow: var(--tw-ring-inset) 0 0 0 calc(3px + var(--tw-ring-offset-width)) var(--tw-ring-color);
        box-shadow: var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000);
        --tw-ring-offset-color: rgb(17, 24, 39);
        --tw-ring-offset-width: 2px;
    }
    
    .webview-content {
        text-align: center;
        padding: 2rem;
    }
    
    .webview-icon {
        margin-bottom: 1.5rem;
        opacity: 0.6;
    }
    
    .webview-text {
        max-width: 500px;
    }
    
    .webview-details {
        background: rgba(0, 0, 0, 0.2);
        border-radius: 0.5rem;
        padding: 1rem;
        margin-top: 1rem;
        border: 1px solid rgba(55, 65, 81, 0.5);
    }
    
    .url-bar {
        margin-top: 1rem;
    }
    
    .webview-info {
        opacity: 0.7;
    }
</style>