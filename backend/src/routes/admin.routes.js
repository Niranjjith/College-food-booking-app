import { Router } from 'express';
import Order from '../models/Order.js';
import Food from '../models/Food.js';
import User from '../models/User.js';

const router = Router();

// Simple session-less password gate using env admin (for demo) — real app: use proper admin login
router.get('/signin', (req, res) => res.render('signin'));
router.post('/signin', async (req, res) => {
  const { email, password } = req.body;
  // Very simple check against DB user with role admin
  const admin = await User.findOne({ email, role: 'admin' });
  if (!admin) return res.render('signin', { error: 'Admin not found' });
  const ok = await admin.comparePassword(password);
  if (!ok) return res.render('signin', { error: 'Wrong password' });
  // naive cookie
  res.cookie('admin', admin._id.toString(), { httpOnly: true });
  res.redirect('/admin/orders');
});

// middleware to check cookie (demo)
router.use((req, res, next) => {
  if (req.cookies?.admin) return next();
  if (req.path === '/signin') return next();
  return res.redirect('/admin/signin');
});

router.get('/orders', async (req, res) => {
  const qDate = req.query.date;
  const date = qDate ? new Date(qDate) : new Date();
  const start = new Date(date); start.setHours(0,0,0,0);
  const end = new Date(date);   end.setHours(23,59,59,999);
  const orders = await Order.find({ createdAt: { $gte: start, $lte: end } })
    .populate('user', 'name email')
    .sort({ createdAt: -1 });
  const total = orders.reduce((s, o) => s + o.subtotal, 0);
  res.render('orders', { orders, total, date: start.toISOString().slice(0,10) });
});

router.get('/foods', async (_req, res) => {
  const foods = await Food.find().sort({ createdAt: -1 });
  res.render('foods', { foods });
});

router.get('/foods/new', (_req, res) => res.render('foods_edit', { food: null }));

router.post('/foods', async (req, res) => {
  await Food.create(req.body);
  res.redirect('/admin/foods');
});

router.get('/foods/:id/edit', async (req, res) => {
  const food = await Food.findById(req.params.id);
  if (!food) return res.redirect('/admin/foods');
  res.render('foods_edit', { food });
});

router.post('/foods/:id', async (req, res) => {
  await Food.findByIdAndUpdate(req.params.id, req.body);
  res.redirect('/admin/foods');
});

router.post('/foods/:id/delete', async (req, res) => {
  await Food.findByIdAndDelete(req.params.id);
  res.redirect('/admin/foods');
});

export default router;
