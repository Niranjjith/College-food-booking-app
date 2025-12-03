import Event from '../models/Event.js';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Get all active events
 */
export const getActiveEvents = catchAsync(async (req, res) => {
  const now = new Date();
  const events = await Event.find({
    startDate: { $lte: now },
    endDate: { $gte: now },
    status: 'active',
  })
    .populate('bundles.items.food')
    .sort({ startDate: 1 });

  res.json(events);
});

/**
 * Get all events (upcoming, active, ended)
 */
export const getAllEvents = catchAsync(async (req, res) => {
  const { status } = req.query;
  const filter = {};
  if (status) filter.status = status;

  const events = await Event.find(filter)
    .populate('bundles.items.food')
    .sort({ startDate: -1 });

  res.json(events);
});

/**
 * Get single event
 */
export const getEvent = catchAsync(async (req, res) => {
  const event = await Event.findById(req.params.id)
    .populate('bundles.items.food');

  if (!event) {
    return res.status(404).json({ message: 'Event not found' });
  }

  res.json(event);
});

/**
 * Create event (Admin)
 */
export const createEvent = catchAsync(async (req, res) => {
  const event = await Event.create(req.body);
  res.status(201).json(event);
});

/**
 * Update event (Admin)
 */
export const updateEvent = catchAsync(async (req, res) => {
  const event = await Event.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  );

  if (!event) {
    return res.status(404).json({ message: 'Event not found' });
  }

  res.json(event);
});

/**
 * Register for event
 */
export const registerForEvent = catchAsync(async (req, res) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return res.status(404).json({ message: 'Event not found' });
  }

  if (event.registrationRequired) {
    if (event.registeredUsers.includes(req.user._id)) {
      return res.status(400).json({ message: 'Already registered for this event' });
    }
    event.registeredUsers.push(req.user._id);
    await event.save();
  }

  res.json({ message: 'Registered successfully', event });
});

/**
 * Order event bundle
 */
export const orderEventBundle = catchAsync(async (req, res) => {
  const { bundleId } = req.body;
  const event = await Event.findById(req.params.id);

  if (!event) {
    return res.status(404).json({ message: 'Event not found' });
  }

  const bundle = event.bundles.id(bundleId);
  if (!bundle || !bundle.available) {
    return res.status(404).json({ message: 'Bundle not found or unavailable' });
  }

  // Check if event is active
  const now = new Date();
  if (now < event.startDate || now > event.endDate) {
    return res.status(400).json({ message: 'Event is not active' });
  }

  // Check registration if required
  if (event.registrationRequired && !event.registeredUsers.includes(req.user._id)) {
    return res.status(403).json({ message: 'Registration required for this event' });
  }

  // Check order limit
  if (event.maxOrders && event.currentOrders >= event.maxOrders) {
    return res.status(400).json({ message: 'Event order limit reached' });
  }

  // Create order from bundle
  const orderItems = bundle.items.map((item) => ({
    food: item.food._id || item.food,
    name: item.name || item.food.name,
    qty: item.qty,
    price: bundle.price / bundle.items.length, // Distribute price
  }));

  const order = await Order.create({
    user: req.user._id,
    items: orderItems,
    subtotal: bundle.price,
    status: 'pending',
    isScheduled: false,
    payment: {
      provider: 'event-bundle',
    },
  });

  // Update event order count
  event.currentOrders += 1;
  await event.save();

  res.status(201).json({
    message: 'Event bundle ordered successfully',
    order,
    bundle: {
      name: bundle.name,
      price: bundle.price,
      discount: bundle.discount,
    },
  });
});

/**
 * Get event statistics (Admin)
 */
export const getEventStats = catchAsync(async (req, res) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return res.status(404).json({ message: 'Event not found' });
  }

  const orders = await Order.find({
    user: { $in: event.registeredUsers },
    createdAt: {
      $gte: event.startDate,
      $lte: event.endDate,
    },
  });

  const revenue = orders.reduce((sum, order) => sum + order.subtotal, 0);

  res.json({
    event: {
      name: event.name,
      startDate: event.startDate,
      endDate: event.endDate,
    },
    statistics: {
      totalRegistrations: event.registeredUsers.length,
      totalOrders: orders.length,
      revenue,
      averageOrderValue: orders.length > 0 ? revenue / orders.length : 0,
      bundlesOrdered: event.currentOrders,
    },
  });
});


