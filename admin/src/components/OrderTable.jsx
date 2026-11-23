import { ArrowUpRight, ChevronDown } from "lucide-react";
import { formatCurrency } from "../api.js";

const nextStatuses = {
  pending: ["paid", "cancelled"],
  paid: ["preparing", "cancelled"],
  preparing: ["ready", "cancelled"],
  ready: ["completed"],
  completed: [],
  cancelled: [],
};
const orderTime = (value) => value
  ? new Intl.DateTimeFormat("en-IN", { hour: "numeric", minute: "2-digit" }).format(new Date(value))
  : "—";

export function StatusBadge({ status = "pending" }) {
  return <span className={`status-badge status-${status}`}><span />{status}</span>;
}

export default function OrderTable({ orders, onStatusChange, updatingOrderId }) {
  if (!orders.length) return (
    <div className="empty-table"><span className="empty-icon"><ArrowUpRight size={20} /></span><strong>No orders to show</strong><span>New campus orders will appear here.</span></div>
  );

  return (
    <div className="table-scroll">
      <table className="data-table">
        <thead><tr><th>ORDER</th><th>CUSTOMER</th><th>ITEMS</th><th>AMOUNT</th><th>STATUS</th><th>TIME</th>{onStatusChange && <th aria-label="Update status" />}</tr></thead>
        <tbody>
          {orders.map((order) => {
            const name = order.user?.name || "Campus customer";
            return (
              <tr key={order._id}>
                <td><span className="order-number">#{order._id.slice(-6).toUpperCase()}</span></td>
                <td><div className="customer-cell"><span className="customer-avatar">{name.charAt(0).toUpperCase()}</span><span><strong>{name}</strong><small>{order.user?.email || "Student"}</small></span></div></td>
                <td><span className="item-cell">{order.items?.slice(0, 2).map((item) => `${item.name} × ${item.qty}`).join(", ")}{(order.items?.length || 0) > 2 && ` +${order.items.length - 2}`}</span></td>
                <td><strong className="amount-cell">{formatCurrency(order.subtotal)}</strong></td>
                <td><StatusBadge status={order.status} /></td>
                <td className="time-cell">{orderTime(order.createdAt)}</td>
                {onStatusChange && <td>
                  <label className="status-select-wrap"><span className="sr-only">Update order status</span>
                    {nextStatuses[order.status]?.length ? (
                      <select className="status-select" value={order.status} disabled={updatingOrderId === order._id} onChange={(event) => onStatusChange(order, event.target.value)}>
                        <option value={order.status}>{order.status}</option>
                        {nextStatuses[order.status].map((status) => <option key={status} value={status}>{status}</option>)}
                      </select>
                    ) : <span className="status-final">{order.status}</span>}
                    {nextStatuses[order.status]?.length > 0 && <ChevronDown size={13} />}
                  </label>
                </td>}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
