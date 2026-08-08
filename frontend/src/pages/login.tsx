import { LoginForm } from "@/components/auth/LoginForm";

/** Login page (Phase 2 auth wiring). */
export default function LoginPage() {
  return (
    <section className="space-y-6 py-6">
      <header className="text-center">
        <h1 className="font-display text-2xl font-bold tracking-tight">Welcome back</h1>
        <p className="text-ink-muted text-sm">Sign in with your university account.</p>
      </header>
      <LoginForm />
    </section>
  );
}
