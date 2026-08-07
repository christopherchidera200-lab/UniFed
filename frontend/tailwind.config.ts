import type { Config } from "tailwindcss";
import { tokens } from "./src/design/tokens";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        navy: tokens.color.navy,
        saffron: tokens.color.saffron,
        ink: tokens.color.ink
      },
      fontFamily: {
        display: ["var(--font-display)", "Space Grotesk", "system-ui", "sans-serif"],
        body: ["var(--font-body)", "Inter", "system-ui", "sans-serif"]
      },
      borderRadius: tokens.radius,
      boxShadow: tokens.shadow,
      transitionTimingFunction: { unifed: tokens.motion.ease }
    }
  },
  plugins: []
};

export default config;
