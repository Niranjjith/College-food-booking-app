import Stripe from 'stripe';
import Razorpay from 'razorpay';
import crypto from 'crypto';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';

const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;

const razorpay = process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET
  ? new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    })
  : null;

export const createPaymentIntent = catchAsync(async (req, res) => {
  if (!stripe) return res.status(501).json({ message: 'Stripe not configured' });

  const { orderId, currency = 'inr' } = req.body;
  const order = await Order.findById(orderId);
  if (!order || order.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Order not found' });
  }
  if (order.status === 'paid') {
    return res.status(400).json({ message: 'Already paid' });
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(order.subtotal * 100),
    currency,
    metadata: { orderId: order._id.toString(), userId: req.user._id.toString() }
  });

  order.payment = { provider: 'stripe', intentId: paymentIntent.id };
  await order.save();

  res.json({ clientSecret: paymentIntent.client_secret });
});

/** Webhook to mark order paid */
export const stripeWebhook = catchAsync(async (req, res) => {
  if (!stripe) return res.status(501).end();

  const sig = req.headers['stripe-signature'];
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'payment_intent.succeeded') {
    const pi = event.data.object;
    const order = await Order.findOne({ 'payment.intentId': pi.id });
    if (order) {
      order.status = 'paid';
      order.payment.paidAt = new Date();
      await order.save();
    }
  }

  res.json({ received: true });
});

/**
 * Razorpay - Create Order
 */
export const createRazorpayOrder = catchAsync(async (req, res) => {
  if (!razorpay) return res.status(501).json({ message: 'Razorpay not configured' });

  const { orderId } = req.body;
  const order = await Order.findById(orderId);
  if (!order || order.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Order not found' });
  }
  if (order.status === 'paid') {
    return res.status(400).json({ message: 'Already paid' });
  }

  const options = {
    amount: Math.round(order.subtotal * 100), // Amount in paise
    currency: 'INR',
    receipt: `order_${order._id}`,
    notes: {
      orderId: order._id.toString(),
      userId: req.user._id.toString(),
    },
  };

  try {
    const razorpayOrder = await razorpay.orders.create(options);
    
    order.payment = {
      provider: 'razorpay',
      intentId: razorpayOrder.id,
    };
    await order.save();

    res.json({
      id: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      key: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Failed to create Razorpay order' });
  }
});

/**
 * Razorpay - Verify Payment
 */
export const verifyRazorpayPayment = catchAsync(async (req, res) => {
  if (!razorpay) return res.status(501).json({ message: 'Razorpay not configured' });

  const { orderId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  const order = await Order.findById(orderId);
  if (!order || order.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Order not found' });
  }

  // Verify signature
  const text = `${razorpay_order_id}|${razorpay_payment_id}`;
  const generatedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(text)
    .digest('hex');

  if (generatedSignature !== razorpay_signature) {
    return res.status(400).json({ message: 'Invalid payment signature' });
  }

  // Mark order as paid
  order.status = 'paid';
  order.payment = {
    provider: 'razorpay',
    intentId: razorpay_order_id,
    paymentId: razorpay_payment_id,
    paidAt: new Date(),
  };
  await order.save();

  res.json({ success: true, order });
});
