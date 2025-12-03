import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';
import crypto from 'crypto';

/**
 * Generate QR code for order pickup
 */
export const generateQRCode = catchAsync(async (req, res) => {
  const order = await Order.findById(req.params.id);
  
  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  // Check if user owns the order
  if (order.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Unauthorized' });
  }

  // Generate unique pickup code
  if (!order.pickupCode) {
    order.pickupCode = crypto.randomBytes(4).toString('hex').toUpperCase();
  }

  // Generate QR code data (JSON string with order info)
  const qrData = {
    orderId: order._id.toString(),
    pickupCode: order.pickupCode,
    userId: order.user.toString(),
    timestamp: new Date().toISOString(),
  };

  order.qrCode = JSON.stringify(qrData);
  await order.save();

  res.json({
    qrCode: order.qrCode,
    pickupCode: order.pickupCode,
    orderId: order._id,
    status: order.status,
  });
});

/**
 * Verify Student ID for pickup
 */
export const verifyStudentId = catchAsync(async (req, res) => {
  const { orderId, studentId } = req.body;
  
  const order = await Order.findById(orderId).populate('user', 'studentId registrationNumber');
  
  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  // Check if student ID matches
  if (order.user.studentId !== studentId && order.user.registrationNumber !== studentId) {
    return res.status(400).json({ message: 'Student ID does not match' });
  }

  // Check if order is ready
  if (order.status !== 'ready') {
    return res.status(400).json({ 
      message: `Order is ${order.status}, not ready for pickup`,
      status: order.status,
    });
  }

  res.json({
    success: true,
    message: 'Student ID verified',
    order: {
      id: order._id,
      user: order.user,
      status: order.status,
    },
  });
});

/**
 * Verify QR code for pickup (Staff/Admin)
 */
export const verifyQRCode = catchAsync(async (req, res) => {
  const { qrData } = req.body;

  try {
    const qrInfo = JSON.parse(qrData);
    const order = await Order.findById(qrInfo.orderId)
      .populate('user', 'name email');

    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Verify pickup code
    if (order.pickupCode !== qrInfo.pickupCode) {
      return res.status(400).json({ message: 'Invalid pickup code' });
    }

    // Check if order is ready
    if (order.status !== 'ready') {
      return res.status(400).json({ 
        message: `Order is ${order.status}, not ready for pickup`,
        status: order.status,
      });
    }

    // Mark as completed
    order.status = 'completed';
    await order.save();

    res.json({
      success: true,
      order: {
        id: order._id,
        user: order.user,
        items: order.items,
        subtotal: order.subtotal,
      },
      message: 'Order verified and completed',
    });
  } catch (error) {
    res.status(400).json({ message: 'Invalid QR code format' });
  }
});

/**
 * Get order by pickup code
 */
export const getOrderByPickupCode = catchAsync(async (req, res) => {
  const { code } = req.params;
  
  const order = await Order.findOne({ pickupCode: code.toUpperCase() })
    .populate('user', 'name email');

  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  res.json({
    order: {
      id: order._id,
      user: order.user,
      items: order.items,
      subtotal: order.subtotal,
      status: order.status,
      pickupCode: order.pickupCode,
    },
  });
});

