import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, Boxes, CirclePlus, PackageCheck, Search, X } from "lucide-react";
import { useOutletContext } from "react-router-dom";
import { api, getErrorMessage } from "../api.js";

const units = ["kg", "g", "L", "mL", "pieces", "packets"];
const categories = ["vegetable", "meat", "spice", "beverage", "grain", "dairy", "other"];
const emptyItem = { name: "", unit: "pieces", currentStock: 0, minStock: 10, maxStock: 100, category: "other", supplier: "", costPerUnit: 0 };

function InventoryDialog({ item, onClose, onSave, restockItem, onRestock }) {
  const [form, setForm] = useState(item ? {
    name: item.name, unit: item.unit, currentStock: item.currentStock,
    minStock: item.minStock, maxStock: item.maxStock, category: item.category || "other",
    supplier: item.supplier || "", costPerUnit: item.costPerUnit || 0,
  } : emptyItem);
  const [quantity, setQuantity] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError("");
    try {
      if (restockItem) await onRestock(Number(quantity));
      else await onSave({
        ...form,
        currentStock: Number(form.currentStock),
        minStock: Number(form.minStock),
        maxStock: Number(form.maxStock),
        costPerUnit: Number(form.costPerUnit),
      });
      onClose();
    } catch (requestError) {
      setError(getErrorMessage(requestError));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="food-modal inventory-modal" role="dialog" aria-modal="true" aria-labelledby="inventory-dialog-title">
        <div className="modal-heading"><div><span className="section-kicker">{restockItem ? "KEEP THE KITCHEN READY" : "KITCHEN STOCK"}</span><h2 id="inventory-dialog-title">{restockItem ? `Restock ${restockItem.name}` : item ? "Edit ingredient" : "Add inventory item"}</h2></div><button className="icon-button" onClick={onClose} aria-label="Close dialog"><X size={19} /></button></div>
        <form className="food-form" onSubmit={submit}>
          {restockItem ? (
            <>
              <p className="inventory-current-stock">On hand: <strong>{restockItem.currentStock} {restockItem.unit}</strong> · maximum {restockItem.maxStock} {restockItem.unit}</p>
              <label className="form-field"><span>Quantity to add <small>{restockItem.unit}</small></span><input type="number" min="0.01" step="any" value={quantity} onChange={(event) => setQuantity(event.target.value)} autoFocus required /></label>
            </>
          ) : (
            <div className="form-grid">
              <label className="form-field form-span"><span>Ingredient name</span><input value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} maxLength={100} required /></label>
              <label className="form-field"><span>Unit</span><select value={form.unit} onChange={(event) => setForm({ ...form, unit: event.target.value })}>{units.map((unit) => <option key={unit}>{unit}</option>)}</select></label>
              <label className="form-field"><span>Category</span><select value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value })}>{categories.map((category) => <option key={category}>{category}</option>)}</select></label>
              <label className="form-field"><span>Current stock</span><input type="number" min="0" step="any" value={form.currentStock} onChange={(event) => setForm({ ...form, currentStock: event.target.value })} required /></label>
              <label className="form-field"><span>Low-stock alert at</span><input type="number" min="0" step="any" value={form.minStock} onChange={(event) => setForm({ ...form, minStock: event.target.value })} required /></label>
              <label className="form-field"><span>Maximum stock</span><input type="number" min="0" step="any" value={form.maxStock} onChange={(event) => setForm({ ...form, maxStock: event.target.value })} required /></label>
              <label className="form-field"><span>Cost per unit <small>INR</small></span><input type="number" min="0" step="any" value={form.costPerUnit} onChange={(event) => setForm({ ...form, costPerUnit: event.target.value })} /></label>
              <label className="form-field form-span"><span>Supplier <small>optional</small></span><input value={form.supplier} onChange={(event) => setForm({ ...form, supplier: event.target.value })} maxLength={120} /></label>
            </div>
          )}
          {error && <div className="form-error" role="alert">{error}</div>}
          <div className="modal-actions"><button className="button-secondary" type="button" onClick={onClose}>Cancel</button><button className="button-primary" disabled={busy || (restockItem && Number(quantity) <= 0)}>{busy ? "Saving…" : restockItem ? "Record restock" : item ? "Save changes" : "Add item"}</button></div>
        </form>
      </section>
    </div>
  );
}

