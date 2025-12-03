import Order from "../models/Order.js";
import Food from "../models/Food.js";
import User from "../models/User.js";
import catchAsync from "../utils/catchAsync.js";
import { updateStockAfterOrder } from "./inventory.controller.js";

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

  // Calculate initial preparation time estimate
  const pendingCount = await Order.countDocuments({
    status: { $in: ['paid', 'preparing'] },
    createdAt: { $lt: order.createdAt },
  });
  
  let totalPrepTime = 0;
  for (const item of orderItems) {
    const food = foodMap[item.food.toString()];
    if (food && food.preparationTime) {
      totalPrepTime += food.preparationTime * item.qty;
    }
  }
  
  const estimatedTime = Math.ceil(totalPrepTime + (pendingCount * 3));
  order.preparation = {
    estimatedTime,
    queuePosition: pendingCount + 1,
    kitchenLoad: pendingCount,
  };
  await order.save();

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
  
  // Update inventory when order is paid
  await updateStockAfterOrder(order._id);
  
  // Recalculate preparation time
  const pendingCount = await Order.countDocuments({
    status: { $in: ['paid', 'preparing'] },
    createdAt: { $lt: order.createdAt },
  });
  
  let totalPrepTime = 0;
  for (const item of order.items) {
    const food = await Food.findById(item.food);
    if (food && food.preparationTime) {
      totalPrepTime += food.preparationTime * item.qty;
    }
  }
  
  const estimatedTime = Math.ceil(totalPrepTime + (pendingCount * 3));
  order.preparation = {
    estimatedTime,
    queuePosition: pendingCount + 1,
    kitchenLoad: pendingCount,
  };
  
  await order.save();

  res.json(order);
});

/**
 * Admin - Demand Forecasting & Predictive Analytics
 */
