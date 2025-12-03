import { Router } from 'express';
import { protect } from '../middlewares/auth.js';
import { chatWithBot } from '../controllers/chatbot.controller.js';

const router = Router();

router.use(protect);
router.post('/chat', chatWithBot);

export default router;


