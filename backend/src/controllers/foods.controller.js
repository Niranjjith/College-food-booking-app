import Food from '../models/Food.js';
import catchAsync from '../utils/catchAsync.js';

export const listFoods = catchAsync(async (req, res) => {
  const foods = await Food.find().sort({ createdAt: -1 });
  res.json(foods);
});

export const getFood = catchAsync(async (req, res) => {
  const food = await Food.findById(req.params.id);
  if (!food) return res.status(404).json({ message: 'Food not found' });
  res.json(food);
});

export const createFood = catchAsync(async (req, res) => {
  const food = await Food.create(req.body);
  res.status(201).json(food);
});

export const updateFood = catchAsync(async (req, res) => {
  const food = await Food.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!food) return res.status(404).json({ message: 'Food not found' });
  res.json(food);
});

export const deleteFood = catchAsync(async (req, res) => {
  const deleted = await Food.findByIdAndDelete(req.params.id);
  if (!deleted) return res.status(404).json({ message: 'Food not found' });
  res.json({ message: 'Deleted' });
});