export const demandForecasting = catchAsync(async (req, res) => {
  const days = parseInt(req.query.days) || 30; // Analyze last N days
  const forecastDays = parseInt(req.query.forecastDays) || 7; // Forecast next N days
  
  const endDate = new Date();
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  // Get all paid orders in the period
  const orders = await Order.find({
    status: "paid",
    createdAt: { $gte: startDate, $lte: endDate }
  });

  // 1. Food Item Demand Analysis
  const foodDemand = {};
  orders.forEach(order => {
    order.items.forEach(item => {
      // Use food ID from item (stored as ObjectId reference)
      const foodId = item.food?.toString() || item.food?._id?.toString() || 'unknown';
      if (!foodDemand[foodId]) {
        foodDemand[foodId] = {
          foodId,
          name: item.name || 'Unknown Food',
          totalQty: 0,
          totalOrders: 0,
          dailyAvg: 0,
          days: []
        };
      }
      foodDemand[foodId].totalQty += item.qty;
      foodDemand[foodId].totalOrders += 1;
    });
  });

  // Calculate daily averages and trends
  const foodDemandArray = Object.values(foodDemand).map(food => {
    food.dailyAvg = food.totalQty / days;
    
    // Get daily breakdown for trend analysis
    const dailyBreakdown = {};
    orders.forEach(order => {
      const orderDate = new Date(order.createdAt).toISOString().split('T')[0];
      order.items.forEach(item => {
        const foodId = item.food?.toString() || item.food?._id?.toString() || 'unknown';
        if (foodId === food.foodId) {
          if (!dailyBreakdown[orderDate]) dailyBreakdown[orderDate] = 0;
          dailyBreakdown[orderDate] += item.qty;
        }
      });
    });
    
    food.days = Object.entries(dailyBreakdown)
      .map(([date, qty]) => ({ date, qty }))
      .sort((a, b) => a.date.localeCompare(b.date));
    
    // Calculate trend (simple linear regression slope)
    if (food.days.length > 1) {
      const n = food.days.length;
      const sumX = food.days.reduce((sum, _, i) => sum + i, 0);
      const sumY = food.days.reduce((sum, d) => sum + d.qty, 0);
      const sumXY = food.days.reduce((sum, d, i) => sum + i * d.qty, 0);
      const sumX2 = food.days.reduce((sum, _, i) => sum + i * i, 0);
      food.trend = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    } else {
      food.trend = 0;
    }
    
    return food;
  });

  // 2. Daily Order Volume Analysis
  const dailyVolume = {};
  orders.forEach(order => {
    const date = new Date(order.createdAt).toISOString().split('T')[0];
    if (!dailyVolume[date]) {
      dailyVolume[date] = { date, orders: 0, revenue: 0, items: 0 };
    }
    dailyVolume[date].orders += 1;
    dailyVolume[date].revenue += order.subtotal;
    dailyVolume[date].items += order.items.reduce((sum, item) => sum + item.qty, 0);
  });

  const dailyVolumeArray = Object.values(dailyVolume)
    .sort((a, b) => a.date.localeCompare(b.date));

  // Calculate average daily metrics
  const avgDailyOrders = dailyVolumeArray.reduce((sum, d) => sum + d.orders, 0) / days;
  const avgDailyRevenue = dailyVolumeArray.reduce((sum, d) => sum + d.revenue, 0) / days;
  const avgDailyItems = dailyVolumeArray.reduce((sum, d) => sum + d.items, 0) / days;

  // 3. Hourly Pattern Analysis
  const hourlyPattern = {};
  for (let i = 0; i < 24; i++) {
    hourlyPattern[i] = { hour: i, orders: 0, revenue: 0 };
  }

  orders.forEach(order => {
    const hour = new Date(order.createdAt).getHours();
    hourlyPattern[hour].orders += 1;
    hourlyPattern[hour].revenue += order.subtotal;
  });

  const hourlyPatternArray = Object.values(hourlyPattern);

  // 4. Day of Week Analysis
  const dayOfWeekPattern = {};
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  dayNames.forEach(day => {
    dayOfWeekPattern[day] = { day, orders: 0, revenue: 0 };
  });

  orders.forEach(order => {
    const dayName = dayNames[new Date(order.createdAt).getDay()];
    dayOfWeekPattern[dayName].orders += 1;
    dayOfWeekPattern[dayName].revenue += order.subtotal;
  });

  const dayOfWeekArray = Object.values(dayOfWeekPattern);

  // 5. Forecast Next N Days
  const forecast = [];
  const recentDays = dailyVolumeArray.slice(-7); // Use last 7 days for moving average
  const recentAvgOrders = recentDays.reduce((sum, d) => sum + d.orders, 0) / Math.max(recentDays.length, 1);
  const recentAvgRevenue = recentDays.reduce((sum, d) => sum + d.revenue, 0) / Math.max(recentDays.length, 1);
  
  // Calculate trend from recent data
  let trendFactor = 0;
  if (recentDays.length > 1) {
    const firstHalf = recentDays.slice(0, Math.floor(recentDays.length / 2));
    const secondHalf = recentDays.slice(Math.floor(recentDays.length / 2));
    const firstAvg = firstHalf.reduce((sum, d) => sum + d.orders, 0) / firstHalf.length;
    const secondAvg = secondHalf.reduce((sum, d) => sum + d.orders, 0) / secondHalf.length;
    trendFactor = (secondAvg - firstAvg) / firstAvg;
  }

  for (let i = 1; i <= forecastDays; i++) {
    const forecastDate = new Date();
    forecastDate.setDate(forecastDate.getDate() + i);
    const dayName = dayNames[forecastDate.getDay()];
    const dayMultiplier = dayOfWeekPattern[dayName]?.orders / (orders.length / 7) || 1;
    
    const predictedOrders = Math.max(0, Math.round(recentAvgOrders * (1 + trendFactor * 0.1) * dayMultiplier));
    const predictedRevenue = Math.max(0, Math.round(recentAvgRevenue * (1 + trendFactor * 0.1) * dayMultiplier));
    
    forecast.push({
      date: forecastDate.toISOString().split('T')[0],
      dayName,
      predictedOrders,
      predictedRevenue,
    });
  }

  // 6. Top Predicted Foods (based on trend and average)
  const topPredictedFoods = foodDemandArray
    .map(food => ({
      ...food,
      predictedDailyQty: Math.max(0, food.dailyAvg + (food.trend * forecastDays)),
      confidence: food.days.length > 3 ? 'high' : food.days.length > 1 ? 'medium' : 'low'
    }))
    .sort((a, b) => b.predictedDailyQty - a.predictedDailyQty)
    .slice(0, 10);

  res.json({
    period: {
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      days,
    },
    summary: {
      totalOrders: orders.length,
      avgDailyOrders: Math.round(avgDailyOrders * 100) / 100,
      avgDailyRevenue: Math.round(avgDailyRevenue * 100) / 100,
      avgDailyItems: Math.round(avgDailyItems * 100) / 100,
    },
    foodDemand: foodDemandArray.sort((a, b) => b.totalQty - a.totalQty),
    topPredictedFoods,
    dailyVolume: dailyVolumeArray,
    hourlyPattern: hourlyPatternArray,
    dayOfWeekPattern: dayOfWeekArray,
    forecast,
  });
});