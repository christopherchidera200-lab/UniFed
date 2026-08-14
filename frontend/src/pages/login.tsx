import { LoginForm } from "@/components/auth/LoginForm";
import Link from "next/link";

/** Login page (Phase 2 auth wiring). */
export default function LoginPage() {
  return (
    <section className="space-y-6 py-6">
      <header className="text-center">
        <h1 className="font-display text-2xl font-bold tracking-tight">Welcome back</h1>
        <p className="text-ink-muted text-sm">Sign in with your university account.</p>
      </header>
      <LoginForm />
      <p className="text-center text-sm text-ink-muted">
        New to UniFed?{" "}
        <Link href="/signup" className="text-navy-600 dark:text-navy-300 font-medium underline">
          Create an account
        </Link>
      </p>
    </section>
  );
}
