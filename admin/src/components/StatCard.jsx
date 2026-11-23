import { ArrowUpRight } from "lucide-react";

export default function StatCard({ label, value, note, icon: Icon, tone }) {
  return (
    <article className={`stat-card stat-${tone}`}>
      <div className="stat-top"><span className="stat-icon"><Icon size={18} /></span><span className="stat-note">{note}</span></div>
      <div className="stat-label">{label}</div>
      <div className="stat-bottom"><strong>{value}</strong><ArrowUpRight size={17} /></div>
    </article>
  );
}
