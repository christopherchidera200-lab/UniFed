import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/router";
import { login } from "@/lib/auth";

/** Email/password/uni_slug login form (OIDC password grant). */
export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [uniSlug, setUniSlug] = useState("adun");

  const mutation = useMutation({
    mutationFn: () => login(email, password, uniSlug),
    onSuccess: () => router.push("/discover"),
    onError: (e: Error) => setError(e.message)
  });
  const [error, setError] = useState<string | null>(null);

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        setError(null);
        mutation.mutate();
      }}
      className="space-y-4 max-w-sm mx-auto"
    >
      <div>
        <label className="block text-sm font-medium mb-1">University slug</label>
        <input
          value={uniSlug}
          onChange={(e) => setUniSlug(e.target.value)}
          className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                     dark:bg-navy-900 px-3 py-2 text-sm"
          placeholder="adun"
        />
      </div>
      <div>
        <label className="block text-sm font-medium mb-1">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                     dark:bg-navy-900 px-3 py-2 text-sm"
          placeholder="you@adun.edu.ng"
          required
        />
      </div>
      <div>
        <label className="block text-sm font-medium mb-1">Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full rounded-md border border-navy-200 dark:border-navy-700 bg-white
                     dark:bg-navy-900 px-3 py-2 text-sm"
          required
        />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        type="submit"
        disabled={mutation.isPending}
        className="w-full px-4 py-2 rounded-md bg-navy-600 text-white font-medium
                   hover:bg-navy-700 transition-colors disabled:opacity-60"
      >
        {mutation.isPending ? "Signing in…" : "Sign in"}
      </button>
    </form>
  );
}
