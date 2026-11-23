import { useEffect, useMemo, useState } from "react";
import { ImagePlus, Plus, Search, UtensilsCrossed, X } from "lucide-react";
import { useOutletContext } from "react-router-dom";
import { api, formatCurrency, getErrorMessage } from "../api.js";

const emptyForm = {
  name: "", category: "", description: "", price: "", image: "", preparationTime: 15, available: true,
};

function FoodDialog({ food, onClose, onSave }) {
  const [form, setForm] = useState(food ? {
    name: food.name || "", category: food.category || "", description: food.description || "",
    price: food.price ?? "", image: food.image || "", preparationTime: food.preparationTime || 15,
    available: food.available !== false,
  } : emptyForm);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function setField(event) {
    const { name, value, type, checked } = event.target;
    setForm((current) => ({ ...current, [name]: type === "checkbox" ? checked : value }));
  }

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setError("");
    try {
      await onSave({ ...form, price: Number(form.price), preparationTime: Number(form.preparationTime) });
      onClose();
    } catch (requestError) {
      setError(getErrorMessage(requestError));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && onClose()}>
      <section className="food-modal" role="dialog" aria-modal="true" aria-labelledby="food-modal-title">
        <div className="modal-heading"><div><span className="section-kicker">{food ? "A LITTLE MENU REFRESH" : "SOMETHING DELICIOUS"}</span><h2 id="food-modal-title">{food ? "Edit this dish" : "Add to the menu"}</h2></div><button className="icon-button" onClick={onClose} aria-label="Close dialog"><X size={19} /></button></div>
        <form className="food-form" onSubmit={submit}>
          <label className="image-url-field"><span className="image-url-icon"><ImagePlus size={20} /></span><span className="input-copy"><strong>Food photo</strong><small>Add an image URL (optional)</small></span><input name="image" type="url" placeholder="https://…" value={form.image} onChange={setField} /></label>
          <div className="form-grid">
            <label className="form-field form-span"><span>Dish name</span><input name="name" value={form.name} onChange={setField} placeholder="e.g. Garden harvest bowl" required maxLength={100} /></label>
            <label className="form-field"><span>Category</span><input name="category" value={form.category} onChange={setField} placeholder="e.g. Bowls" required maxLength={50} /></label>
            <label className="form-field"><span>Price <small>in INR</small></span><input name="price" type="number" min="0" step="0.01" value={form.price} onChange={setField} placeholder="120" required /></label>
            <label className="form-field"><span>Prep time <small>minutes</small></span><input name="preparationTime" type="number" min="1" max="240" value={form.preparationTime} onChange={setField} required /></label>
            <label className="form-field form-span"><span>A little description</span><textarea name="description" rows="3" value={form.description} onChange={setField} placeholder="What makes this one a favourite?" maxLength={300} /></label>
          </div>
          <label className="availability-switch"><input type="checkbox" name="available" checked={form.available} onChange={setField} /><span className="switch-track" /><span><strong>Available to order</strong><small>Show this dish in the student app menu.</small></span></label>
          {error && <div className="form-error" role="alert">{error}</div>}
          <div className="modal-actions"><button className="button-secondary" type="button" onClick={onClose}>Cancel</button><button className="button-primary" disabled={saving}>{saving ? "Saving…" : food ? "Save changes" : "Add dish"}</button></div>
        </form>
      </section>
    </div>
  );
}

export default function Foods() {
  const { notify } = useOutletContext();
  const [foods, setFoods] = useState([]);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("All dishes");
  const [dialogFood, setDialogFood] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    api.get("/foods")
      .then(({ data }) => { if (active) setFoods(data); })
      .catch((requestError) => { if (active) setError(getErrorMessage(requestError)); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  const categories = useMemo(() => ["All dishes", ...new Set(foods.map((food) => food.category).filter(Boolean))], [foods]);
  const visibleFoods = foods.filter((food) =>
    (category === "All dishes" || food.category === category) &&
    `${food.name} ${food.category}`.toLowerCase().includes(search.trim().toLowerCase()));
  const availableCount = foods.filter((food) => food.available !== false).length;

  async function saveFood(payload) {
    const { data } = dialogFood
      ? await api.put(`/foods/${dialogFood._id}`, payload)
      : await api.post("/foods", payload);
    setFoods((current) => dialogFood
      ? current.map((food) => food._id === dialogFood._id ? data : food)
      : [data, ...current]);
    notify(dialogFood ? "Menu item updated." : "New dish added to the menu.");
  }

  async function deleteFood(food) {
    if (!window.confirm(`Remove "${food.name}" from the menu?`)) return;
    try {
      await api.delete(`/foods/${food._id}`);
      setFoods((current) => current.filter((item) => item._id !== food._id));
      notify("Dish removed from the menu.");
    } catch (requestError) {
      setError(getErrorMessage(requestError));
      notify(getErrorMessage(requestError));
    }
  }

  return <>
    <section className="menu-summary"><div className="menu-summary-copy"><span className="menu-summary-icon"><UtensilsCrossed size={19} /></span><span><strong>{availableCount} dishes ready to order</strong><small>Curated for good days on campus.</small></span></div><button className="button-primary add-food-button" onClick={() => { setDialogFood(null); setDialogOpen(true); }}><Plus size={17} />Add a dish</button></section>
    <section className="menu-toolbar">
      <div className="category-tabs">{categories.map((item) => <button key={item} className={`category-tab${category === item ? " category-tab-active" : ""}`} onClick={() => setCategory(item)}>{item}</button>)}</div>
      <label className="search-field"><Search size={16} /><span className="sr-only">Search menu</span><input placeholder="Find a dish…" value={search} onChange={(event) => setSearch(event.target.value)} /></label>
    </section>
    {error && <div className="inline-error" role="alert">{error}</div>}
    {loading ? <div className="page-loading"><span className="spinner" />Setting the table…</div> : visibleFoods.length ? (
      <section className="food-grid">{visibleFoods.map((food, index) => (
        <article className="food-card" key={food._id}>
          <div className={`food-image food-image-${index % 4}`}>
            {food.image ? <img src={food.image} alt={food.name} /> : <span><UtensilsCrossed size={28} /></span>}
            <span className={`food-availability${food.available === false ? " unavailable" : ""}`}><span />{food.available === false ? "Unavailable" : "Available"}</span>
            <span className="food-time">{food.preparationTime || 15} min</span>
          </div>
          <div className="food-card-body"><div className="food-category">{food.category || "Fresh from the kitchen"}</div><div className="food-title-row"><h3>{food.name}</h3><strong>{formatCurrency(food.price)}</strong></div><p>{food.description || "A campus favourite, made fresh for you."}</p>
            <div className="food-card-actions"><button className="button-secondary food-edit" onClick={() => { setDialogFood(food); setDialogOpen(true); }}>Edit dish</button><button className="delete-button" onClick={() => deleteFood(food)}>Remove</button></div>
          </div>
        </article>
      ))}</section>
    ) : <div className="empty-menu"><span className="empty-icon"><UtensilsCrossed size={21} /></span><h3>No dishes found</h3><p>Try another search, or add something new to the menu.</p></div>}
    {dialogOpen && <FoodDialog food={dialogFood} onClose={() => setDialogOpen(false)} onSave={saveFood} />}
  </>;
}
