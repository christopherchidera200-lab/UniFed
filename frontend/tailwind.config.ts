import type { Config } from "tailwindcss";
import { tokens } from "./src/design/tokens";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        navy: tokens.color.navy,
        brand: tokens.color.brand,
        saffron: tokens.color.saffron,
        ink: tokens.color.ink,
        ct: tokens.color.ct,
        role: tokens.color.role,
        fed: tokens.color.fed
      },
      fontFamily: {
        display: ["var(--font-display)", "DM Sans", "system-ui", "sans-serif"],
        body: ["var(--font-body)", "DM Sans", "system-ui", "sans-serif"]
      },
      borderRadius: tokens.radius,
      boxShadow: tokens.shadow,
      transitionTimingFunction: { unifed: tokens.motion.ease },
      keyframes: {
        "fade-up": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        }
      },
      animation: {
        "fade-up": "fade-up 0.35s cubic-bezier(.22,1,.36,1) both"
      }
    }
  },
  plugins: []
};

export default config;
