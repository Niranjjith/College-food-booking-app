import { Router } from "express";
import { protect, adminOnly } from "../middlewares/auth.js";
import {
  createOrder,
  myOrders,
  getOrder,
  adminDailyOrders,
  markPaid,
  adminSummary,
  adminSalesTrend,
} from "../controllers/orders.controller.js";

const router = Router();

// Student routes
router.post("/", protect, createOrder);
router.get("/mine", protect, myOrders);
router.get("/:id", protect, getOrder);

// Admin routes
router.get("/admin/daily", protect, adminOnly, adminDailyOrders);
router.get("/admin/summary", protect, adminOnly, adminSummary);
router.get("/admin/sales-trend", protect, adminOnly, adminSalesTrend);
router.patch("/:id/mark-paid", protect, adminOnly, markPaid);

export default router;
