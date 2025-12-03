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
    status: { type: String, enum: ['pending', 'paid', 'cancelled'], default: 'pending' },
    payment: {
      provider: { type: String, default: 'stripe' },
      intentId: String,
      paymentId: String,
      paidAt: Date
    },
    billUrl: String    // link to a PDF/HTML bill (could be generated later)
  },
  { timestamps: true }
);

export default mongoose.model('Order', orderSchema);
