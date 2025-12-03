import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  prioritizeOrders,
  getKitchenActions,
  updateOrderPriority,
} from '../controllers/prioritization.controller.js';

const router = Router();

router.use(protect);

router.get('/queue', adminOnly, prioritizeOrders);
router.get('/actions', adminOnly, getKitchenActions);
router.patch('/order/:orderId/priority', adminOnly, updateOrderPriority);

export default router;


