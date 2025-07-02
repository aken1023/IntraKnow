import type { Config } from "tailwindcss";
import defaultTheme from "tailwindcss/defaultTheme";

const config: Config = {
    darkMode: "class",
    content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
    "./lib/**/*.{js,ts,jsx,tsx,mdx}",
    "./hooks/**/*.{js,ts,jsx,tsx,mdx}",
    "*.{js,ts,jsx,tsx,mdx}"
  ],
  theme: {
    screens: {
      'xs': '390px',
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
      '3xl': '1920px',
    },
  	extend: {
      fontFamily: {
        sans: ["var(--font-sans)", ...defaultTheme.fontFamily.sans],
        serif: ["var(--font-serif)", ...defaultTheme.fontFamily.serif],
      },
  		colors: {
  			border: "hsl(var(--border) / <alpha-value>)",
  			input: "hsl(var(--input) / <alpha-value>)",
  			ring: "hsl(var(--ring) / <alpha-value>)",
  			background: "hsl(var(--background) / <alpha-value>)",
  			foreground: "hsl(var(--foreground) / <alpha-value>)",
  			primary: {
  				DEFAULT: "hsl(var(--primary) / <alpha-value>)",
  				foreground: "hsl(var(--primary-foreground) / <alpha-value>)",
  			},
  			secondary: {
  				DEFAULT: "hsl(var(--secondary) / <alpha-value>)",
  				foreground: "hsl(var(--secondary-foreground) / <alpha-value>)",
  			},
  			destructive: {
  				DEFAULT: "hsl(var(--destructive) / <alpha-value>)",
  				foreground: "hsl(var(--destructive-foreground) / <alpha-value>)",
  			},
  			muted: {
  				DEFAULT: "hsl(var(--muted) / <alpha-value>)",
  				foreground: "hsl(var(--muted-foreground) / <alpha-value>)",
  			},
  			accent: {
  				DEFAULT: "hsl(var(--accent) / <alpha-value>)",
  				foreground: "hsl(var(--accent-foreground) / <alpha-value>)",
  			},
  			popover: {
  				DEFAULT: "hsl(var(--popover) / <alpha-value>)",
  				foreground: "hsl(var(--popover-foreground) / <alpha-value>)",
  			},
  			card: {
  				DEFAULT: "hsl(var(--card) / <alpha-value>)",
  				foreground: "hsl(var(--card-foreground) / <alpha-value>)",
  			},
  			chart: {
  				'1': 'hsl(var(--chart-1))',
  				'2': 'hsl(var(--chart-2))',
  				'3': 'hsl(var(--chart-3))',
  				'4': 'hsl(var(--chart-4))',
  				'5': 'hsl(var(--chart-5))'
  			},
  			sidebar: {
  				DEFAULT: 'hsl(var(--sidebar-background))',
  				foreground: 'hsl(var(--sidebar-foreground))',
  				primary: 'hsl(var(--sidebar-primary))',
  				'primary-foreground': 'hsl(var(--sidebar-primary-foreground))',
  				accent: 'hsl(var(--sidebar-accent))',
  				'accent-foreground': 'hsl(var(--sidebar-accent-foreground))',
  				border: 'hsl(var(--sidebar-border))',
  				ring: 'hsl(var(--sidebar-ring))'
  			}
  		},
  		borderRadius: {
  			lg: "var(--radius)",
  			md: "calc(var(--radius) - 2px)",
  			sm: "calc(var(--radius) - 4px)"
  		},
  		keyframes: {
  			'accordion-down': {
  				from: {
  					height: '0'
  				},
  				to: {
  					height: 'var(--radix-accordion-content-height)'
  				}
  			},
  			'accordion-up': {
  				from: {
  					height: 'var(--radix-accordion-content-height)'
  				},
  				to: {
  					height: '0'
  				}
  			}
  		},
  		animation: {
  			'accordion-down': 'accordion-down 0.2s ease-out',
  			'accordion-up': 'accordion-up 0.2s ease-out'
  		},
      spacing: {
        '4.5': '1.125rem',
        '5.5': '1.375rem',
        '18': '4.5rem',
      },
      container: {
        center: true,
        padding: {
          DEFAULT: '1rem',
          sm: '1.5rem',
          md: '2rem',
        },
      },
  	}
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config;
export default config;
