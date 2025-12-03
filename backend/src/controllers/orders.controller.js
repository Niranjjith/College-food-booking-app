import Order from "../models/Order.js";
import Food from "../models/Food.js";
import User from "../models/User.js";
import catchAsync from "../utils/catchAsync.js";

/**
 * Student - Create Order
 */
export const createOrder = catchAsync(async (req, res) => {
  const { items } = req.body;
  if (!items || items.length === 0) {
    return res.status(400).json({ message: "No items" });
  }

  const foodIds = items.map((i) => i.foodId);
  const foods = await Food.find({ _id: { $in: foodIds } });
  const foodMap = {};
  foods.forEach((f) => (foodMap[f._id] = f));

  const orderItems = items.map((i) => {
    const f = foodMap[i.foodId];
    if (!f) throw new Error("Food not found");
    return { food: f._id, name: f.name, qty: i.qty, price: f.price };
  });

  const subtotal = orderItems.reduce((sum, i) => sum + i.price * i.qty, 0);

  const order = await Order.create({
    user: req.user._id,
    items: orderItems,
    subtotal,
    status: "pending",
  });

  res.status(201).json(order);
});

/**
 * Student - My Orders
 */
export const myOrders = catchAsync(async (req, res) => {
  const orders = await Order.find({ user: req.user._id }).sort({ createdAt: -1 });
  res.json(orders);
});

/**
 * Student/Admin - Get single order
 */
export const getOrder = catchAsync(async (req, res) => {
  const order = await Order.findById(req.params.id).populate("user", "name email");
  if (!order) return res.status(404).json({ message: "Order not found" });
  res.json(order);
});

/**
 * Admin - Today’s Orders
 */
export const adminDailyOrders = catchAsync(async (req, res) => {
  const date = req.query.date ? new Date(req.query.date) : new Date();
  const start = new Date(date); start.setHours(0, 0, 0, 0);
  const end = new Date(date); end.setHours(23, 59, 59, 999);

  const orders = await Order.find({ createdAt: { $gte: start, $lte: end } })
    .populate("user", "name email")
    .sort({ createdAt: -1 });

  const total = orders.reduce((sum, o) => sum + o.subtotal, 0);

  res.json({
    date: start.toISOString().slice(0, 10),
    count: orders.length,
    total,
    orders,
  });
});

/**
 * Admin - Summary
 */
export const adminSummary = catchAsync(async (req, res) => {
  const orders = await Order.countDocuments();
  const foods = await Food.countDocuments();
  const users = await User.countDocuments();
  const revenue = await Order.aggregate([
    { $match: { status: "paid" } },
    { $group: { _id: null, total: { $sum: "$subtotal" } } },
  ]);

  res.json({
    orders,
    foods,
    users,
    revenue: revenue[0]?.total || 0,
  });
});

/**
 * Admin - Sales Trend (last 7 days)
 */
export const adminSalesTrend = catchAsync(async (req, res) => {
  const last7 = new Date();
  last7.setDate(last7.getDate() - 6);

  const data = await Order.aggregate([
    { $match: { createdAt: { $gte: last7 }, status: "paid" } },
    {
      $group: {
        _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
        total: { $sum: "$subtotal" },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  res.json(data);
});

/**
 * Admin - Mark Paid
 */
export const markPaid = catchAsync(async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ message: "Order not found" });

  order.status = "paid";
  order.payment = { provider: "manual", paidAt: new Date() };
  await order.save();

  res.json(order);
});
