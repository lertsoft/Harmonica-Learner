export type Theme = 'dark' | 'light';

class ThemeState {
	current = $state<Theme>('dark');
	private initialized = false;

	init() {
		if (typeof window === 'undefined' || this.initialized) return;
		this.initialized = true;

		let initial: Theme = 'dark';
		try {
			const params = new URLSearchParams(window.location.search);
			const tParam = params.get('theme');
			if (tParam === 'light' || tParam === 'dark') {
				initial = tParam;
			} else {
				const saved = localStorage.getItem('harmonica_theme');
				if (saved === 'light' || saved === 'dark') {
					initial = saved;
				} else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) {
					initial = 'light';
				}
			}
		} catch {
			// Storage access can fail in privacy-restricted environments
		}

		this.setTheme(initial);

		// Synchronize theme changes across open browser tabs
		window.addEventListener('storage', (e) => {
			if (e.key === 'harmonica_theme' && (e.newValue === 'light' || e.newValue === 'dark')) {
				this.setTheme(e.newValue);
			}
		});

		// Listen for OS system theme changes when user has not explicitly chosen a preference
		if (window.matchMedia) {
			const mql = window.matchMedia('(prefers-color-scheme: light)');
			mql.addEventListener('change', (e) => {
				let hasSaved: string | null = null;
				try {
					hasSaved = localStorage.getItem('harmonica_theme');
				} catch {}
				if (!hasSaved) {
					this.setTheme(e.matches ? 'light' : 'dark');
				}
			});
		}
	}

	setTheme(theme: Theme) {
		this.current = theme;
		if (typeof window !== 'undefined') {
			try {
				localStorage.setItem('harmonica_theme', theme);
			} catch {}

			const root = document.documentElement;
			root.setAttribute('data-theme', theme);
			if (theme === 'light') {
				root.classList.add('theme-light');
			} else {
				root.classList.remove('theme-light');
			}

			const metaThemeColor = document.querySelector('meta[name="theme-color"]');
			if (metaThemeColor) {
				metaThemeColor.setAttribute('content', theme === 'light' ? '#fbfbf9' : '#0d111a');
			}

			const metaColorScheme = document.querySelector('meta[name="color-scheme"]');
			if (metaColorScheme) {
				metaColorScheme.setAttribute('content', theme);
			}

			// Reflect theme in URL search parameter if one is already present
			const url = new URL(window.location.href);
			if (url.searchParams.has('theme')) {
				url.searchParams.set('theme', theme);
				window.history.replaceState({}, '', url.toString());
			}
		}
	}

	toggleTheme() {
		this.setTheme(this.current === 'dark' ? 'light' : 'dark');
	}
}

export const themeState = new ThemeState();
