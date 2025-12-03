import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import catchAsync from '../utils/catchAsync.js';

const signToken = (id) =>
  jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

export const register = catchAsync(async (req, res) => {
  const { name, email, password } = req.body;
  const exists = await User.findOne({ email });
  if (exists) return res.status(400).json({ message: 'Email already in use' });
  const user = await User.create({ name, email, password, role: 'user' });
  const token = signToken(user._id);
  res.status(201).json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role } });
});

export const login = catchAsync(async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user || !(await user.comparePassword(password))) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  const token = signToken(user._id);
  res.json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role } });
});

/** Seed one admin on first boot if absent */
export const ensureAdmin = catchAsync(async (_req, _res) => {
  const email = process.env.ADMIN_EMAIL;
  if (!email) return;
  const existing = await User.findOne({ email });
  if (!existing) {
    await User.create({
      name: 'Admin',
      email,
      password: process.env.ADMIN_PASSWORD || 'Admin@123',
      role: 'admin'
    });
    console.log('Seeded default admin:', email);
  }
});
export const getMe = catchAsync(async (req, res) => {
  res.json(req.user);
});

export const updateProfile = catchAsync(async (req, res) => {
  const user = await User.findById(req.user._id);
  if (!user) return res.status(404).json({ message: "User not found" });

  if (req.body.email) user.email = req.body.email;
  if (req.body.password) user.password = req.body.password;

  await user.save();
  res.json({ message: "Profile updated", user });
});
