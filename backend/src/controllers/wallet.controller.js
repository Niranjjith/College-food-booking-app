import Wallet from '../models/Wallet.js';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';
import crypto from 'crypto';

/**
 * Get user wallet
 */
export const getWallet = catchAsync(async (req, res) => {
  let wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    wallet = await Wallet.create({ user: req.user._id });
  }
  res.json(wallet);
});

/**
 * Top up wallet
 */
export const topUpWallet = catchAsync(async (req, res) => {
  const { amount, paymentMethod } = req.body;
  
  if (amount <= 0) {
    return res.status(400).json({ message: 'Invalid amount' });
  }

  let wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    wallet = await Wallet.create({ user: req.user._id });
  }

  wallet.balance += amount;
  wallet.transactions.push({
    type: 'topup',
    amount,
    description: `Top-up via ${paymentMethod || 'payment gateway'}`,
  });

  await wallet.save();

  res.json({
    wallet,
    message: `Successfully added ₹${amount} to wallet`,
  });
});

/**
 * Pay with wallet
 */
export const payWithWallet = catchAsync(async (req, res) => {
  const { orderId } = req.body;

  const order = await Order.findById(orderId);
  if (!order || order.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Order not found' });
  }

  if (order.status === 'paid') {
    return res.status(400).json({ message: 'Order already paid' });
  }

  let wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    wallet = await Wallet.create({ user: req.user._id });
  }

  if (wallet.balance < order.subtotal) {
    return res.status(400).json({ 
      message: 'Insufficient balance',
      required: order.subtotal,
      available: wallet.balance,
    });
  }

  // Deduct from wallet
  wallet.balance -= order.subtotal;
  wallet.totalSpent += order.subtotal;
  wallet.updateRewardTier();
  wallet.updateStreak();

  // Add loyalty points (1 point per ₹10 spent)
  const pointsEarned = Math.floor(order.subtotal / 10);
  wallet.loyaltyPoints += pointsEarned;

  wallet.transactions.push({
    type: 'payment',
    amount: -order.subtotal,
    orderId: order._id,
    description: `Payment for order #${order._id.toString().slice(-6)}`,
  });

  await wallet.save();

  // Update order
  order.status = 'paid';
  order.payment = {
    provider: 'wallet',
    paidAt: new Date(),
  };
  await order.save();

  res.json({
    success: true,
    wallet,
    order,
    pointsEarned,
    message: `Payment successful! Earned ${pointsEarned} loyalty points.`,
  });
});

/**
 * Get wallet transactions
 */
export const getTransactions = catchAsync(async (req, res) => {
  const wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    return res.json({ transactions: [] });
  }

  const transactions = wallet.transactions.sort((a, b) => b.createdAt - a.createdAt);
  res.json({ transactions });
});

/**
 * Redeem loyalty points
 */
export const redeemPoints = catchAsync(async (req, res) => {
  const { points } = req.body;
  const conversionRate = 10; // 10 points = ₹1

  if (points < conversionRate) {
    return res.status(400).json({ message: `Minimum ${conversionRate} points required` });
  }

  const wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet || wallet.loyaltyPoints < points) {
    return res.status(400).json({ message: 'Insufficient points' });
  }

  const amount = Math.floor(points / conversionRate);
  wallet.loyaltyPoints -= points;
  wallet.balance += amount;

  wallet.transactions.push({
    type: 'reward',
    amount,
    description: `Redeemed ${points} points for ₹${amount}`,
  });

  await wallet.save();

  res.json({
    wallet,
    message: `Redeemed ${points} points for ₹${amount}`,
  });
});

/**
 * Get rewards and discounts
 */
export const getRewards = catchAsync(async (req, res) => {
  const wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    return res.json({
      loyaltyPoints: 0,
      streakDays: 0,
      rewardTier: 'bronze',
      discounts: [],
    });
  }

  // Calculate discounts based on tier and streak
  const discounts = [];
  
  // Streak discount
  if (wallet.streakDays >= 7) {
    discounts.push({
      type: 'streak',
      name: '7-Day Streak Bonus',
      discount: 10,
      description: '10% off for maintaining 7-day order streak',
    });
  }

  // Tier-based discounts
  const tierDiscounts = {
    bronze: 0,
    silver: 5,
    gold: 10,
    platinum: 15,
  };
  
  if (tierDiscounts[wallet.rewardTier] > 0) {
    discounts.push({
      type: 'tier',
      name: `${wallet.rewardTier.toUpperCase()} Member`,
      discount: tierDiscounts[wallet.rewardTier],
      description: `${tierDiscounts[wallet.rewardTier]}% off for ${wallet.rewardTier} tier members`,
    });
  }

  // Off-peak discount (if ordering during off-peak hours)
  const currentHour = new Date().getHours();
  if (currentHour < 11 || currentHour > 14) {
    discounts.push({
      type: 'off-peak',
      name: 'Off-Peak Discount',
      discount: 5,
      description: '5% off for ordering during off-peak hours',
    });
  }

  res.json({
    loyaltyPoints: wallet.loyaltyPoints,
    streakDays: wallet.streakDays,
    rewardTier: wallet.rewardTier,
    totalSpent: wallet.totalSpent,
    discounts,
  });
});


