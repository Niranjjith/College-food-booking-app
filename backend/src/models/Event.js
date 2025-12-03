import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    description: String,
    startDate: { type: Date, required: true },
    endDate: { type: Date, required: true },
    eventType: {
      type: String,
      enum: ['fest', 'group-event', 'special-occasion', 'holiday'],
      default: 'group-event',
    },
    status: {
      type: String,
      enum: ['upcoming', 'active', 'ended'],
      default: 'upcoming',
    },
    bundles: [
      {
        name: { type: String, required: true },
        description: String,
        items: [
          {
            food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
            name: String,
            qty: { type: Number, default: 1 },
          },
        ],
        price: { type: Number, required: true },
        discount: { type: Number, default: 0 }, // Percentage discount
        image: String,
        available: { type: Boolean, default: true },
      },
    ],
    maxOrders: Number, // Optional: limit total orders for this event
    currentOrders: { type: Number, default: 0 },
    registrationRequired: { type: Boolean, default: false },
    registeredUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

export default mongoose.model('Event', eventSchema);

