import Inventory from '../models/Inventory.js';
import FoodIngredient from '../models/FoodIngredient.js';
import Order from '../models/Order.js';
import Food from '../models/Food.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Get all inventory items
 */
export const getInventory = catchAsync(async (req, res) => {
  const inventory = await Inventory.find().sort({ name: 1 });
  res.json(inventory);
});

/**
 * Create inventory item
 */
export const createInventoryItem = catchAsync(async (req, res) => {
  const inventory = await Inventory.create(req.body);
  res.status(201).json(inventory);
});

/**
 * Update inventory item
 */
export const updateInventoryItem = catchAsync(async (req, res) => {
  const inventory = await Inventory.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  );
  if (!inventory) {
    return res.status(404).json({ message: 'Inventory item not found' });
  }
  res.json(inventory);
});

/**
 * Delete inventory item
 */
export const deleteInventoryItem = catchAsync(async (req, res) => {
  const inventory = await Inventory.findByIdAndDelete(req.params.id);
  if (!inventory) {
    return res.status(404).json({ message: 'Inventory item not found' });
  }
  res.json({ message: 'Inventory item deleted' });
});

/**
 * Get low stock alerts
 */
export const getLowStockAlerts = catchAsync(async (req, res) => {
  const alerts = await Inventory.find({
    $expr: { $lte: ['$currentStock', '$minStock'] },
  }).sort({ currentStock: 1 });

  res.json({
    count: alerts.length,
    alerts: alerts.map((item) => ({
      id: item._id,
      name: item.name,
      currentStock: item.currentStock,
      minStock: item.minStock,
      unit: item.unit,
      category: item.category,
      supplier: item.supplier,
      urgency: item.currentStock === 0 ? 'critical' : item.currentStock <= item.minStock * 0.5 ? 'high' : 'medium',
    })),
  });
});

/**
 * Update stock after order
 */
export const updateStockAfterOrder = catchAsync(async (orderId) => {
  const order = await Order.findById(orderId).populate('items.food');
  if (!order || order.status !== 'paid') return;

  for (const item of order.items) {
    const food = item.food;
    if (!food) continue;

    // Get ingredients for this food
    const ingredients = await FoodIngredient.find({ food: food._id }).populate('ingredient');

    for (const ingredient of ingredients) {
      const quantityUsed = ingredient.quantity * item.qty;
      await Inventory.findByIdAndUpdate(ingredient.ingredient._id, {
        $inc: { currentStock: -quantityUsed },
      });
    }
  }
});

/**
 * Restock inventory item
 */
export const restockInventory = catchAsync(async (req, res) => {
  const { quantity } = req.body;
  const inventory = await Inventory.findById(req.params.id);

  if (!inventory) {
    return res.status(404).json({ message: 'Inventory item not found' });
  }

  inventory.currentStock = Math.min(
    inventory.currentStock + quantity,
    inventory.maxStock
  );
  inventory.lastRestocked = new Date();
  await inventory.save();

  res.json(inventory);
});

/**
 * Link ingredient to food
 */
export const addFoodIngredient = catchAsync(async (req, res) => {
  const { foodId, ingredientId, quantity, unit } = req.body;

  const foodIngredient = await FoodIngredient.findOneAndUpdate(
    { food: foodId, ingredient: ingredientId },
    { quantity, unit },
    { upsert: true, new: true }
  );

  res.json(foodIngredient);
});

/**
 * Get ingredients for a food
 */
export const getFoodIngredients = catchAsync(async (req, res) => {
  const ingredients = await FoodIngredient.find({ food: req.params.foodId })
    .populate('ingredient');
  res.json(ingredients);
});

