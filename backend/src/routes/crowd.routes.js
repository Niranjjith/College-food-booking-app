import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import {
  getCrowdDensity,
  getZoneCrowdDensity,
  updateCrowdDensity,
} from '../controllers/crowd.controller.js';

const router = Router();

router.get('/', protect, getCrowdDensity);
router.get('/:zone', protect, getZoneCrowdDensity);
router.post('/update', protect, updateCrowdDensity); // For CCTV/AI system

export default router;

