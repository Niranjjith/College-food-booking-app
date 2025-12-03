import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import {
  getWallet,
  topUpWallet,
  payWithWallet,
  getTransactions,
  redeemPoints,
  getRewards,
} from '../controllers/wallet.controller.js';

const router = Router();

router.use(protect);

router.get('/', getWallet);
router.post('/topup', topUpWallet);
router.post('/pay', payWithWallet);
router.get('/transactions', getTransactions);
router.post('/redeem', redeemPoints);
router.get('/rewards', getRewards);

export default router;


