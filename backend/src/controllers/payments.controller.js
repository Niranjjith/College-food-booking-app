import Stripe from 'stripe';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';

const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;

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
