import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import {
  createPaymentIntent,
  stripeWebhook,
  createRazorpayOrder,
  verifyRazorpayPayment,
  razorpayCheckoutPage,
  verifyRazorpayHostedPayment,
} from '../controllers/payments.controller.js';

const router = Router();

// Stripe routes
router.post('/intent', protect, createPaymentIntent);

// Razorpay routes
router.post('/razorpay/create-order', protect, createRazorpayOrder);
router.post('/razorpay/verify', protect, verifyRazorpayPayment);
router.get('/razorpay/checkout', razorpayCheckoutPage);
router.post('/razorpay/verify-hosted', verifyRazorpayHostedPayment);

// webhook must read the raw body
export const webhookRoute = Router();
webhookRoute.post('/stripe', stripeWebhook);

export default router;
