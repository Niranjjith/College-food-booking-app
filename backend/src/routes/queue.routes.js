import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  getOrderStatus,
  getQueueStatus,
  updateOrderStatus,
} from '../controllers/queue.controller.js';

const router = Router();

// User routes
router.get('/order/:id/status', protect, getOrderStatus);

// Admin routes
router.get('/admin/queue', protect, adminOnly, getQueueStatus);
router.patch('/order/:id/status', protect, adminOnly, updateOrderStatus);

export default router;


