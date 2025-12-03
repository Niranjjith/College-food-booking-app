import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import { createPaymentIntent, stripeWebhook } from '../controllers/payments.controller.js';

const router = Router();

router.post('/intent', protect, createPaymentIntent);

// webhook must read the raw body
export const webhookRoute = Router();
webhookRoute.post('/stripe', stripeWebhook);

export default router;
