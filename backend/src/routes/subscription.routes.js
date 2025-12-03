import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  createSubscription,
  getMySubscriptions,
  processScheduledOrders,
  cancelSubscription,
  updateSubscriptionStatus,
} from '../controllers/subscription.controller.js';

const router = Router();

router.use(protect);

router.post('/', createSubscription);
router.get('/me', getMySubscriptions);
router.post('/:id/cancel', cancelSubscription);
router.patch('/:id/status', updateSubscriptionStatus);

// Admin route to process scheduled orders (can be called via cron job)
router.post('/admin/process', adminOnly, processScheduledOrders);

export default router;

