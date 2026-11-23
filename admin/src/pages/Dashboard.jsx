import { useEffect, useState } from "react";
import { ArrowRight, CalendarDays, CookingPot, IndianRupee, ShoppingBag, UsersRound } from "lucide-react";
import { Link } from "react-router-dom";
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { api, formatCurrency, getErrorMessage, localDateKey } from "../api.js";
import OrderTable from "../components/OrderTable.jsx";
import StatCard from "../components/StatCard.jsx";

function salesWeek(trend) {
  const values = new Map(trend.map((entry) => [entry._id, entry.total]));
  return Array.from({ length: 7 }, (_, index) => {
    const day = new Date();
    day.setDate(day.getDate() - (6 - index));
    return {
      day: new Intl.DateTimeFormat("en-IN", { weekday: "short" }).format(day),
      date: localDateKey(day),
      revenue: values.get(localDateKey(day)) || 0,
    };
  });
}

function ChartTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return <div className="chart-tooltip"><span>{label}</span><strong>{formatCurrency(payload[0].value)}</strong></div>;
}

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    Promise.all([
      api.get("/orders/admin/summary"),
      api.get("/orders/admin/daily", { params: { date: localDateKey(new Date()) } }),
      api.get("/orders/admin/sales-trend"),
    ]).then(([summary, daily, trend]) => {
      if (active) setData({ summary: summary.data, daily: daily.data, trend: salesWeek(trend.data) });
    }).catch((requestError) => {
      if (active) setError(getErrorMessage(requestError));
    });
    return () => { active = false; };
  }, []);

  if (error) return <div className="page-error" role="alert">{error}</div>;
  if (!data) return <div className="page-loading"><span className="spinner" />Loading your overview…</div>;

  const popular = new Map();
  data.daily.orders.forEach((order) => order.items.forEach((item) => popular.set(item.name, (popular.get(item.name) || 0) + item.qty)));
  const topFoods = [...popular.entries()].sort((a, b) => b[1] - a[1]).slice(0, 4);

  return <>
    <section className="welcome-banner">
      <div className="welcome-copy">
        <span className="welcome-pill"><span /> KITCHEN IS OPEN</span>
        <h2>A little overview,<br /><em>a lot to feel good about.</em></h2>
        <p>Your team is doing great. Here’s the latest from your campus kitchen.</p>
      </div>
      <div className="welcome-illustration" aria-hidden="true"><div className="welcome-sun" /><div className="welcome-plate"><span /><span /><span /></div><div className="welcome-sprig sprig-one">✳</div><div className="welcome-sprig sprig-two">✦</div><div className="welcome-leaf">⌁</div></div>
      <div className="banner-bottom"><CalendarDays size={14} />A fresh day, a fresh start.</div>
    </section>
    <section className="stat-grid" aria-label="Kitchen statistics">
      <StatCard label="Today’s orders" value={data.daily.count} note="TODAY" icon={ShoppingBag} tone="green" />
      <StatCard label="Total menu items" value={data.summary.foods} note="ON THE MENU" icon={CookingPot} tone="peach" />
      <StatCard label="Campus community" value={data.summary.users} note="REGISTERED" icon={UsersRound} tone="lavender" />
      <StatCard label="All-time revenue" value={formatCurrency(data.summary.revenue)} note="PAID ORDERS" icon={IndianRupee} tone="yellow" />
    </section>
    <section className="dashboard-grid">
      <article className="panel sales-panel">
        <div className="panel-heading"><div><span className="section-kicker">THE BIG PICTURE</span><h3>Sales over the week</h3></div><span className="panel-caption">Last 7 days <ArrowRight size={14} /></span></div>
        <div className="chart-legend"><span /><span>Daily revenue</span></div>
        <div className="sales-chart"><ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data.trend} margin={{ top: 12, right: 4, left: -18, bottom: 0 }}>
            <defs><linearGradient id="salesFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#2c7658" stopOpacity={0.2} /><stop offset="100%" stopColor="#2c7658" stopOpacity={0} /></linearGradient></defs>
            <CartesianGrid stroke="#e9ece5" vertical={false} strokeDasharray="3 5" />
            <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: "#91998e", fontSize: 11 }} dy={10} />
            <YAxis axisLine={false} tickLine={false} tick={{ fill: "#91998e", fontSize: 11 }} tickFormatter={(value) => value === 0 ? "₹0" : `₹${value}`} />
            <Tooltip content={<ChartTooltip />} />
            <Area type="monotone" dataKey="revenue" stroke="#286b50" strokeWidth={2.5} fill="url(#salesFill)" activeDot={{ r: 5, fill: "#286b50", stroke: "#fff", strokeWidth: 3 }} />
          </AreaChart>
        </ResponsiveContainer></div>
      </article>
      <article className="panel popular-panel">
        <div className="panel-heading"><div><span className="section-kicker">THE CROWD FAVOURITES</span><h3>Popular today</h3></div><span className="popular-spark">✳</span></div>
        {topFoods.length ? <div className="popular-list">{topFoods.map(([name, count], index) => (
          <div className="popular-row" key={name}><span className={`popular-rank rank-${index + 1}`}>0{index + 1}</span><span className="popular-name">{name}</span><span className="popular-count">{count} ordered</span></div>
        ))}</div> : <div className="popular-empty">The first orders of the day are just around the corner.</div>}
        <Link className="text-link" to="/foods">Explore the menu <ArrowRight size={15} /></Link>
      </article>
    </section>
    <section className="panel recent-panel">
      <div className="panel-heading recent-heading"><div><span className="section-kicker">FRESH FROM THE COUNTER</span><h3>Recent orders</h3></div><Link className="text-link" to="/orders">All orders <ArrowRight size={15} /></Link></div>
      <OrderTable orders={data.daily.orders.slice(0, 5)} />
    </section>
  </>;
}
