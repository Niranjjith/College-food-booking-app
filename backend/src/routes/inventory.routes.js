import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  getInventory,
  createInventoryItem,
  updateInventoryItem,
  deleteInventoryItem,
  getLowStockAlerts,
  restockInventory,
  addFoodIngredient,
  getFoodIngredients,
} from '../controllers/inventory.controller.js';

const router = Router();

// All routes require admin access
router.use(protect, adminOnly);

router.get('/', getInventory);
router.post('/', createInventoryItem);
router.get('/alerts', getLowStockAlerts);
router.get('/food/:foodId/ingredients', getFoodIngredients);
router.post('/food/ingredient', addFoodIngredient);
router.put('/:id', updateInventoryItem);
router.patch('/:id/restock', restockInventory);
router.delete('/:id', deleteInventoryItem);

export default router;

