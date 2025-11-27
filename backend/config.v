module main

import os

pub struct Config {
pub mut:
	google_client_id     string
	google_client_secret string
	google_redirect_uri  string
	tableware_base_url   string
	session_secret       string
}

pub fn load_config() Config {
	return Config{
		google_client_id: os.getenv_opt('GOOGLE_CLIENT_ID') or { 
			panic('GOOGLE_CLIENT_ID must be set') 
		}
		google_client_secret: os.getenv_opt('GOOGLE_CLIENT_SECRET') or { 
			panic('GOOGLE_CLIENT_SECRET must be set') 
		}
		google_redirect_uri: os.getenv_opt('GOOGLE_REDIRECT_URI') or { 
			'http://localhost:${port}/api/auth/google/callback' 
		}
		tableware_base_url: os.getenv_opt('TABLEWARE_BASE_URL') or { 
			'http://localhost:8000' 
		}
		session_secret: os.getenv_opt('SESSION_SECRET') or { 
			'soliloquy-dev-secret-change-in-production' 
		}
	}
}
