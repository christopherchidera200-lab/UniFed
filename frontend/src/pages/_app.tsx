import type { AppProps } from "next/app";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { UniFedLayout } from "@/components/layout/UniFedLayout";
import "@/styles/globals.css";

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, refetchOnWindowFocus: false } }
});

export default function App({ Component, pageProps }: AppProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <UniFedLayout>
        <Component {...pageProps} />
      </UniFedLayout>
    </QueryClientProvider>
  );
}