export default function Inventory() {
  const { notify } = useOutletContext();
  const [items, setItems] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [search, setSearch] = useState("");
  const [dialogItem, setDialogItem] = useState(null);
  const [restockItem, setRestockItem] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  async function loadInventory() {
    setError("");
    try {
      const [inventoryResponse, alertsResponse] = await Promise.all([
        api.get("/inventory"),
        api.get("/inventory/alerts"),
      ]);
      setItems(inventoryResponse.data);
      setAlerts(alertsResponse.data.alerts);
    } catch (requestError) {
      setError(getErrorMessage(requestError));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { loadInventory(); }, []);

  const visibleItems = useMemo(
    () => items.filter((item) => `${item.name} ${item.category} ${item.supplier || ""}`.toLowerCase().includes(search.trim().toLowerCase())),
    [items, search],
  );

  async function saveItem(payload) {
    const { data } = dialogItem
      ? await api.put(`/inventory/${dialogItem._id}`, payload)
      : await api.post("/inventory", payload);
    setItems((current) => dialogItem
      ? current.map((item) => item._id === dialogItem._id ? data : item)
      : [...current, data].sort((a, b) => a.name.localeCompare(b.name)));
    await loadInventory();
    notify(dialogItem ? "Inventory details updated." : "Inventory item added.");
  }

  async function restock(quantity) {
    const { data } = await api.patch(`/inventory/${restockItem._id}/restock`, { quantity });
    setItems((current) => current.map((item) => item._id === restockItem._id ? data : item));
    await loadInventory();
    notify(`${restockItem.name} restocked.`);
  }

  async function deleteItem(item) {
    if (!window.confirm(`Remove ${item.name} from inventory?`)) return;
    try {
      await api.delete(`/inventory/${item._id}`);
      setItems((current) => current.filter((entry) => entry._id !== item._id));
      await loadInventory();
      notify(`${item.name} removed from inventory.`);
    } catch (requestError) {
      setError(getErrorMessage(requestError));
      notify(getErrorMessage(requestError));
    }
  }

  return <>
    <section className="inventory-summary">
      <div className="inventory-summary-copy"><span className="inventory-summary-icon"><Boxes size={20} /></span><span><strong>Stock that keeps service flowing</strong><small>{items.length} ingredients tracked · {alerts.length} need attention</small></span></div>
      <button className="button-primary" onClick={() => { setDialogItem(null); setRestockItem(null); setDialogOpen(true); }}><CirclePlus size={16} />Add ingredient</button>
    </section>

    <section className={`inventory-alerts${alerts.length ? " has-alerts" : ""}`}>
      <div className="inventory-alert-heading"><span className="alert-icon"><AlertTriangle size={17} /></span><div><strong>{alerts.length ? `${alerts.length} low-stock ${alerts.length === 1 ? "item" : "items"}` : "Stock levels look good"}</strong><small>{alerts.length ? "Restock soon to avoid menu interruptions." : "We’ll flag ingredients when they reach their minimum."}</small></div></div>
      {alerts.length > 0 && <div className="alert-chips">{alerts.slice(0, 4).map((alert) => <span key={alert.id}>{alert.name}<strong>{alert.currentStock} {alert.unit}</strong></span>)}</div>}
    </section>

    <section className="inventory-toolbar">
      <div><span className="section-kicker">INGREDIENTS</span><h3>Inventory overview</h3></div>
      <label className="search-field"><Search size={16} /><span className="sr-only">Search inventory</span><input placeholder="Search inventory…" value={search} onChange={(event) => setSearch(event.target.value)} /></label>
    </section>
    {error && <div className="inline-error" role="alert">{error}</div>}
    <section className="panel inventory-panel">
      {loading ? <div className="page-loading"><span className="spinner" />Counting what’s in stock…</div> : visibleItems.length ? (
        <div className="table-scroll"><table className="data-table inventory-table">
          <thead><tr><th>INGREDIENT</th><th>IN STOCK</th><th>LEVEL</th><th>CATEGORY</th><th>SUPPLIER</th><th aria-label="Actions" /></tr></thead>
          <tbody>{visibleItems.map((item) => {
            const low = item.currentStock <= item.minStock;
            const percent = item.maxStock > 0 ? Math.min(100, Math.max(0, item.currentStock / item.maxStock * 100)) : 0;
            return <tr key={item._id}>
              <td><div className="inventory-name"><span className={`inventory-item-icon${low ? " inventory-item-low" : ""}`}><PackageCheck size={16} /></span><span><strong>{item.name}</strong><small>Min. {item.minStock} {item.unit}</small></span></div></td>
              <td><strong className={low ? "stock-low" : "stock-good"}>{item.currentStock} {item.unit}</strong>{low && <span className="stock-alert-label">Restock soon</span>}</td>
              <td><div className="stock-meter"><span className={low ? "meter-low" : ""} style={{ width: `${percent}%` }} /></div><small className="stock-meter-caption">{Math.round(percent)}% of max</small></td>
              <td><span className="category-pill">{item.category}</span></td>
              <td className="inventory-supplier">{item.supplier || "—"}</td>
              <td><div className="inventory-actions"><button className="button-secondary restock-button" onClick={() => { setRestockItem(item); setDialogItem(null); setDialogOpen(true); }}>Restock</button><button className="inventory-icon-action" onClick={() => { setDialogItem(item); setRestockItem(null); setDialogOpen(true); }} aria-label={`Edit ${item.name}`}>Edit</button><button className="inventory-icon-action delete-action" onClick={() => deleteItem(item)} aria-label={`Delete ${item.name}`}>Remove</button></div></td>
            </tr>;
          })}</tbody>
        </table></div>
      ) : <div className="empty-menu"><span className="empty-icon"><Boxes size={21} /></span><h3>No inventory items found</h3><p>Add ingredients to start tracking stock.</p></div>}
    </section>
    {dialogOpen && <InventoryDialog item={dialogItem} restockItem={restockItem} onClose={() => setDialogOpen(false)} onSave={saveItem} onRestock={restock} />}
  </>;
}
