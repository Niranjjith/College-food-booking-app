import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import {
  getRecommendations,
  updatePreferences,
  getTrendingFoods,
  getFavoriteFoods,
  updateFavoriteFood,
} from '../controllers/recommendations.controller.js';

const router = Router();

router.get('/me', protect, getRecommendations);
router.get('/favorites', protect, getFavoriteFoods);
router.put('/favorites/:foodId', protect, updateFavoriteFood);
router.put('/preferences', protect, updatePreferences);
router.get('/trending', getTrendingFoods);

export default router;


