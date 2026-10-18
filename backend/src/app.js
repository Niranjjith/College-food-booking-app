import "./config/env.js";
import express from "express";
import cors from "cors";
import morgan from "morgan";
import { connectDB } from "./config/db.js";

import authRoutes from "./routes/auth.routes.js";
import foodRoutes from "./routes/foods.routes.js";
import orderRoutes from "./routes/orders.routes.js";
import paymentRoutes, { webhookRoute } from "./routes/payments.routes.js";
import queueRoutes from "./routes/queue.routes.js";
import inventoryRoutes from "./routes/inventory.routes.js";
import recommendationRoutes from "./routes/recommendations.routes.js";
import walletRoutes from "./routes/wallet.routes.js";
import qrRoutes from "./routes/qr.routes.js";
import subscriptionRoutes from "./routes/subscription.routes.js";
import feedbackRoutes from "./routes/feedback.routes.js";
import prioritizationRoutes from "./routes/prioritization.routes.js";
import crowdRoutes from "./routes/crowd.routes.js";
import chatbotRoutes from "./routes/chatbot.routes.js";
import eventRoutes from "./routes/event.routes.js";

connectDB();

const app = express();

app.use(cors({ origin: "*", credentials: true }));
app.use(express.json());
app.use(morgan("dev"));

// Health check
app.get("/health", (req, res) => {
  res.json({ ok: true });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/foods", foodRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/webhooks", webhookRoute);
app.use("/api/queue", queueRoutes);
app.use("/api/inventory", inventoryRoutes);
app.use("/api/recommendations", recommendationRoutes);
app.use("/api/wallet", walletRoutes);
app.use("/api/qr", qrRoutes);
app.use("/api/subscriptions", subscriptionRoutes);
app.use("/api/feedback", feedbackRoutes);
app.use("/api/prioritization", prioritizationRoutes);
app.use("/api/crowd", crowdRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/events", eventRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  const razorpayReady = Boolean(
    process.env.RAZORPAY_KEY_ID?.trim() && process.env.RAZORPAY_KEY_SECRET?.trim()
  );
  console.log(`✅ Server running on port ${PORT}`);
  console.log(razorpayReady ? "Razorpay: configured" : "Razorpay: missing RAZORPAY_KEY_ID/SECRET");
});
