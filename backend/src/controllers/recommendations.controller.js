import Food from '../models/Food.js';
import Order from '../models/Order.js';
import UserPreference from '../models/UserPreference.js';
import catchAsync from '../utils/catchAsync.js';

/**
 * Get personalized recommendations for a user
 */
export const getRecommendations = catchAsync(async (req, res) => {
  const userId = req.user._id;

  // Get user preferences
  let userPrefs = await UserPreference.findOne({ user: userId });
  if (!userPrefs) {
    userPrefs = await UserPreference.create({ user: userId });
  }

  // Get user's order history
  const userOrders = await Order.find({
    user: userId,
    status: { $in: ['paid', 'completed'] },
  }).populate('items.food');

  // Build recommendation algorithm
  const recommendations = await buildRecommendations(userId, userPrefs, userOrders);

  res.json({
    recommendations,
    basedOn: {
      orderHistory: userOrders.length > 0,
      preferences: userPrefs.dietaryRestrictions.length > 0 || userPrefs.favoriteCategories.length > 0,
      trending: true,
    },
  });
});

/**
 * Build recommendation algorithm
 */
const buildRecommendations = async (userId, userPrefs, userOrders) => {
  const allFoods = await Food.find({ isAvailable: true });

  // Score each food
  const scoredFoods = await Promise.all(
    allFoods.map(async (food) => {
      let score = 0;

      // 1. Order history (40% weight)
      const orderCount = userOrders.reduce((count, order) => {
        return count + order.items.filter((item) => item.food._id.toString() === food._id.toString()).length;
      }, 0);
      score += orderCount * 40;

      // 2. Category preference (20% weight)
      if (userPrefs.favoriteCategories.includes(food.category)) {
        score += 20;
      }

      // 3. Price range (15% weight)
      if (food.price >= userPrefs.preferredPriceRange.min && food.price <= userPrefs.preferredPriceRange.max) {
        score += 15;
      }

      // 4. Popularity/trending (15% weight)
      score += Math.min(food.popularity / 10, 15);

      // 5. Dietary restrictions (10% weight)
      // Check if food matches dietary restrictions
      const matchesDietary = checkDietaryMatch(food, userPrefs.dietaryRestrictions);
      if (matchesDietary) {
        score += 10;
      } else if (userPrefs.dietaryRestrictions.length > 0) {
        score -= 50; // Heavy penalty if doesn't match dietary restrictions
      }

      // 6. Disliked foods penalty
      if (userPrefs.dislikedFoods.some((id) => id.toString() === food._id.toString())) {
        score -= 100;
      }

      // 7. New items boost (if never ordered)
      if (orderCount === 0 && food.createdAt > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)) {
        score += 5; // Boost for new items
      }

      return { food, score };
    })
  );

  // Sort by score and return top recommendations
  return scoredFoods
    .filter((item) => item.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 10)
    .map((item) => ({
      food: item.food,
      score: item.score,
      reason: getRecommendationReason(item.food, userPrefs, userOrders),
    }));
};

/**
 * Check if food matches dietary restrictions
 */
const checkDietaryMatch = (food, restrictions) => {
  if (restrictions.length === 0) return true;

  const foodTags = food.tags || [];
  const foodCategory = food.category?.toLowerCase() || '';

  // Simple matching logic (can be enhanced)
  if (restrictions.includes('vegetarian') && !foodTags.includes('non-veg')) {
    return true;
  }
  if (restrictions.includes('vegan') && foodTags.includes('vegan')) {
    return true;
  }
  if (restrictions.includes('gluten-free') && foodTags.includes('gluten-free')) {
    return true;
  }

  return false;
};

/**
 * Get reason for recommendation
 */
const getRecommendationReason = (food, userPrefs, userOrders) => {
  const orderCount = userOrders.reduce((count, order) => {
    return count + order.items.filter((item) => item.food._id.toString() === food._id.toString()).length;
  }, 0);

  if (orderCount > 0) {
    return `You've ordered this ${orderCount} time${orderCount > 1 ? 's' : ''} before`;
  }
  if (userPrefs.favoriteCategories.includes(food.category)) {
    return `Matches your favorite category: ${food.category}`;
  }
  if (food.popularity > 50) {
    return 'Trending item';
  }
  return 'Recommended for you';
};

/**
 * Update user preferences
 */
export const updatePreferences = catchAsync(async (req, res) => {
  const userId = req.user._id;
  const {
    dietaryRestrictions,
    favoriteCategories,
    dislikedFoods,
    allergies,
    preferredPriceRange,
  } = req.body;

  let userPrefs = await UserPreference.findOne({ user: userId });
  if (!userPrefs) {
    userPrefs = await UserPreference.create({ user: userId });
  }

  if (dietaryRestrictions) userPrefs.dietaryRestrictions = dietaryRestrictions;
  if (favoriteCategories) userPrefs.favoriteCategories = favoriteCategories;
  if (dislikedFoods) userPrefs.dislikedFoods = dislikedFoods;
  if (allergies) userPrefs.allergies = allergies;
  if (preferredPriceRange) userPrefs.preferredPriceRange = preferredPriceRange;

  await userPrefs.save();
  res.json(userPrefs);
});

/**
 * Get trending foods
 */
export const getTrendingFoods = catchAsync(async (req, res) => {
  const trending = await Food.find({ isAvailable: true })
    .sort({ popularity: -1 })
    .limit(10);

  res.json(trending);
});

