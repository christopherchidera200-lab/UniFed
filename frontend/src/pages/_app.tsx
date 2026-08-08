import type { AppProps } from "next/app";
import { DM_Sans } from "next/font/google";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { UniFedLayout } from "@/components/layout/UniFedLayout";
import { ThemeScript } from "@/components/theme/ThemeScript";
import "@/styles/globals.css";

const dmSans = DM_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-display",
  display: "swap"
});

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, refetchOnWindowFocus: false } }
});

export default function App({ Component, pageProps }: AppProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeScript />
      <div className={dmSans.variable}>
        <UniFedLayout>
          <Component {...pageProps} />
        </UniFedLayout>
      </div>
    </QueryClientProvider>
  );
}
