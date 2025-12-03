import mongoose from 'mongoose';

const feedbackSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { 
      type: String, 
      enum: ['feedback', 'suggestion', 'complaint', 'issue'], 
      required: true 
    },
    category: {
      type: String,
      enum: ['food', 'service', 'app', 'payment', 'delivery', 'other'],
      default: 'other',
    },
    title: { type: String, required: true },
    description: { type: String, required: true },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
    foodId: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
    rating: { type: Number, min: 1, max: 5 },
    status: { 
      type: String, 
      enum: ['open', 'in-progress', 'resolved', 'closed'], 
      default: 'open' 
    },
    priority: { 
      type: String, 
      enum: ['low', 'medium', 'high', 'urgent'], 
      default: 'medium' 
    },
    adminResponse: String,
    resolvedAt: Date,
  },
  { timestamps: true }
);

export default mongoose.model('Feedback', feedbackSchema);


