import Food from '../models/Food.js';
import Order from '../models/Order.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * AI Chatbot for Food Recommendations & Support
 * 
 * Handles:
 * - Menu questions
 * - Food recommendations
 * - Complaint management
 * - Order status queries
 * - General support
 */

// Simple rule-based chatbot (in production, integrate with OpenAI, Dialogflow, etc.)
const responses = {
  greetings: [
    'Hello! How can I help you today?',
    'Hi there! What would you like to know?',
    'Welcome! I\'m here to help with your food ordering needs.',
  ],
  menu: [
    'You can browse our menu in the Foods section. We have a variety of delicious options!',
    'Check out our menu! We offer vegetarian, non-vegetarian, and healthy options.',
    'Our menu includes breakfast, lunch, dinner, and snacks. What are you in the mood for?',
  ],
  recommendations: [
    'Based on popular choices, I recommend trying our trending items!',
    'For a healthy option, check out items marked with the green badge.',
    'Our most popular items are usually great choices!',
  ],
  complaints: [
    'I\'m sorry to hear that. Please submit your complaint through the Feedback section, and our team will address it promptly.',
    'We take complaints seriously. Use the Feedback feature to report any issues.',
    'Thank you for bringing this to our attention. Please use the Feedback section for detailed complaints.',
  ],
  orderStatus: [
    'You can check your order status in the Orders section.',
    'Go to Orders to see the real-time status of your orders.',
    'Your order status is updated in real-time. Check the Orders tab!',
  ],
  default: [
    'I\'m here to help! You can ask me about the menu, place orders, check order status, or get recommendations.',
    'I can help with menu questions, recommendations, order status, and more. What do you need?',
    'Feel free to ask about our menu, place an order, or get food recommendations!',
  ],
};

export const chatWithBot = catchAsync(async (req, res) => {
  const { message, userId } = req.body;
  const userMessage = (message || '').toLowerCase().trim();

  if (!userMessage) {
    return res.json({
      response: 'Please send a message!',
      suggestions: ['Menu', 'Recommendations', 'Order Status', 'Complaints'],
    });
  }

  let response = '';
  let suggestions = [];
  let data = null;

  // Intent detection
  if (isGreeting(userMessage)) {
    response = getRandomResponse(responses.greetings);
    suggestions = ['Menu', 'Recommendations', 'Order Status'];
  } else if (isMenuQuestion(userMessage)) {
    const foods = await Food.find({ available: true }).limit(5);
    response = `We have ${foods.length}+ items available! Here are some popular ones: ${foods.map(f => f.name).join(', ')}. Check the menu for full details!`;
    suggestions = ['Recommendations', 'Healthy Options', 'Order Now'];
    data = { foods: foods.map(f => ({ name: f.name, price: f.price, category: f.category })) };
  } else if (isRecommendationRequest(userMessage)) {
    const recommendations = await getRecommendations(userId);
    response = recommendations.message;
    suggestions = ['View Menu', 'Order Now', 'More Options'];
    data = recommendations.data;
  } else if (isComplaint(userMessage)) {
    response = getRandomResponse(responses.complaints);
    suggestions = ['Submit Feedback', 'Contact Support', 'Menu'];
  } else if (isOrderStatusQuery(userMessage)) {
    if (userId) {
      const orders = await Order.find({ user: userId })
        .sort({ createdAt: -1 })
        .limit(3);
      if (orders.length > 0) {
        response = `You have ${orders.length} recent order(s). Latest order status: ${orders[0].status}. Check Orders section for details!`;
        data = { orders: orders.map(o => ({ id: o._id, status: o.status, items: o.items.length })) };
      } else {
        response = 'You don\'t have any orders yet. Place your first order!';
      }
    } else {
      response = getRandomResponse(responses.orderStatus);
    }
    suggestions = ['View Orders', 'Place Order', 'Menu'];
  } else if (isPriceQuestion(userMessage)) {
    const foods = await Food.find({ available: true }).limit(3);
    response = `Here are some prices: ${foods.map(f => `${f.name} - ₹${f.price}`).join(', ')}. Check the menu for all prices!`;
    suggestions = ['View Menu', 'Order Now'];
  } else if (isHealthyQuestion(userMessage)) {
    const healthyFoods = await Food.find({ available: true, isHealthy: true }).limit(5);
    if (healthyFoods.length > 0) {
      response = `We have healthy options! Try: ${healthyFoods.map(f => f.name).join(', ')}. They're marked with a green badge!`;
      data = { foods: healthyFoods.map(f => ({ name: f.name, healthScore: f.healthScore })) };
    } else {
      response = 'Check our menu for healthy options marked with the green badge!';
    }
    suggestions = ['View Menu', 'Order Healthy Meal'];
  } else {
    response = getRandomResponse(responses.default);
    suggestions = ['Menu', 'Recommendations', 'Order Status', 'Help'];
  }

  res.json({
    response,
    suggestions,
    data,
    timestamp: new Date(),
  });
});

// Helper functions for intent detection
function isGreeting(message) {
  return /^(hi|hello|hey|greetings|good morning|good afternoon|good evening)/.test(message);
}

function isMenuQuestion(message) {
  return /(menu|what.*available|what.*have|items|foods|dishes)/.test(message);
}

function isRecommendationRequest(message) {
  return /(recommend|suggest|what.*should|best|popular|trending|favorite)/.test(message);
}

function isComplaint(message) {
  return /(complaint|problem|issue|wrong|bad|terrible|disappointed|unhappy)/.test(message);
}

function isOrderStatusQuery(message) {
  return /(order.*status|where.*order|when.*ready|order.*ready|track.*order)/.test(message);
}

function isPriceQuestion(message) {
  return /(price|cost|how much|expensive|cheap|affordable)/.test(message);
}

function isHealthyQuestion(message) {
  return /(healthy|diet|calorie|nutrition|low.*fat|protein|vegetarian|vegan)/.test(message);
}

async function getRecommendations(userId) {
  // Get trending/popular foods
  const trending = await Food.find({ available: true })
    .sort({ popularity: -1 })
    .limit(3);

  if (trending.length > 0) {
    return {
      message: `I recommend trying: ${trending.map(f => f.name).join(', ')}. These are our most popular items!`,
      data: {
        type: 'recommendations',
        foods: trending.map(f => ({
          name: f.name,
          price: f.price,
          category: f.category,
          popularity: f.popularity,
        })),
      },
    };
  }

  return {
    message: 'Check out our menu for great options! All items are delicious.',
    data: null,
  };
}

function getRandomResponse(responses) {
  return responses[Math.floor(Math.random() * responses.length)];
}

