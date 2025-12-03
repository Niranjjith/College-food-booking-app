import Order from '../models/Order.js';
import Food from '../models/Food.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Calculate estimated preparation time for an order
 */
export const calculateEstimatedTime = async (order) => {
  const items = order.items;
  let maxPrepTime = 0;
  let totalPrepTime = 0;

  // Get preparation times for all items
  for (const item of items) {
    const food = await Food.findById(item.food);
    if (food) {
      const itemPrepTime = food.preparationTime * item.qty;
      totalPrepTime += itemPrepTime;
      maxPrepTime = Math.max(maxPrepTime, food.preparationTime);
    }
  }

  // Count pending orders (being prepared)
  const pendingOrders = await Order.countDocuments({
    status: { $in: ['paid', 'preparing'] },
    createdAt: { $lt: order.createdAt },
  });

  // Base time + queue wait time
  // Each order in queue adds 2-5 minutes depending on complexity
  const queueWaitTime = pendingOrders * 3; // Average 3 minutes per order
  const estimatedTime = Math.ceil(totalPrepTime + queueWaitTime);

  return {
    estimatedTime,
    queuePosition: pendingOrders + 1,
    kitchenLoad: pendingOrders,
    maxPrepTime,
  };
};

/**
 * Get order status with ETA
 */
export const getOrderStatus = catchAsync(async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  // Check if user owns the order
  if (order.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Unauthorized' });
  }

  const prepInfo = await calculateEstimatedTime(order);

  // Update order with current estimates
  order.preparation = {
    estimatedTime: prepInfo.estimatedTime,
    queuePosition: prepInfo.queuePosition,
    kitchenLoad: prepInfo.kitchenLoad,
    startTime: order.status === 'preparing' ? order.preparation.startTime : null,
    readyTime: order.status === 'ready' ? order.preparation.readyTime : null,
  };

  // Calculate remaining time
  let remainingTime = prepInfo.estimatedTime;
  if (order.preparation.startTime) {
    const elapsed = Math.floor((new Date() - order.preparation.startTime) / 60000);
    remainingTime = Math.max(0, prepInfo.estimatedTime - elapsed);
  }

  res.json({
    order: {
      id: order._id,
      status: order.status,
      items: order.items,
      subtotal: order.subtotal,
    },
    preparation: {
      ...prepInfo,
      remainingTime,
      startTime: order.preparation.startTime,
      readyTime: order.preparation.readyTime,
    },
  });
});

/**
 * Get all orders in queue (Admin)
 */
export const getQueueStatus = catchAsync(async (req, res) => {
  const orders = await Order.find({
    status: { $in: ['paid', 'preparing', 'ready'] },
  })
    .populate('user', 'name email')
    .sort({ createdAt: 1 });

  const queue = await Promise.all(
    orders.map(async (order) => {
      const prepInfo = await calculateEstimatedTime(order);
      let remainingTime = prepInfo.estimatedTime;

      if (order.preparation.startTime) {
        const elapsed = Math.floor((new Date() - order.preparation.startTime) / 60000);
        remainingTime = Math.max(0, prepInfo.estimatedTime - elapsed);
      }

      return {
        orderId: order._id,
        user: order.user,
        items: order.items,
        status: order.status,
        createdAt: order.createdAt,
        preparation: {
          ...prepInfo,
          remainingTime,
          startTime: order.preparation.startTime,
        },
      };
    })
  );

  res.json({
    totalOrders: queue.length,
    preparing: queue.filter((o) => o.status === 'preparing').length,
    ready: queue.filter((o) => o.status === 'ready').length,
    queue,
  });
});

/**
 * Update order status (Admin)
 */
export const updateOrderStatus = catchAsync(async (req, res) => {
  const { status } = req.body;
  const order = await Order.findById(req.params.id);

  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  const validStatuses = ['pending', 'paid', 'preparing', 'ready', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  order.status = status;

  // Update preparation timestamps
  if (status === 'preparing' && !order.preparation.startTime) {
    order.preparation.startTime = new Date();
    const prepInfo = await calculateEstimatedTime(order);
    const readyTime = new Date();
    readyTime.setMinutes(readyTime.getMinutes() + prepInfo.estimatedTime);
    order.preparation.readyTime = readyTime;
  } else if (status === 'ready') {
    order.preparation.readyTime = new Date();
  } else if (status === 'completed') {
    // Update food popularity
    for (const item of order.items) {
      await Food.findByIdAndUpdate(item.food, {
        $inc: { popularity: item.qty },
      });
    }
  }

  await order.save();

  res.json(order);
});

