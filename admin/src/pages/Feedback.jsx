import { useEffect, useMemo, useState } from "react";
import { MessageSquareText, Search, Send, Star } from "lucide-react";
import { useOutletContext } from "react-router-dom";
import { api, getErrorMessage } from "../api.js";

const statuses = ["all", "open", "in-progress", "resolved", "closed"];
const statusLabels = { all: "All messages", open: "Open", "in-progress": "In progress", resolved: "Resolved", closed: "Closed" };

function timeAgo(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const days = Math.floor((Date.now() - date.getTime()) / 86400000);
  if (days === 0) return "Today";
  if (days === 1) return "Yesterday";
  return `${days} days ago`;
}

export default function Feedback() {
  const { notify } = useOutletContext();
  const [feedback, setFeedback] = useState([]);
  const [stats, setStats] = useState(null);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [drafts, setDrafts] = useState({});
  const [busyId, setBusyId] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  async function loadFeedback() {
    setError("");
    try {
      const [messages, metrics] = await Promise.all([
        api.get("/feedback/admin/all"),
        api.get("/feedback/admin/stats"),
      ]);
      setFeedback(messages.data);
      setStats(metrics.data);
      setDrafts(Object.fromEntries(messages.data.map((item) => [item._id, {
        status: item.status,
        response: item.adminResponse || "",
      }])));
    } catch (requestError) {
      setError(getErrorMessage(requestError));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadFeedback(); }, []);

  const filtered = useMemo(() => feedback.filter((item) => {
    const term = search.trim().toLowerCase();
    const matchesStatus = filter === "all" || item.status === filter;
    return matchesStatus && (!term || `${item.title} ${item.description} ${item.user?.name || ""} ${item.user?.email || ""}`.toLowerCase().includes(term));
  }), [feedback, filter, search]);

  function updateDraft(id, values) {
    setDrafts((current) => ({ ...current, [id]: { ...current[id], ...values } }));
  }

  async function saveResponse(item) {
    const draft = drafts[item._id];
    setBusyId(item._id);
    setError("");
    try {
      const { data } = await api.patch(`/feedback/admin/${item._id}`, {
        status: draft.status,
        adminResponse: draft.response,
      });
      setFeedback((current) => current.map((entry) => entry._id === item._id ? {
        ...entry,
        ...data,
        user: entry.user,
        orderId: entry.orderId,
        foodId: entry.foodId,
      } : entry));
      notify("Feedback response saved.");
    } catch (requestError) {
      setError(getErrorMessage(requestError));
      notify(getErrorMessage(requestError));
    } finally {
      setBusyId("");
    }
  }

  const openCount = stats?.byStatus?.find((entry) => entry._id === "open")?.count || 0;
  const urgentCount = feedback.filter((entry) => ["urgent", "high"].includes(entry.priority)).length;
  const totalCount = stats?.byStatus?.reduce((total, entry) => total + entry.count, 0) || 0;

  return <>
    <section className="feedback-banner">
      <div><span className="welcome-pill"><span /> STUDENT VOICES</span><h2>Listen well.<br /><em>Make campus better.</em></h2><p>Thoughtful replies turn student feedback into a better day for everyone.</p></div>
      <div className="feedback-banner-mark"><MessageSquareText size={36} /><span>✳</span></div>
    </section>

    <section className="feedback-metrics">
      <article><span className="feedback-metric-icon feedback-open-icon"><MessageSquareText size={17} /></span><span><small>Open messages</small><strong>{openCount}</strong></span></article>
      <article><span className="feedback-metric-icon feedback-urgent-icon"><span>!</span></span><span><small>High priority</small><strong>{urgentCount}</strong></span></article>
      <article><span className="feedback-metric-icon feedback-resolved-icon"><Star size={17} /></span><span><small>All submissions</small><strong>{totalCount}</strong></span></article>
    </section>

    <section className="feedback-toolbar">
      <div className="feedback-tabs">{statuses.map((status) => (
        <button key={status} className={`filter-chip${filter === status ? " filter-active" : ""}`} onClick={() => setFilter(status)}>{statusLabels[status]}</button>
      ))}</div>
      <label className="search-field"><Search size={16} /><span className="sr-only">Search feedback</span><input placeholder="Search messages…" value={search} onChange={(event) => setSearch(event.target.value)} /></label>
    </section>
    {error && <div className="inline-error" role="alert">{error}</div>}
    {loading ? <div className="page-loading"><span className="spinner" />Opening the inbox…</div> : filtered.length ? (
      <section className="feedback-list">{filtered.map((item) => {
        const draft = drafts[item._id] || { status: item.status, response: item.adminResponse || "" };
        return <article className="feedback-card" key={item._id}>
          <div className="feedback-card-head">
            <div className="feedback-type-icon"><MessageSquareText size={17} /></div>
            <div className="feedback-title"><div className="feedback-tags"><span className={`feedback-type type-${item.type}`}>{item.type}</span><span>{item.category}</span>{item.priority && item.priority !== "medium" && <span className={`priority-pill priority-${item.priority}`}>{item.priority} priority</span>}</div><h3>{item.title}</h3><p>{item.user?.name || "Campus student"}{item.user?.email ? ` · ${item.user.email}` : ""} · {timeAgo(item.createdAt)}</p></div>
            {item.rating && <div className="feedback-rating"><Star size={13} fill="currentColor" />{item.rating}/5</div>}
          </div>
          <div className="feedback-description">{item.description}</div>
          {item.orderId && <div className="feedback-order-ref">Related order · #{String(item.orderId._id || item.orderId).slice(-6).toUpperCase()}</div>}
          <div className="feedback-response">
            <label className="form-field"><span>Your response</span><textarea rows="2" maxLength={1000} placeholder="Write a helpful reply for the student…" value={draft.response} onChange={(event) => updateDraft(item._id, { response: event.target.value })} /></label>
            <div className="feedback-save-row">
              <label className="feedback-status-select"><span>Status</span><select value={draft.status} onChange={(event) => updateDraft(item._id, { status: event.target.value })}>{statuses.slice(1).map((status) => <option key={status} value={status}>{statusLabels[status]}</option>)}</select></label>
              <button className="button-primary feedback-save" onClick={() => saveResponse(item)} disabled={busyId === item._id}><Send size={14} />{busyId === item._id ? "Saving…" : "Save response"}</button>
            </div>
          </div>
        </article>;
      })}</section>
    ) : <div className="empty-menu"><span className="empty-icon"><MessageSquareText size={21} /></span><h3>Inbox is clear</h3><p>No messages match this filter. New student feedback will show up here.</p></div>}
  </>;
}
