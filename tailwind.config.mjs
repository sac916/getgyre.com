/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        // The Abyss — dark ocean palette
        abyss: {
          bg: '#080d1a',        // page top
          deep: '#030508',      // page bottom / deepest cards
          surface: '#060c16',   // card backgrounds
          card: '#040a12',      // inner code blocks
          border: '#0d1f2e',    // subtle borders
          muted: '#0d1e2a',     // muted backgrounds
        },
        teal: {
          DEFAULT: 'rgba(0,120,160,0.85)',  // deep teal accent — button fill
          light: '#00aed0',                  // teal for links/code
          glow: 'rgba(0,120,160,0.12)',      // ambient glow only
          border: 'rgba(0,120,160,0.25)',    // teal borders
        },
        text: {
          primary: '#ffffff',
          secondary: 'rgba(255,255,255,0.65)',
          muted: 'rgba(255,255,255,0.35)',
        },
      },
      fontFamily: {
        serif: ['Georgia', 'Times New Roman', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'Consolas', 'monospace'],
      },
    },
  },
  plugins: [],
};
