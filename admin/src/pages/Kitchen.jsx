import { useEffect, useMemo, useState } from "react";
import { ChefHat, Clock3, RefreshCw, UsersRound } from "lucide-react";
import { useOutletContext } from "react-router-dom";
import { api, getErrorMessage } from "../api.js";
import { StatusBadge } from "../components/OrderTable.jsx";

const nextStatus = {
  paid: ["preparing", "Start preparing"],
  preparing: ["ready", "Mark ready"],
  ready: ["completed", "Complete pickup"],
};
const filters = ["all", "paid", "preparing", "ready"];

function elapsedTime(value) {
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 60000));
  if (minutes < 1) return "Just placed";
  if (minutes < 60) return `${minutes} min ago`;
  return `${Math.floor(minutes / 60)}h ${minutes % 60}m ago`;
}

export default function Kitchen() {
  const { notify } = useOutletContext();
  const [queue, setQueue] = useState([]);
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [updating, setUpdating] = useState("");
  const [error, setError] = useState("");

  async function loadQueue(silent = false) {
    if (silent) setRefreshing(true);
    setError("");
    try {
      const { data } = await api.get("/queue/admin/queue");
      setQueue(data.queue);
    } catch (requestError) {
      setError(getErrorMessage(requestError));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadQueue();
    const timer = window.setInterval(() => loadQueue(true), 25000);
    return () => window.clearInterval(timer);
  }, []);

  async function advance(order) {
    const step = nextStatus[order.status];
    if (!step || updating === order.orderId) return;
    setUpdating(order.orderId);
    try {
      await api.patch(`/queue/order/${order.orderId}/status`, { status: step[0] });
      notify(`${step[1]} — order #${String(order.orderId).slice(-6)}.`);
      await loadQueue(true);
    } catch (requestError) {
      setError(getErrorMessage(requestError));
      notify(getErrorMessage(requestError));
    } finally {
      setUpdating("");
    }
  }

  const filteredQueue = useMemo(
    () => filter === "all" ? queue : queue.filter((order) => order.status === filter),
    [queue, filter],
  );
  const counts = {
    paid: queue.filter((order) => order.status === "paid").length,
    preparing: queue.filter((order) => order.status === "preparing").length,
    ready: queue.filter((order) => order.status === "ready").length,
  };

  return <>
    <section className="queue-banner">
      <div>
        <span className="welcome-pill"><span /> LIVE KITCHEN QUEUE</span>
        <h2>One order at a time.<br /><em>One great meal at a time.</em></h2>
        <p>Keep an eye on what’s cooking and what’s ready for pickup.</p>
      </div>
      <button className="button-secondary queue-refresh" onClick={() => loadQueue(true)} disabled={refreshing}>
        <RefreshCw size={15} className={refreshing ? "spin-icon" : ""} />
        {refreshing ? "Updating" : "Refresh"}
      </button>
    </section>

    <section className="queue-stats">
      <article><span className="queue-stat-icon queue-icon-paid"><Clock3 size={17} /></span><span><small>Waiting to start</small><strong>{counts.paid}</strong></span></article>
      <article><span className="queue-stat-icon queue-icon-preparing"><ChefHat size={17} /></span><span><small>In the kitchen</small><strong>{counts.preparing}</strong></span></article>
      <article><span className="queue-stat-icon queue-icon-ready"><UsersRound size={17} /></span><span><small>Ready for pickup</small><strong>{counts.ready}</strong></span></article>
    </section>

    <div className="queue-toolbar">
      <div className="queue-filters">{filters.map((status) => (
        <button key={status} className={`filter-chip${filter === status ? " filter-active" : ""}`} onClick={() => setFilter(status)}>
          {status === "all" ? "All active" : status}
        </button>
      ))}</div>
      <span className="queue-live-label"><span />Auto-refreshes every 25 seconds</span>
    </div>

    {error && <div className="inline-error" role="alert">{error}</div>}
    {loading ? <div className="page-loading"><span className="spinner" />Checking the kitchen…</div> : filteredQueue.length ? (
      <section className="kitchen-queue">
        {filteredQueue.map((order) => {
          const action = nextStatus[order.status];
          return (
            <article className={`queue-card queue-card-${order.status}`} key={order.orderId}>
              <div className="queue-card-top">
                <div><span className="queue-order-id">ORDER #{String(order.orderId).slice(-6).toUpperCase()}</span><strong>{order.user?.name || "Campus customer"}</strong></div>
                <StatusBadge status={order.status} />
              </div>
              <div className="queue-order-meta"><span><Clock3 size={13} />{elapsedTime(order.createdAt)}</span>{order.preparation?.queuePosition > 0 && <span>Queue #{order.preparation.queuePosition}</span>}</div>
              <div className="queue-items">
                {order.items.map((item, index) => <span key={`${item.name}-${index}`}>{item.name}<strong>× {item.qty}</strong></span>)}
              </div>
              <div className="queue-card-bottom">
                <span className="queue-eta">{order.status === "ready" ? "Ready for pickup" : `~${order.preparation?.remainingTime ?? order.preparation?.estimatedTime ?? 0} min prep`}</span>
                {action && <button className="button-primary queue-action" onClick={() => advance(order)} disabled={updating === order.orderId}>{updating === order.orderId ? "Updating…" : action[1]}</button>}
              </div>
            </article>
          );
        })}
      </section>
    ) : (
      <div className="empty-menu queue-empty"><span className="empty-icon"><ChefHat size={21} /></span><h3>All caught up</h3><p>No {filter === "all" ? "active orders" : `${filter} orders`} in the kitchen right now.</p></div>
    )}
  </>;
}
