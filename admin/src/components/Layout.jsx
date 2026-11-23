import { useState } from "react";
import {
  Bell, Boxes, ChefHat, ClipboardList, LayoutDashboard, LogOut, Menu,
  MessageSquareText, Salad, TrendingUp, X,
} from "lucide-react";
import { NavLink, Outlet, useLocation } from "react-router-dom";

const navigation = [
  { label: "Overview", to: "/", icon: LayoutDashboard, end: true },
  { label: "Kitchen queue", to: "/kitchen", icon: ChefHat },
  { label: "Orders", to: "/orders", icon: ClipboardList },
  { label: "Food menu", to: "/foods", icon: Salad },
  { label: "Inventory", to: "/inventory", icon: Boxes },
  { label: "Feedback inbox", to: "/feedback", icon: MessageSquareText },
  { label: "Analytics", to: "/analytics", icon: TrendingUp },
];
const titles = {
  "/": ["Good morning", "Here’s what’s happening in your kitchen today."],
  "/kitchen": ["Kitchen queue", "Keep orders moving from the kitchen to pickup."],
  "/orders": ["Orders", "Keep every order moving, from checkout to pickup."],
  "/foods": ["Food menu", "Manage the dishes your campus loves."],
  "/inventory": ["Inventory", "Stay ahead of low stock and keep ingredients ready."],
  "/feedback": ["Feedback inbox", "Listen to students and close the loop with thoughtful replies."],
  "/analytics": ["Analytics", "A clearer view of demand and sales."],
};
const greeting = () => {
  const hour = new Date().getHours();
  return hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";
};
const today = () => new Intl.DateTimeFormat("en-IN", {
  weekday: "long", month: "long", day: "numeric",
}).format(new Date());

export default function Layout({ user, onSignOut }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [notice, setNotice] = useState("");
  const location = useLocation();
  const page = location.pathname === "/"
    ? [greeting(), titles["/"][1]]
    : titles[location.pathname] || ["Kitchen", ""];
  const initials = (user.name || user.email || "A").split(/\s+/).slice(0, 2).map((part) => part[0]).join("").toUpperCase();

  function notify(message) {
    setNotice(message);
    window.setTimeout(() => setNotice(""), 3200);
  }

  return (
    <div className="app-shell">
      {menuOpen && <button className="mobile-backdrop" aria-label="Close navigation" onClick={() => setMenuOpen(false)} />}
      <aside className={`sidebar ${menuOpen ? "sidebar-open" : ""}`}>
        <div className="brand">
          <div className="brand-mark"><ChefHat size={23} /></div>
          <div><div className="brand-name">campus<span>kitchen</span></div><div className="brand-caption">ADMIN CONSOLE</div></div>
          <button className="icon-button sidebar-close" aria-label="Close navigation" onClick={() => setMenuOpen(false)}><X size={18} /></button>
        </div>
        <div className="sidebar-label">WORKSPACE</div>
        <nav className="side-nav" aria-label="Main navigation">
          {navigation.map(({ label, to, icon: Icon, end }) => (
            <NavLink key={to} to={to} end={end}
              className={({ isActive }) => `side-link${isActive ? " side-link-active" : ""}`}
              onClick={() => setMenuOpen(false)}>
              <Icon size={18} /><span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-tip">
            <span className="tip-icon">✳</span>
            <p>Your kitchen,<br /><strong>running smoothly.</strong></p>
            <span>Keep menus fresh and orders flowing.</span>
          </div>
          <div className="sidebar-user">
            <div className="avatar">{initials}</div>
            <div className="sidebar-user-copy"><strong>{user.name || "Kitchen admin"}</strong><span>Administrator</span></div>
            <button className="icon-button signout-button" onClick={onSignOut} title="Sign out" aria-label="Sign out"><LogOut size={17} /></button>
          </div>
        </div>
      </aside>

      <main className="main-panel">
        <header className="topbar">
          <button className="icon-button mobile-menu" onClick={() => setMenuOpen(true)} aria-label="Open navigation"><Menu size={21} /></button>
          <div className="topbar-date"><span className="live-dot" />{today()}</div>
          <div className="topbar-right"><span className="topbar-location"><span>●</span> Campus kitchen</span><div className="avatar avatar-small">{initials}</div></div>
        </header>
        <div className="page-wrap">
          <div className="page-heading">
            <div><div className="eyebrow">{location.pathname === "/" ? "YOUR DAILY BRIEFING" : "CAMPUS KITCHEN"}</div><h1>{page[0]}</h1><p>{page[1]}</p></div>
            <div className="heading-tools"><span className="heading-date">{today()}</span><button className="icon-button notification-button" aria-label="Notifications"><Bell size={19} /><span /></button></div>
          </div>
          <Outlet context={{ notify }} />
        </div>
      </main>
      <div className={`toast${notice ? " toast-visible" : ""}`} role="status">{notice}</div>
    </div>
  );
}
