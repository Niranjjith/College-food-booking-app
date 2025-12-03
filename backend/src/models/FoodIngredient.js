import mongoose from 'mongoose';

const foodIngredientSchema = new mongoose.Schema(
  {
    food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food', required: true },
    ingredient: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory', required: true },
    quantity: { type: Number, required: true }, // Amount needed per serving
    unit: { type: String, required: true },
  },
  { timestamps: true }
);

// Index for faster lookups
foodIngredientSchema.index({ food: 1, ingredient: 1 });

export default mongoose.model('FoodIngredient', foodIngredientSchema);

