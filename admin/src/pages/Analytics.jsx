import { useEffect, useState } from "react";
import { ArrowDownRight, ArrowUpRight, CalendarDays, ChartNoAxesCombined, PackageCheck, ShoppingBag } from "lucide-react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { api, formatCurrency, getErrorMessage } from "../api.js";

function AnalyticsTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null;
  return <div className="chart-tooltip"><span>{label}</span><strong>{payload[0].value} orders</strong></div>;
}

export default function Analytics() {
  const [days, setDays] = useState(30);
  const [forecastDays, setForecastDays] = useState(7);
  const [report, setReport] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError("");
    api.get("/orders/admin/demand-forecast", { params: { days, forecastDays } })
      .then(({ data }) => { if (active) setReport(data); })
      .catch((requestError) => { if (active) setError(getErrorMessage(requestError)); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [days, forecastDays]);

  if (error) return <div className="page-error" role="alert">{error}</div>;
  if (loading || !report) return <div className="page-loading"><span className="spinner" />Finding your rhythm…</div>;
  const forecast = report.forecast.map((item) => ({
    ...item,
    day: new Intl.DateTimeFormat("en-IN", { weekday: "short" }).format(new Date(`${item.date}T12:00:00`)),
  }));

  return <>
    <section className="analytics-banner">
      <div><span className="welcome-pill"><span /> MADE FROM YOUR ORDER HISTORY</span><h2>Look ahead.<br /><em>Plan with a little more ease.</em></h2><p>Use your campus’s own ordering patterns to get ready for what’s next.</p></div>
      <div className="analytics-controls">
        <label><CalendarDays size={15} /><span className="sr-only">History period</span><select value={days} onChange={(event) => setDays(Number(event.target.value))}><option value={7}>Last 7 days</option><option value={30}>Last 30 days</option><option value={90}>Last 90 days</option></select></label>
        <label><ChartNoAxesCombined size={15} /><span className="sr-only">Forecast period</span><select value={forecastDays} onChange={(event) => setForecastDays(Number(event.target.value))}><option value={7}>Next 7 days</option><option value={14}>Next 14 days</option></select></label>
      </div>
    </section>
    <section className="analytics-stat-grid">
      <article className="analytics-stat"><span className="analytics-stat-icon analytics-icon-green"><ShoppingBag size={18} /></span><span className="section-kicker">ORDERS IN THIS PERIOD</span><strong>{report.summary.totalOrders}</strong><small>Paid orders from the last {days} days</small></article>
      <article className="analytics-stat"><span className="analytics-stat-icon analytics-icon-peach"><ArrowUpRight size={18} /></span><span className="section-kicker">DAILY ORDER AVERAGE</span><strong>{report.summary.avgDailyOrders}</strong><small>Orders on an average day</small></article>
      <article className="analytics-stat"><span className="analytics-stat-icon analytics-icon-lavender"><ChartNoAxesCombined size={18} /></span><span className="section-kicker">DAILY REVENUE AVERAGE</span><strong>{formatCurrency(report.summary.avgDailyRevenue)}</strong><small>From paid orders</small></article>
      <article className="analytics-stat"><span className="analytics-stat-icon analytics-icon-yellow"><PackageCheck size={18} /></span><span className="section-kicker">DAILY ITEMS AVERAGE</span><strong>{report.summary.avgDailyItems}</strong><small>Items sold per day</small></article>
    </section>
    <section className="panel forecast-panel">
      <div className="panel-heading"><div><span className="section-kicker">A HELPFUL HEAD START</span><h3>Expected orders</h3></div><span className="forecast-badge"><span />Forecast · {forecastDays} days</span></div>
      {forecast.length ? <div className="forecast-chart"><ResponsiveContainer width="100%" height="100%">
        <BarChart data={forecast} margin={{ top: 10, right: 8, left: -16, bottom: 0 }}>
          <CartesianGrid stroke="#e9ece5" vertical={false} strokeDasharray="3 5" /><XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: "#91998e", fontSize: 11 }} dy={9} /><YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fill: "#91998e", fontSize: 11 }} /><Tooltip content={<AnalyticsTooltip />} cursor={{ fill: "#eff3ec" }} />
          <Bar dataKey="predictedOrders" name="Expected orders" radius={[6, 6, 2, 2]} maxBarSize={38}>{forecast.map((entry, index) => <Cell key={entry.date} fill={index === 0 ? "#91b8a1" : "#286b50"} />)}</Bar>
        </BarChart>
      </ResponsiveContainer></div> : <div className="popular-empty">There isn’t enough order history to build a forecast just yet.</div>}
    </section>
    <section className="panel forecast-detail-panel">
      <div className="panel-heading"><div><span className="section-kicker">WHAT’S COOKING</span><h3>Foods to keep an eye on</h3></div><span className="panel-caption">Based on {days} days of orders</span></div>
      {report.topPredictedFoods.length ? <div className="demand-list">{report.topPredictedFoods.map((food, index) => {
        const rising = food.trend > 0;
        return <div className="demand-row" key={food.foodId}><span className={`demand-number${index < 3 ? " demand-number-top" : ""}`}>{String(index + 1).padStart(2, "0")}</span><span className="demand-food"><strong>{food.name}</strong><small>{food.totalOrders} orders · {food.totalQty} items sold</small></span><span className={`demand-trend${rising ? " trend-up" : " trend-down"}`}>{rising ? <ArrowUpRight size={15} /> : <ArrowDownRight size={15} />}{rising ? "Rising" : "Steady"}</span><span className="demand-forecast">{Math.round(food.predictedDailyQty)}<small> est. daily</small></span></div>;
      })}</div> : <div className="popular-empty">Once paid orders come in, we’ll highlight the campus favourites here.</div>}
      <div className="forecast-footnote">Forecasts are estimates from recent ordering patterns—not a promise of future demand.</div>
    </section>
  </>;
}
