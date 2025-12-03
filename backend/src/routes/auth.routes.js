import { Router } from "express";
import { protect } from "../middlewares/auth.js";
import { register, login, updateProfile, getMe } from "../controllers/auth.controller.js";

const router = Router();

router.post("/register", register);
router.post("/login", login);
router.get("/me", protect, getMe);
router.put("/me", protect, updateProfile);

export default router;
