import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import Link from "next/link";
import { useRouter } from "next/router";
import { unifedApi } from "@/lib/api";
import { storeTokens } from "@/lib/auth";
import { SectionHeader, Card } from "@/components/ui/Card";

const PASSWORD_RE = /(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=[\]{};':"\\|,.<>\/?]).{8,}/;

/** Self-service sign-up (product-readiness). Reuses the existing auth session. */
export default function SignupPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [matricNo, setMatricNo] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: () =>
      unifedApi.register({
        name,
        email,
        password,
        ...(matricNo.trim() ? { matric_no: matricNo.trim() } : {})
      }),
    onSuccess: (tokens) => {
      storeTokens(tokens);
      router.push("/discover");
    },
    onError: (e: Error) => setError(e.message)
  });

  const passwordMismatch = confirm.length > 0 && password !== confirm;
  const weak = password.length > 0 && !PASSWORD_RE.test(password);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (!name.trim() || !email.trim()) return setError("Name and email are required.");
    if (weak) return setError("Password must be 8+ chars with upper, lower, digit and symbol.");
    if (passwordMismatch) return setError("Passwords do not match.");
    mutation.mutate();
  }

  return (
    <section className="space-y-6 py-6">
      <header className="text-center">
        <h1 className="font-display text-2xl font-bold tracking-tight">Create your account</h1>
        <p className="text-ink-muted text-sm">Join your university on UniFed.</p>
      </header>

      <Card className="max-w-sm mx-auto p-5">
        <form onSubmit={submit} className="space-y-4" noValidate>
          <div>
            <label className="block text-sm font-medium mb-1" htmlFor="name">Full name</label>
            <input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoComplete="name"
              className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                         dark:bg-navy-900 px-3 py-2 text-sm"
              placeholder="Chidera Christopher"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1" htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                         dark:bg-navy-900 px-3 py-2 text-sm"
              placeholder="you@adun.edu.ng"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1" htmlFor="matric">
              Matric number <span className="text-ink-subtle font-normal">(optional)</span>
            </label>
            <input
              id="matric"
              value={matricNo}
              onChange={(e) => setMatricNo(e.target.value)}
              autoComplete="off"
              className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                         dark:bg-navy-900 px-3 py-2 text-sm"
              placeholder="ADUN/FS/CYB/23/001"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1" htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="new-password"
              className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                         dark:bg-navy-900 px-3 py-2 text-sm"
              placeholder="At least 8 characters"
              required
            />
            {weak && (
              <p className="text-xs text-amber-600 dark:text-amber-400 mt-1">
                Use upper + lower + number + symbol, 8+ chars.
              </p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium mb-1" htmlFor="confirm">Confirm password</label>
            <input
              id="confirm"
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              autoComplete="new-password"
              className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                         dark:bg-navy-900 px-3 py-2 text-sm"
              required
            />
            {passwordMismatch && (
              <p className="text-xs text-red-600 mt-1">Passwords do not match.</p>
            )}
          </div>

          {error && <p className="text-sm text-red-600" role="alert">{error}</p>}

          <button
            type="submit"
            disabled={mutation.isPending}
            className="w-full px-4 py-2 rounded-md bg-navy-600 text-white font-medium
                       hover:bg-navy-700 transition-colors disabled:opacity-60"
          >
            {mutation.isPending ? "Creating account…" : "Create account"}
          </button>
        </form>
      </Card>

      <p className="text-center text-sm text-ink-muted">
        Already have an account?{" "}
        <Link href="/login" className="text-navy-600 dark:text-navy-300 font-medium underline">
          Sign in
        </Link>
      </p>
    </section>
  );
}
