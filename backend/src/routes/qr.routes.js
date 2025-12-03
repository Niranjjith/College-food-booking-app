import { Router } from 'express';
import { protect, adminOnly } from '../middlewares/auth.js';
import {
  generateQRCode,
  verifyQRCode,
  getOrderByPickupCode,
  verifyStudentId,
} from '../controllers/qr.controller.js';

const router = Router();

router.get('/order/:id', protect, generateQRCode);
router.get('/pickup/:code', protect, getOrderByPickupCode);
router.post('/verify', protect, adminOnly, verifyQRCode);
router.post('/verify-student', protect, verifyStudentId);

export default router;

