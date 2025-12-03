import catchAsync from '../utils/catchAsync.js';

/**
 * Crowd Density Monitoring
 * 
 * Simulates CCTV + AI crowd density estimation
 * In production, this would integrate with actual CCTV feeds and AI models
 */

// In-memory storage (in production, use Redis or database)
const crowdData = {
  mainCounter: { density: 0, lastUpdate: null, capacity: 50 },
  secondaryCounter: { density: 0, lastUpdate: null, capacity: 30 },
  expressCounter: { density: 0, lastUpdate: null, capacity: 20 },
};

/**
 * Update crowd density for a pickup zone
 */
export const updateCrowdDensity = catchAsync(async (req, res) => {
  const { zone, density, timestamp } = req.body;

  if (!crowdData[zone]) {
    return res.status(400).json({ message: 'Invalid zone' });
  }

  const densityValue = Math.max(0, Math.min(100, density || 0)); // Clamp 0-100

  crowdData[zone] = {
    ...crowdData[zone],
    density: densityValue,
    lastUpdate: timestamp || new Date(),
  };

  res.json({
    success: true,
    zone,
    density: densityValue,
    status: getCrowdStatus(densityValue),
    recommendedAction: getRecommendedAction(zone, densityValue),
  });
});

/**
 * Get current crowd density for all zones
 */
export const getCrowdDensity = catchAsync(async (req, res) => {
  const zones = Object.keys(crowdData).map((zone) => ({
    zone,
    ...crowdData[zone],
    status: getCrowdStatus(crowdData[zone].density),
    waitTime: estimateWaitTime(crowdData[zone].density),
    recommendedAction: getRecommendedAction(zone, crowdData[zone].density),
  }));

  // Find best zone (lowest density)
  const bestZone = zones.reduce((best, current) =>
    current.density < best.density ? current : best
  );

  res.json({
    zones,
    bestZone: {
      zone: bestZone.zone,
      density: bestZone.density,
      waitTime: bestZone.waitTime,
      status: bestZone.status,
    },
    overallStatus: getOverallStatus(zones),
    recommendations: generateRecommendations(zones),
  });
});

/**
 * Get crowd status for a specific zone
 */
export const getZoneCrowdDensity = catchAsync(async (req, res) => {
  const { zone } = req.params;

  if (!crowdData[zone]) {
    return res.status(404).json({ message: 'Zone not found' });
  }

  const data = crowdData[zone];
  res.json({
    zone,
    ...data,
    status: getCrowdStatus(data.density),
    waitTime: estimateWaitTime(data.density),
    recommendedAction: getRecommendedAction(zone, data.density),
  });
});

// Helper functions
function getCrowdStatus(density) {
  if (density < 30) return 'low';
  if (density < 60) return 'medium';
  if (density < 85) return 'high';
  return 'very-high';
}

function estimateWaitTime(density) {
  // Estimate wait time in minutes based on density
  if (density < 30) return 2;
  if (density < 60) return 5;
  if (density < 85) return 10;
  return 15;
}

function getRecommendedAction(zone, density) {
  if (density < 30) {
    return {
      action: 'go',
      message: `Perfect time to pick up! ${zone} is not crowded.`,
      urgency: 'low',
    };
  }
  if (density < 60) {
    return {
      action: 'consider',
      message: `${zone} is moderately busy. Consider waiting 5-10 minutes.`,
      urgency: 'medium',
    };
  }
  if (density < 85) {
    const alternatives = Object.keys(crowdData)
      .filter((z) => z !== zone && crowdData[z].density < 60)
      .map((z) => z);
    
    return {
      action: 'wait-or-redirect',
      message: `${zone} is very busy. ${alternatives.length > 0 ? `Consider ${alternatives[0]}.` : 'Wait 10-15 minutes.'}`,
      urgency: 'high',
      alternatives,
    };
  }
  
  const alternatives = Object.keys(crowdData)
    .filter((z) => z !== zone && crowdData[z].density < 70)
    .map((z) => z);
  
  return {
    action: 'redirect',
    message: `${zone} is extremely crowded! ${alternatives.length > 0 ? `Redirect to ${alternatives[0]}.` : 'Wait 15+ minutes.'}`,
    urgency: 'very-high',
    alternatives,
  };
}

function getOverallStatus(zones) {
  const avgDensity = zones.reduce((sum, z) => sum + z.density, 0) / zones.length;
  return {
    averageDensity: Math.round(avgDensity),
    status: getCrowdStatus(avgDensity),
    allZonesBusy: zones.every((z) => z.density > 60),
  };
}

function generateRecommendations(zones) {
  const recommendations = [];
  const bestZone = zones.reduce((best, current) =>
    current.density < best.density ? current : best
  );

  if (bestZone.density < 30) {
    recommendations.push({
      type: 'optimal',
      message: `Best pickup time is now! ${bestZone.zone} has low crowd density.`,
      zone: bestZone.zone,
    });
  } else if (bestZone.density < 60) {
    recommendations.push({
      type: 'good',
      message: `Good time to pick up. ${bestZone.zone} is moderately busy.`,
      zone: bestZone.zone,
    });
  } else {
    recommendations.push({
      type: 'wait',
      message: `All zones are busy. Best to wait ${estimateWaitTime(bestZone.density)} minutes.`,
      suggestedTime: new Date(Date.now() + estimateWaitTime(bestZone.density) * 60000),
    });
  }

  return recommendations;
}


