import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  generateQRCode,
  verifyQRCode,
  getOrderByPickupCode,
} from '../controllers/qr.controller.js';

const router = Router();

router.get('/order/:id', protect, generateQRCode);
router.get('/pickup/:code', protect, getOrderByPickupCode);
router.post('/verify', protect, adminOnly, verifyQRCode);

export default router;

