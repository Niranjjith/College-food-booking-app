import mongoose from 'mongoose';

const userPreferenceSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    dietaryRestrictions: [{ type: String, enum: ['vegetarian', 'vegan', 'gluten-free', 'dairy-free', 'nut-free', 'halal', 'kosher'] }],
    favoriteCategories: [String],
    dislikedFoods: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Food' }],
    allergies: [String],
    preferredPriceRange: {
      min: { type: Number, default: 0 },
      max: { type: Number, default: 1000 },
    },
    orderHistory: [{
      food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
      orderDate: Date,
      rating: { type: Number, min: 1, max: 5 },
    }],
  },
  { timestamps: true }
);

export default mongoose.model('UserPreference', userPreferenceSchema);

