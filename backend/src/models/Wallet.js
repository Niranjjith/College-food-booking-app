import mongoose from 'mongoose';

const transactionSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['topup', 'payment', 'refund', 'reward'], required: true },
    amount: { type: Number, required: true },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
    description: String,
    receiptUrl: String,
  },
  { timestamps: true, _id: false }
);

const walletSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    balance: { type: Number, default: 0, min: 0 },
    transactions: [transactionSchema],
    loyaltyPoints: { type: Number, default: 0, min: 0 },
    streakDays: { type: Number, default: 0 },
    lastOrderDate: Date,
    totalSpent: { type: Number, default: 0 },
    rewardTier: { type: String, enum: ['bronze', 'silver', 'gold', 'platinum'], default: 'bronze' },
  },
  { timestamps: true }
);

// Calculate reward tier based on total spent
walletSchema.methods.updateRewardTier = function() {
  if (this.totalSpent >= 10000) {
    this.rewardTier = 'platinum';
  } else if (this.totalSpent >= 5000) {
    this.rewardTier = 'gold';
  } else if (this.totalSpent >= 2000) {
    this.rewardTier = 'silver';
  } else {
    this.rewardTier = 'bronze';
  }
};

// Update streak
walletSchema.methods.updateStreak = function() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  if (this.lastOrderDate) {
    const lastDate = new Date(this.lastOrderDate);
    lastDate.setHours(0, 0, 0, 0);
    const daysDiff = Math.floor((today - lastDate) / (1000 * 60 * 60 * 24));
    
    if (daysDiff === 1) {
      // Consecutive day
      this.streakDays += 1;
    } else if (daysDiff > 1) {
      // Streak broken
      this.streakDays = 1;
    }
    // If daysDiff === 0, same day, don't update
  } else {
    this.streakDays = 1;
  }
  
  this.lastOrderDate = today;
};

export default mongoose.model('Wallet', walletSchema);

