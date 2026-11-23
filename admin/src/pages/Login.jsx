import { useState } from "react";
import { ArrowRight, ChefHat, Eye, EyeOff, Leaf, LockKeyhole, Mail } from "lucide-react";
import { api, getErrorMessage, setAuthToken } from "../api.js";

export default function Login({ onLogin }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const { data } = await api.post("/auth/login", { email, password });
      if (data.user?.role !== "admin") {
        setError("This account doesn’t have administrator access.");
        return;
      }
      setAuthToken(data.token);
      onLogin(data.user);
    } catch (loginError) {
      setError(getErrorMessage(loginError));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="login-page">
      <section className="login-art">
        <div className="login-art-top"><div className="brand-mark brand-mark-light"><ChefHat size={23} /></div><span>campus<span>kitchen</span></span></div>
        <div className="login-art-content">
          <span className="login-kicker"><Leaf size={14} /> MADE FOR YOUR CAMPUS</span>
          <h1>Good food.<br /><em>Good days.</em></h1>
          <p>Every great campus moment starts around the table. Let’s make today delicious.</p>
          <div className="login-art-note"><span className="login-note-line" />Thoughtful food, made easy.</div>
        </div>
        <div className="login-art-footer">CAMPUS KITCHEN · EST. FOR EVERY DAY</div>
        <div className="login-art-orbit orbit-one" /><div className="login-art-orbit orbit-two" />
      </section>
      <section className="login-form-side">
        <div className="login-mobile-brand"><div className="brand-mark"><ChefHat size={21} /></div>campus<span>kitchen</span></div>
        <div className="login-form-wrap">
          <div className="login-welcome">WELCOME BACK</div>
          <h2>Sign in to your<br />kitchen.</h2>
          <p className="login-description">Your campus kitchen is ready when you are.</p>
          <form onSubmit={handleSubmit} className="login-form">
            <label htmlFor="admin-email">Email address</label>
            <div className="input-with-icon"><Mail size={17} /><input autoComplete="username" autoFocus id="admin-email" type="email" placeholder="admin@example.com" value={email} onChange={(event) => setEmail(event.target.value)} required /></div>
            <label htmlFor="admin-password">Password</label>
            <div className="input-with-icon"><LockKeyhole size={17} /><input autoComplete="current-password" id="admin-password" type={showPassword ? "text" : "password"} placeholder="Enter your password" value={password} onChange={(event) => setPassword(event.target.value)} required />
              <button className="password-toggle" type="button" onClick={() => setShowPassword(!showPassword)} aria-label={showPassword ? "Hide password" : "Show password"}>{showPassword ? <EyeOff size={17} /> : <Eye size={17} />}</button>
            </div>
            {error && <div className="form-error" role="alert">{error}</div>}
            <button className="button-primary login-submit" disabled={submitting}>{submitting ? "Signing you in…" : "Sign in to dashboard"}{!submitting && <ArrowRight size={17} />}</button>
          </form>
          <div className="login-security"><LockKeyhole size={14} />Secure access for kitchen administrators</div>
        </div>
        <div className="login-legal">© {new Date().getFullYear()} Campus Kitchen <span>·</span> Made for the everyday.</div>
      </section>
    </main>
  );
}
