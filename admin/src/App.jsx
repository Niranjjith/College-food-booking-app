import { useEffect, useState } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { api, setAuthToken } from "./api.js";
import Layout from "./components/Layout.jsx";
import Analytics from "./pages/Analytics.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import Feedback from "./pages/Feedback.jsx";
import Foods from "./pages/Foods.jsx";
import Inventory from "./pages/Inventory.jsx";
import Kitchen from "./pages/Kitchen.jsx";
import Login from "./pages/Login.jsx";
import Orders from "./pages/Orders.jsx";

export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const token = sessionStorage.getItem("adminToken");
    if (!token) {
      setChecking(false);
      return;
    }

    let active = true;
    setAuthToken(token);
    api.get("/auth/me")
      .then(({ data }) => {
        if (active && data.role === "admin") setUser(data);
        else if (active) setAuthToken(null);
      })
      .catch(() => { if (active) setAuthToken(null); })
      .finally(() => { if (active) setChecking(false); });
    return () => { active = false; };
  }, []);

  function signOut() {
    setAuthToken(null);
    setUser(null);
  }

  if (checking) return <div className="loading-screen"><span className="loading-mark">ck</span>Getting your kitchen ready…</div>;

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/" replace /> : <Login onLogin={setUser} />} />
      <Route element={user ? <Layout user={user} onSignOut={signOut} /> : <Navigate to="/login" replace />}>
        <Route index element={<Dashboard />} />
        <Route path="kitchen" element={<Kitchen />} />
        <Route path="orders" element={<Orders />} />
        <Route path="foods" element={<Foods />} />
        <Route path="inventory" element={<Inventory />} />
        <Route path="feedback" element={<Feedback />} />
        <Route path="analytics" element={<Analytics />} />
      </Route>
      <Route path="*" element={<Navigate to={user ? "/" : "/login"} replace />} />
    </Routes>
  );
}
