import Subscription from '../models/Subscription.js';
import Order from '../models/Order.js';
import Food from '../models/Food.js';
import Wallet from '../models/Wallet.js';
import catchAsync from '../utils/catchAsync.js';
import crypto from 'crypto';

/**
 * Create subscription
 */
export const createSubscription = catchAsync(async (req, res) => {
  const { items, startDate, endDate, pickupTime, autoRenew } = req.body;

  // Calculate total price
  let totalPrice = 0;
  const subscriptionItems = [];

  for (const item of items) {
    const food = await Food.findById(item.foodId);
    if (!food) {
      return res.status(404).json({ message: `Food ${item.foodId} not found` });
    }

    const itemPrice = food.price * item.qty;
    totalPrice += itemPrice;

    subscriptionItems.push({
      food: food._id,
      name: food.name,
      price: food.price,
      qty: item.qty,
      daysOfWeek: item.daysOfWeek || [1, 2, 3, 4, 5], // Default: Mon-Fri
    });
  }

  // Calculate next order date
  const start = new Date(startDate);
  const nextOrderDate = new Date(start);
  nextOrderDate.setDate(nextOrderDate.getDate() + 1);

  const subscription = await Subscription.create({
    user: req.user._id,
    items: subscriptionItems,
    startDate: start,
    endDate: new Date(endDate),
    totalPrice,
    pickupTime: pickupTime || '12:00',
    autoRenew,
    nextOrderDate,
  });

  res.status(201).json(subscription);
});

/**
 * Get user subscriptions
 */
export const getMySubscriptions = catchAsync(async (req, res) => {
  const subscriptions = await Subscription.find({ user: req.user._id })
    .populate('items.food')
    .sort({ createdAt: -1 });

  res.json(subscriptions);
});

/**
 * Process scheduled orders for today
 */
export const processScheduledOrders = catchAsync(async (req, res) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const dayOfWeek = today.getDay();

  // Find active subscriptions that need orders today
  const subscriptions = await Subscription.find({
    status: 'active',
    startDate: { $lte: today },
    endDate: { $gte: today },
  }).populate('items.food');

  const ordersCreated = [];

  for (const subscription of subscriptions) {
    // Check if subscription has items for today
    const itemsForToday = subscription.items.filter(item => 
      item.daysOfWeek.includes(dayOfWeek)
    );

    if (itemsForToday.length === 0) continue;

    // Check if order already exists for today
    const existingOrder = await Order.findOne({
      subscriptionId: subscription._id,
      scheduledDate: today,
    });

    if (existingOrder) continue;

    // Create order
    const orderItems = itemsForToday.map(item => ({
      food: item.food._id,
      name: item.food.name,
      price: item.food.price,
      qty: item.qty,
    }));

    const subtotal = orderItems.reduce((sum, item) => sum + (item.price * item.qty), 0);

    // Generate pickup code
    const pickupCode = crypto.randomBytes(4).toString('hex').toUpperCase();

    const order = await Order.create({
      user: subscription.user,
      items: orderItems,
      subtotal,
      status: 'paid', // Auto-paid for subscriptions
      payment: {
        provider: 'subscription',
        paidAt: new Date(),
      },
      isScheduled: true,
      scheduledDate: today,
      subscriptionId: subscription._id,
      pickupCode,
      preparation: {
        estimatedTime: 0, // Will be calculated
        queuePosition: 0,
        kitchenLoad: 0,
      },
    });

    // Update subscription next order date
    const nextDate = new Date(today);
    nextDate.setDate(nextDate.getDate() + 1);
    subscription.nextOrderDate = nextDate;
    await subscription.save();

    ordersCreated.push(order);
  }

  res.json({
    message: `Created ${ordersCreated.length} scheduled orders`,
    orders: ordersCreated,
  });
});

/**
 * Cancel subscription
 */
export const cancelSubscription = catchAsync(async (req, res) => {
  const subscription = await Subscription.findById(req.params.id);
  
  if (!subscription || subscription.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Subscription not found' });
  }

  subscription.status = 'cancelled';
  await subscription.save();

  res.json({ message: 'Subscription cancelled', subscription });
});

/**
 * Pause/Resume subscription
 */
export const updateSubscriptionStatus = catchAsync(async (req, res) => {
  const { status } = req.body;
  const subscription = await Subscription.findById(req.params.id);
  
  if (!subscription || subscription.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Subscription not found' });
  }

  subscription.status = status;
  await subscription.save();

  res.json(subscription);
});

