import { Router } from 'express';
import { adminOnly, protect } from '../middlewares/auth.js';
import { listFoods, getFood, createFood, updateFood, deleteFood } from '../controllers/foods.controller.js';

const router = Router();

router.get('/', listFoods);
router.get('/:id', getFood);
router.post('/', protect, adminOnly, createFood);
router.put('/:id', protect, adminOnly, updateFood);
router.delete('/:id', protect, adminOnly, deleteFood);

export default router;
