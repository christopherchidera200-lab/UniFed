/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Backend API base URL is injected at build/runtime via NEXT_PUBLIC_API_BASE.
  env: {
    NEXT_PUBLIC_API_BASE: process.env.NEXT_PUBLIC_API_BASE || "http://localhost:3000",
  },
};

export default nextConfig;
