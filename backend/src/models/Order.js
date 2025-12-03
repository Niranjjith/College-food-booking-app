import mongoose from 'mongoose';

const orderItemSchema = new mongoose.Schema(
  {
    food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food', required: true },
    name: String,
    price: Number,
    qty: { type: Number, default: 1, min: 1 }
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    items: [orderItemSchema],
    subtotal: { type: Number, required: true },
    status: { 
      type: String, 
      enum: ['pending', 'paid', 'preparing', 'ready', 'completed', 'cancelled'], 
      default: 'pending' 
    },
    payment: {
      provider: { type: String, default: 'stripe' },
      intentId: String,
      paymentId: String,
      paidAt: Date
    },
    preparation: {
      estimatedTime: { type: Number, default: 0 }, // in minutes
      startTime: Date,
      readyTime: Date,
      queuePosition: { type: Number, default: 0 },
      kitchenLoad: { type: Number, default: 0 }, // number of orders being prepared
    },
    billUrl: String,    // link to a PDF/HTML bill (could be generated later)
    qrCode: String,     // QR code data for pickup
    pickupCode: String, // Unique pickup code
    isScheduled: { type: Boolean, default: false },
    scheduledDate: Date,
    subscriptionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subscription' },
  },
  { timestamps: true }
);

export default mongoose.model('Order', orderSchema);
