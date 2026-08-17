import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { getExpiresAt, refreshSession } from "./auth";

/**
 * Session context — surfaces token-expiry state to the UI so users aren't
 * silently logged out mid-action (the brief's session-clarity requirement).
 * Backed by the real refresh logic in auth.ts. A non-intrusive toast (see
 * SessionToast) is shown when expiry is imminent.
 */
interface SessionState {
  /** ms until expiry, or null if unknown. */
  msToExpiry: number | null;
  /** True when within the warning window (<= 2 min). */
  warning: boolean;
  /** Proactively refresh now (user tapped "Stay signed in"). */
  staySignedIn: () => Promise<void>;
}

const Ctx = createContext<SessionState>({
  msToExpiry: null, warning: false, staySignedIn: async () => {}
});

const WARN_WINDOW_MS = 2 * 60 * 1000;

export function SessionProvider({ children }: { children: ReactNode }) {
  const [msToExpiry, setMsToExpiry] = useState<number | null>(null);
  const timer = useRef<ReturnType<typeof setInterval>>();

  useEffect(() => {
    const tick = () => {
      const exp = getExpiresAt();
      setMsToExpiry(exp == null ? null : exp - Date.now());
    };
    tick();
    timer.current = setInterval(tick, 15_000);
    return () => clearInterval(timer.current);
  }, []);

  const staySignedIn = async () => {
    await refreshSession();
  };

  const warning = msToExpiry != null && msToExpiry > 0 && msToExpiry <= WARN_WINDOW_MS;

  return (
    <Ctx.Provider value={{ msToExpiry, warning, staySignedIn }}>{children}</Ctx.Provider>
  );
}

export function useSession(): SessionState {
  return useContext(Ctx);
}
