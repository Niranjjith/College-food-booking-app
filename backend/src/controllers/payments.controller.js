import '../config/env.js';
import Stripe from 'stripe';
import Razorpay from 'razorpay';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';

function publicApiOrigin(req) {
  if (process.env.PUBLIC_API_URL) return process.env.PUBLIC_API_URL.replace(/\/$/, '');
  const host = req.get('host');
  const protocol = req.protocol === 'https' || req.get('x-forwarded-proto') === 'https' ? 'https' : 'http';
  return host ? `${protocol}://${host}` : `http://localhost:${process.env.PORT || 5000}`;
}

function markRazorpayOrderPaid(order, razorpayOrderId, razorpayPaymentId) {
  order.status = 'paid';
  order.payment = {
    provider: 'razorpay',
    intentId: razorpayOrderId,
    paymentId: razorpayPaymentId,
    paidAt: new Date(),
  };
}

function verifyRazorpaySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature) {
  const text = `${razorpayOrderId}|${razorpayPaymentId}`;
  const generatedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(text)
    .digest('hex');
  return generatedSignature === razorpaySignature;
}

function getStripe() {
  return process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;
}

function getRazorpay() {
  const keyId = process.env.RAZORPAY_KEY_ID?.trim();
  const keySecret = process.env.RAZORPAY_KEY_SECRET?.trim();
  if (!keyId || !keySecret) return null;
  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
}

export const createPaymentIntent = catchAsync(async (req, res) => {
  const stripe = getStripe();
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
  const stripe = getStripe();
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
  const razorpay = getRazorpay();
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

    const checkoutToken = jwt.sign(
      {
        purpose: 'razorpay_checkout',
        orderId: order._id.toString(),
        razorpayOrderId: razorpayOrder.id,
        userId: req.user._id.toString(),
      },
      process.env.JWT_SECRET,
      { expiresIn: '30m' }
    );

    const origin = publicApiOrigin(req);
    const checkoutUrl = `${origin}/api/payments/razorpay/checkout?token=${encodeURIComponent(checkoutToken)}`;

    res.json({
      id: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      key: process.env.RAZORPAY_KEY_ID,
      checkoutUrl,
    });
  } catch (error) {
    res.status(500).json({ message: error.message || 'Failed to create Razorpay order' });
  }
});

/**
 * Razorpay - Hosted checkout page (desktop / web browsers)
 */
export const razorpayCheckoutPage = catchAsync(async (req, res) => {
  if (!process.env.RAZORPAY_KEY_ID) {
    return res.status(501).send('Razorpay not configured');
  }

  let payload;
  try {
    payload = jwt.verify(req.query.token, process.env.JWT_SECRET);
  } catch {
    return res.status(400).send('Invalid or expired checkout link. Create a new order from the app.');
  }

  if (payload.purpose !== 'razorpay_checkout') {
    return res.status(400).send('Invalid checkout token');
  }

  const order = await Order.findById(payload.orderId);
  if (!order || order.status === 'paid') {
    return res.status(400).send('Order not found or already paid');
  }

  const tokenJson = JSON.stringify(req.query.token);
  const keyJson = JSON.stringify(process.env.RAZORPAY_KEY_ID);
  const orderIdJson = JSON.stringify(payload.razorpayOrderId);
  const amount = Math.round(order.subtotal * 100);

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Pay — Food Booking</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 420px; margin: 48px auto; padding: 0 16px; color: #111827; }
    button { background: #10B981; color: #fff; border: 0; padding: 12px 20px; border-radius: 8px; font-size: 16px; cursor: pointer; }
    #msg { margin-top: 16px; color: #374151; }
  </style>
</head>
<body>
  <h1>Food Booking</h1>
  <p>Amount: ₹${(amount / 100).toFixed(2)}</p>
  <button type="button" id="pay">Pay with Razorpay</button>
  <p id="msg"></p>
  <script>
    const checkoutToken = ${tokenJson};
    const options = {
      key: ${keyJson},
      amount: ${amount},
      currency: 'INR',
      name: 'Food Booking App',
      description: 'Order payment',
      order_id: ${orderIdJson},
      handler: function (response) {
        document.getElementById('msg').textContent = 'Verifying payment…';
        fetch('/api/payments/razorpay/verify-hosted', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            checkoutToken: checkoutToken,
            razorpay_order_id: response.razorpay_order_id,
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_signature: response.razorpay_signature,
          }),
        })
          .then(function (r) { return r.json().then(function (d) { return { ok: r.ok, d: d }; }); })
          .then(function (result) {
            if (result.ok && result.d.success) {
              document.getElementById('msg').textContent = 'Payment successful! You can close this window and return to the app.';
            } else {
              document.getElementById('msg').textContent = result.d.message || 'Payment verification failed.';
            }
          })
          .catch(function () {
            document.getElementById('msg').textContent = 'Could not verify payment. Return to the app and tap Refresh.';
          });
      },
      modal: {
        ondismiss: function () {
          document.getElementById('msg').textContent = 'Payment cancelled. You can try again.';
        }
      }
    };
    document.getElementById('pay').onclick = function () {
      const rzp = new Razorpay(options);
      rzp.open();
    };
    document.getElementById('pay').click();
  </script>
</body>
</html>`);
});

/**
 * Razorpay - Verify payment from hosted checkout (browser)
 */
export const verifyRazorpayHostedPayment = catchAsync(async (req, res) => {
  if (!getRazorpay()) return res.status(501).json({ message: 'Razorpay not configured' });

  const { checkoutToken, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  let payload;
  try {
    payload = jwt.verify(checkoutToken, process.env.JWT_SECRET);
  } catch {
    return res.status(400).json({ message: 'Invalid or expired checkout session' });
  }

  if (payload.purpose !== 'razorpay_checkout') {
    return res.status(400).json({ message: 'Invalid checkout session' });
  }

  if (payload.razorpayOrderId !== razorpay_order_id) {
    return res.status(400).json({ message: 'Order mismatch' });
  }

  const order = await Order.findById(payload.orderId);
  if (!order || order.user.toString() !== payload.userId) {
    return res.status(404).json({ message: 'Order not found' });
  }
  if (order.status === 'paid') {
    return res.json({ success: true, order });
  }

  if (!verifyRazorpaySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
    return res.status(400).json({ message: 'Invalid payment signature' });
  }

  markRazorpayOrderPaid(order, razorpay_order_id, razorpay_payment_id);
  await order.save();

  res.json({ success: true, order });
});

/**
 * Razorpay - Verify Payment
 */
export const verifyRazorpayPayment = catchAsync(async (req, res) => {
  if (!getRazorpay()) return res.status(501).json({ message: 'Razorpay not configured' });

  const { orderId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  const order = await Order.findById(orderId);
  if (!order || order.user.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Order not found' });
  }

  if (!verifyRazorpaySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
    return res.status(400).json({ message: 'Invalid payment signature' });
  }

  markRazorpayOrderPaid(order, razorpay_order_id, razorpay_payment_id);
  await order.save();

  res.json({ success: true, order });
});
