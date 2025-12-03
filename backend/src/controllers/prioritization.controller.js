import Order from '../models/Order.js';
import Food from '../models/Food.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Real-Time Order Prioritization Algorithm
 * 
 * Factors considered:
 * 1. Item preparation complexity (preparationTime)
 * 2. Kitchen capacity (current load)
 * 3. Order deadlines (scheduled orders, time since order)
 * 4. Item type (simple items first, complex items can be parallel)
 * 5. Customer priority (VIP, subscription orders)
 */
export const prioritizeOrders = catchAsync(async (req, res) => {
  const { kitchenCapacity = 5 } = req.query; // Max concurrent orders
  
  // Get all pending/preparing orders
  const orders = await Order.find({
    status: { $in: ['paid', 'preparing'] }
  })
    .sort({ createdAt: 1 }); // Start with oldest first

  // Calculate priority scores for each order
  const prioritizedOrders = await Promise.all(
    orders.map(async (order) => {
      let priorityScore = 0;
      const factors = {
        timeWaiting: 0,
        complexity: 0,
        deadline: 0,
        customerType: 0,
        itemCount: 0,
      };

      // 1. Time Waiting Factor (older orders get higher priority)
      const minutesWaiting = Math.floor(
        (Date.now() - new Date(order.createdAt).getTime()) / 60000
      );
      factors.timeWaiting = Math.min(minutesWaiting * 2, 50); // Max 50 points
      priorityScore += factors.timeWaiting;

      // 2. Complexity Factor (simpler items first)
      let totalComplexity = 0;
      let maxComplexity = 0;
      for (const item of order.items) {
        const food = await Food.findById(item.food);
        if (food) {
          const itemComplexity = food.preparationTime || 15;
          totalComplexity += itemComplexity * item.qty;
          maxComplexity = Math.max(maxComplexity, itemComplexity);
        }
      }
      // Lower complexity = higher priority (inverse)
      factors.complexity = Math.max(0, 30 - (maxComplexity / 2));
      priorityScore += factors.complexity;

      // 3. Deadline Factor (scheduled orders, urgent orders)
      if (order.isScheduled && order.scheduledDate) {
        const deadlineMinutes = Math.floor(
          (new Date(order.scheduledDate).getTime() - Date.now()) / 60000
        );
        if (deadlineMinutes < 30) {
          factors.deadline = 40; // Urgent
        } else if (deadlineMinutes < 60) {
          factors.deadline = 20; // Soon
        }
      }
      priorityScore += factors.deadline;

      // 4. Customer Type Factor (subscription orders, VIP)
      if (order.subscriptionId) {
        factors.customerType = 15; // Subscription orders
      }
      priorityScore += factors.customerType;

      // 5. Item Count Factor (fewer items = faster = higher priority)
      const itemCount = order.items.reduce((sum, item) => sum + item.qty, 0);
      factors.itemCount = Math.max(0, 10 - itemCount);
      priorityScore += factors.itemCount;

      // Calculate estimated completion time
      const estimatedMinutes = Math.ceil(totalComplexity / kitchenCapacity);

      return {
        order: {
          _id: order._id,
          user: order.user,
          items: order.items,
          subtotal: order.subtotal,
          status: order.status,
          createdAt: order.createdAt,
          scheduledDate: order.scheduledDate,
          isScheduled: order.isScheduled,
        },
        priorityScore: Math.round(priorityScore),
        factors,
        estimatedCompletionMinutes: estimatedMinutes,
        totalComplexity,
      };
    })
  );

  // Sort by priority score (highest first)
  prioritizedOrders.sort((a, b) => b.priorityScore - a.priorityScore);

  // Reorder queue positions
  const reorderedQueue = prioritizedOrders.map((item, index) => ({
    ...item,
    queuePosition: index + 1,
    recommendedAction: index < kitchenCapacity ? 'start' : 'wait',
  }));

  res.json({
    kitchenCapacity,
    totalOrders: orders.length,
    activeOrders: Math.min(orders.length, kitchenCapacity),
    waitingOrders: Math.max(0, orders.length - kitchenCapacity),
    prioritizedQueue: reorderedQueue,
    algorithm: {
      factors: {
        timeWaiting: 'Weight: 2 points per minute (max 50)',
        complexity: 'Weight: 30 - (max_prep_time / 2)',
        deadline: 'Weight: 40 (urgent), 20 (soon)',
        customerType: 'Weight: 15 (subscription)',
        itemCount: 'Weight: 10 - item_count',
      },
      totalMaxScore: 145,
    },
  });
});

/**
 * Get recommended kitchen actions
 */
export const getKitchenActions = catchAsync(async (req, res) => {
  const prioritized = await prioritizeOrders(req, res);
  // This will be handled by the prioritizeOrders function
});

/**
 * Update order priority manually (admin override)
 */
export const updateOrderPriority = catchAsync(async (req, res) => {
  const { orderId } = req.params;
  const { priorityBoost = 0 } = req.body;

  const order = await Order.findById(orderId);
  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  // Store priority boost in order metadata
  order.priorityBoost = priorityBoost;
  await order.save();

  res.json({
    message: 'Order priority updated',
    order: {
      _id: order._id,
      priorityBoost,
    },
  });
});

