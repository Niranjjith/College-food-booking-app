import mongoose from 'mongoose';

const inventoryItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true },
    unit: { type: String, required: true, enum: ['kg', 'g', 'L', 'mL', 'pieces', 'packets'] },
    currentStock: { type: Number, required: true, default: 0 },
    minStock: { type: Number, required: true, default: 10 }, // Alert threshold
    maxStock: { type: Number, required: true, default: 100 },
    supplier: String,
    lastRestocked: Date,
    costPerUnit: { type: Number, default: 0 },
    category: { type: String, enum: ['vegetable', 'meat', 'spice', 'beverage', 'grain', 'dairy', 'other'], default: 'other' },
  },
  { timestamps: true }
);

export default mongoose.model('Inventory', inventoryItemSchema);


