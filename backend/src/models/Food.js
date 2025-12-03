import mongoose from 'mongoose';

const foodSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    price: { type: Number, required: true, min: 0 },
    category: { type: String, default: 'General' },
    imageUrl: { type: String, default: '' },
    isAvailable: { type: Boolean, default: true },
    preparationTime: { type: Number, default: 15, min: 1 }, // in minutes
    popularity: { type: Number, default: 0 }, // for recommendations
    tags: [String], // for filtering and recommendations
  },
  { timestamps: true }
);

export default mongoose.model('Food', foodSchema);
