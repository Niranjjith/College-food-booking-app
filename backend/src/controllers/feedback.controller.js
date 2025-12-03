import Feedback from '../models/Feedback.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Create feedback/issue report
 */
export const createFeedback = catchAsync(async (req, res) => {
  const { type, category, title, description, orderId, foodId, rating } = req.body;

  const feedback = await Feedback.create({
    user: req.user._id,
    type,
    category,
    title,
    description,
    orderId,
    foodId,
    rating,
  });

  res.status(201).json(feedback);
});

/**
 * Get user's feedback
 */
export const getMyFeedback = catchAsync(async (req, res) => {
  const feedbacks = await Feedback.find({ user: req.user._id })
    .populate('orderId', 'subtotal status')
    .populate('foodId', 'name image')
    .sort({ createdAt: -1 });

  res.json(feedbacks);
});

/**
 * Get all feedback (Admin)
 */
export const getAllFeedback = catchAsync(async (req, res) => {
  const { status, type, priority } = req.query;
  const filter = {};
  if (status) filter.status = status;
  if (type) filter.type = type;
  if (priority) filter.priority = priority;

  const feedbacks = await Feedback.find(filter)
    .populate('user', 'name email registrationNumber')
    .populate('orderId', 'subtotal status')
    .populate('foodId', 'name image')
    .sort({ createdAt: -1 });

  res.json(feedbacks);
});

/**
 * Update feedback status (Admin)
 */
export const updateFeedbackStatus = catchAsync(async (req, res) => {
  const { status, adminResponse } = req.body;
  const feedback = await Feedback.findById(req.params.id);

  if (!feedback) {
    return res.status(404).json({ message: 'Feedback not found' });
  }

  feedback.status = status;
  if (adminResponse) feedback.adminResponse = adminResponse;
  if (status === 'resolved') feedback.resolvedAt = new Date();

  await feedback.save();

  res.json(feedback);
});

/**
 * Get feedback statistics (Admin)
 */
export const getFeedbackStats = catchAsync(async (req, res) => {
  const stats = await Feedback.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
      },
    },
  ]);

  const typeStats = await Feedback.aggregate([
    {
      $group: {
        _id: '$type',
        count: { $sum: 1 },
      },
    },
  ]);

  const categoryStats = await Feedback.aggregate([
    {
      $group: {
        _id: '$category',
        count: { $sum: 1 },
      },
    },
  ]);

  res.json({
    byStatus: stats,
    byType: typeStats,
    byCategory: categoryStats,
  });
});


