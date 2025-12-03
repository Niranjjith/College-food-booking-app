import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import {
  getRecommendations,
  updatePreferences,
  getTrendingFoods,
} from '../controllers/recommendations.controller.js';

const router = Router();

router.get('/me', protect, getRecommendations);
router.put('/preferences', protect, updatePreferences);
router.get('/trending', getTrendingFoods);

export default router;

