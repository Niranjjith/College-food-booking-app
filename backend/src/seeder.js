import 'dotenv/config.js';
import mongoose from 'mongoose';
import Food from './models/Food.js';
import { connectDB } from './config/db.js';

const foods = [
  {
    name: "Veg Thali",
    description: "Rice, dal, sabzi, chapati, salad",
    price: 120,
    category: "Lunch",
    imageUrl: "https://i.imgur.com/4YQX8xR.png",
    isAvailable: true,
  },
  {
    name: "Chicken Biryani",
    description: "Aromatic basmati rice with chicken",
    price: 180,
    category: "Lunch",
    imageUrl: "https://i.imgur.com/aNXKq2G.png",
    isAvailable: true,
  },
  {
    name: "Paneer Butter Masala",
    description: "Creamy paneer curry with butter and spices",
    price: 150,
    category: "Dinner",
    imageUrl: "https://i.imgur.com/4T3HqBZ.png",
    isAvailable: true,
  },
  {
    name: "Masala Dosa",
    description: "Crispy dosa filled with spiced potatoes",
    price: 80,
    category: "Breakfast",
    imageUrl: "https://i.imgur.com/1nI2bYF.png",
    isAvailable: true,
  },
  {
    name: "Cold Coffee",
    description: "Chilled coffee with milk and ice cream",
    price: 60,
    category: "Beverage",
    imageUrl: "https://i.imgur.com/nmk3RhB.png",
    isAvailable: true,
  },
];

const seedFoods = async () => {
  try {
    await connectDB();
    await Food.deleteMany();
    await Food.insertMany(foods);
    console.log("✅ Foods seeded successfully");
    process.exit();
  } catch (err) {
    console.error("❌ Seeding failed", err);
    process.exit(1);
  }
};

seedFoods();
