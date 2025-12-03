import mongoose from 'mongoose';

const subscriptionItemSchema = new mongoose.Schema(
  {
    food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food', required: true },
    name: String,
    price: Number,
    qty: { type: Number, default: 1 },
    daysOfWeek: [Number], // 0 = Sunday, 1 = Monday, etc.
  },
  { _id: false }
);

const subscriptionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, default: 'Weekly Meal Plan' },
    items: [subscriptionItemSchema],
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    totalPrice: { type: Number, required: true },
    status: { type: String, enum: ['active', 'paused', 'cancelled', 'completed'], default: 'active' },
    autoRenew: { type: Boolean, default: false },
    pickupTime: String, // e.g., "12:00", "18:00"
    nextOrderDate: Date,
  },
  { timestamps: true }
);

export default mongoose.model('Subscription', subscriptionSchema);

