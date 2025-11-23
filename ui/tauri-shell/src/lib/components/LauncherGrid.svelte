<script lang="ts">
    interface LauncherItem {
        id: string;
        name: string;
        icon: string;
        description: string;
        url?: string;
    }
    
    const launcherItems: LauncherItem[] = [
        {
            id: 'browser',
            name: 'Browser',
            icon: '🌐',
            description: 'Web Browser',
            url: 'https://example.com'
        },
        {
            id: 'terminal',
            name: 'Terminal',
            icon: '💻',
            description: 'Command Line'
        },
        {
            id: 'files',
            name: 'Files',
            icon: '📁',
            description: 'File Manager'
        },
        {
            id: 'settings',
            name: 'Settings',
            icon: '⚙️',
            description: 'System Settings'
        },
        {
            id: 'calculator',
            name: 'Calculator',
            icon: '🧮',
            description: 'Calculator'
        },
        {
            id: 'text-editor',
            name: 'Editor',
            icon: '📝',
            description: 'Text Editor'
        },
        {
            id: 'media',
            name: 'Media',
            icon: '🎵',
            description: 'Media Player'
        },
        {
            id: 'camera',
            name: 'Camera',
            icon: '📷',
            description: 'Camera'
        }
    ];
    
    async function handleLauncherClick(item: LauncherItem) {
        console.log(`Launching ${item.name}:`, item);
        
        if (item.url) {
            // In a real implementation, this would open the URL in Servo
            console.log(`Would open ${item.url} in Servo webview`);
        } else {
            // In a real implementation, this would launch the corresponding app
            console.log(`Would launch ${item.id} application`);
        }
    }
</script>

<section class="launcher-container">
    <div class="launcher-grid">
        {#each launcherItems as item (item.id)}
            <div 
                class="launcher-item"
                role="button"
                tabindex="0"
                onclick={() => handleLauncherClick(item)}
                onkeydown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                        handleLauncherClick(item);
                    }
                }}
            >
                <div class="launcher-icon">{item.icon}</div>
                <div class="launcher-label">{item.name}</div>
            </div>
        {/each}
    </div>
</section>

<style>
    .launcher-container {
        flex: 1;
        overflow-y: auto;
        padding: 1rem 0;
    }
    
    .launcher-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
        gap: 1rem;
        padding: 0 1.5rem;
        max-width: 800px;
        margin: 0 auto;
    }
    
    .launcher-item {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 1rem;
        border-radius: 0.5rem;
        background-color: rgb(31, 41, 55);
        transition: all 0.2s;
        cursor: pointer;
        border: 1px solid rgb(55, 65, 81);
        min-height: 100px;
        outline: none;
    }
    
    .launcher-item:hover {
        background-color: rgb(55, 65, 81);
        border-color: rgb(75, 85, 99);
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    }
    
    .launcher-item:focus {
        --tw-ring-color: rgb(59, 130, 246);
        --tw-ring-offset-shadow: var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);
        --tw-ring-shadow: var(--tw-ring-inset) 0 0 0 calc(3px + var(--tw-ring-offset-width)) var(--tw-ring-color);
        box-shadow: var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000);
        --tw-ring-offset-color: rgb(17, 24, 39);
        --tw-ring-offset-width: 2px;
    }
    
    .launcher-icon {
        font-size: 2rem;
        line-height: 1;
        margin-bottom: 0.5rem;
    }
    
    .launcher-label {
        font-size: 0.75rem;
        font-weight: 500;
        color: rgb(209, 213, 219);
        text-align: center;
    }
</style>