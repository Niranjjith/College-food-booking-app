import { useEffect, useMemo, useState } from "react";
import { CalendarDays, Search, ShoppingBag } from "lucide-react";
import { useOutletContext } from "react-router-dom";
import { api, getErrorMessage, localDateKey } from "../api.js";
import OrderTable from "../components/OrderTable.jsx";

const filters = ["all", "pending", "paid", "preparing", "ready", "completed", "cancelled"];

export default function Orders() {
  const { notify } = useOutletContext();
  const [date, setDate] = useState(() => localDateKey(new Date()));
  const [orders, setOrders] = useState([]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [updating, setUpdating] = useState("");

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError("");
    api.get("/orders/admin/daily", { params: { date } })
      .then(({ data }) => { if (active) setOrders(data.orders); })
      .catch((requestError) => { if (active) setError(getErrorMessage(requestError)); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [date]);

  const visibleOrders = useMemo(() => orders.filter((order) => {
    const term = search.trim().toLowerCase();
    return (filter === "all" || order.status === filter) && (!term ||
      order.user?.name?.toLowerCase().includes(term) ||
      order.user?.email?.toLowerCase().includes(term) ||
      order.items?.some((item) => item.name?.toLowerCase().includes(term)) ||
      order._id?.toLowerCase().includes(term));
  }), [orders, filter, search]);

  async function changeStatus(order, status) {
    if (status === order.status) return;
    setUpdating(order._id);
    try {
      const updated = status === "paid"
        ? await api.patch(`/orders/${order._id}/mark-paid`)
        : await api.patch(`/queue/order/${order._id}/status`, { status });
      setOrders((current) => current.map((item) => item._id === order._id ? updated.data : item));
      notify(`Order updated to ${status}.`);
    } catch (requestError) {
      setError(getErrorMessage(requestError));
      notify(getErrorMessage(requestError));
    } finally {
      setUpdating("");
    }
  }

  return <>
    <section className="orders-toolbar">
      <div className="orders-intro"><span className="orders-icon"><ShoppingBag size={19} /></span><span><strong>{orders.length} orders</strong><small>on the selected day</small></span></div>
      <div className="orders-controls">
        <label className="date-picker"><CalendarDays size={16} /><span className="sr-only">Filter orders by date</span><input type="date" value={date} onChange={(event) => setDate(event.target.value)} /></label>
        <label className="search-field"><Search size={16} /><span className="sr-only">Search orders</span><input placeholder="Search orders…" value={search} onChange={(event) => setSearch(event.target.value)} /></label>
      </div>
    </section>
    <div className="filter-row" aria-label="Filter by status">{filters.map((status) => (
      <button key={status} className={`filter-chip${filter === status ? " filter-active" : ""}`} onClick={() => setFilter(status)}>
        {status === "all" ? "All orders" : status}{status === "all" && <span>{orders.length}</span>}
      </button>
    ))}</div>
    {error && <div className="inline-error" role="alert">{error}</div>}
    <section className="panel orders-panel">
      <div className="panel-heading"><div><span className="section-kicker">YOUR SERVICE, AT A GLANCE</span><h3>Order activity</h3></div><span className="panel-caption">{date === localDateKey(new Date()) ? "Today" : date}</span></div>
      {loading ? <div className="page-loading"><span className="spinner" />Loading orders…</div> : <OrderTable orders={visibleOrders} onStatusChange={changeStatus} updatingOrderId={updating} />}
    </section>
  </>;
}
