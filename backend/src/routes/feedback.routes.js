import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  createFeedback,
  getMyFeedback,
  getAllFeedback,
  updateFeedbackStatus,
  getFeedbackStats,
} from '../controllers/feedback.controller.js';

const router = Router();

router.use(protect);

router.post('/', createFeedback);
router.get('/me', getMyFeedback);
router.get('/admin/all', adminOnly, getAllFeedback);
router.get('/admin/stats', adminOnly, getFeedbackStats);
router.patch('/admin/:id', adminOnly, updateFeedbackStatus);

export default router;


