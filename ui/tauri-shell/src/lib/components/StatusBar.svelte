<script lang="ts">
    import { onMount } from 'svelte';
    import { appWindow } from '@tauri-apps/api/window';
    
    let currentTime = new Date();
    let windowTitle = 'Soliloquy Shell';
    
    onMount(() => {
        // Update time every second
        const interval = setInterval(() => {
            currentTime = new Date();
        }, 1000);
        
        return () => clearInterval(interval);
    });
    
    $: formattedTime = currentTime.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit',
        hour12: false 
    });
    
    $: formattedDate = currentTime.toLocaleDateString('en-US', { 
        weekday: 'short', 
        month: 'short', 
        day: 'numeric' 
    });
</script>

<header class="status-bar h-12 px-4 flex items-center justify-between text-sm">
    <!-- Left side: System info -->
    <div class="flex items-center space-x-4">
        <div class="flex items-center space-x-2">
            <div class="w-6 h-6 bg-blue-600 rounded flex items-center justify-center text-xs font-bold">
                S
            </div>
            <span class="font-medium">{windowTitle}</span>
        </div>
        
        <div class="text-xs text-gray-400">
            Servo Runtime • Zircon Kernel
        </div>
    </div>
    
    <!-- Right side: Status indicators -->
    <div class="flex items-center space-x-4">
        <!-- Network Status -->
        <div class="flex items-center space-x-1 text-green-400">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M17.778 8.222c-4.296-4.296-11.26-4.296-15.556 0A1 1 0 01.808 6.808c5.076-5.077 13.308-5.077 18.384 0a1 1 0 01-1.414 1.414zM14.95 11.05a7 7 0 00-9.9 0 1 1 0 01-1.414-1.414 9 9 0 0112.728 0 1 1 0 01-1.414 1.414zM12.12 13.88a3 3 0 00-4.242 0 1 1 0 01-1.415-1.415 5 5 0 017.072 0 1 1 0 01-1.415 1.415zM9 16a1 1 0 011-1v0a1 1 0 110 2v0a1 1 0 01-1-1z" clip-rule="evenodd"/>
            </svg>
            <span class="text-xs">Connected</span>
        </div>
        
        <!-- Battery Status -->
        <div class="flex items-center space-x-1 text-gray-300">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"/>
            </svg>
            <span class="text-xs">85%</span>
        </div>
        
        <!-- Date & Time -->
        <div class="text-xs text-gray-300">
            <div>{formattedTime}</div>
        </div>
    </div>
</header>

<style>
    .status-bar {
        background: linear-gradient(to bottom, #1f2937, #111827);
        border-bottom: 1px solid #374151;
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
    }
</style>