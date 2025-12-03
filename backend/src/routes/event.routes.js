import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  getActiveEvents,
  getAllEvents,
  getEvent,
  createEvent,
  updateEvent,
  registerForEvent,
  orderEventBundle,
  getEventStats,
} from '../controllers/event.controller.js';

const router = Router();

// Public routes (for students)
router.get('/active', getActiveEvents);
router.get('/', protect, getAllEvents);
router.get('/:id', protect, getEvent);
router.post('/:id/register', protect, registerForEvent);
router.post('/:id/order-bundle', protect, orderEventBundle);

// Admin routes
router.post('/', protect, adminOnly, createEvent);
router.patch('/:id', protect, adminOnly, updateEvent);
router.get('/:id/stats', protect, adminOnly, getEventStats);

export default router;


