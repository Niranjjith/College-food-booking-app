# 🍽️ Food Booking App

A **full-stack food ordering system** with premium UI/UX, featuring a Flutter mobile app for customers, a React admin dashboard, and a Node.js backend with MongoDB. Includes Razorpay payment integration and predictive analytics for demand forecasting.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## ✨ Features

### 📱 Customer App (Flutter)
- 🔐 **User Authentication** - Secure login and registration
- 🍔 **Food Menu** - Browse available food items with categories
- 🛒 **Shopping Cart** - Add items, manage quantities, view totals
- 💳 **Payment Integration** - Razorpay payment gateway with Cash on Delivery option
- 📦 **Order History** - View past orders with status tracking
- 👤 **Profile Management** - Update email and password
- 🎨 **Premium UI** - Modern Material Design 3 with smooth animations

### 🖥️ Admin Dashboard (React)
- 📊 **Analytics Dashboard** - Revenue charts, order summaries, and statistics
- 🔮 **Demand Forecasting** - Predictive analytics for inventory planning
- 🍲 **Food Management** - Add, edit, delete, and manage food items
- 📋 **Order Management** - View daily orders, mark as paid, track status
- 📈 **Sales Trends** - 7-day revenue trends and patterns
- ⏰ **Peak Hours Analysis** - Identify busiest hours and days
- 🎨 **Premium Design** - Modern UI with Tailwind CSS and gradient cards

### 🔧 Backend (Node.js)
- 🔒 **JWT Authentication** - Secure token-based authentication
- 💰 **Payment Processing** - Razorpay and Stripe integration
- 📊 **Analytics API** - Demand forecasting and trend analysis
- 🗄️ **MongoDB Database** - Scalable data storage with Mongoose ODM
- 🛡️ **Security** - Helmet, CORS, input validation

---

## 🛠️ Tech Stack

### Frontend (Customer)
- **Flutter** - Cross-platform mobile framework
- **Material Design 3** - Modern UI components
- **Razorpay Flutter SDK** - Payment integration
- **HTTP** - API communication
- **Shared Preferences** - Local storage

### Frontend (Admin)
- **React 18** - UI library
- **Tailwind CSS 3** - Utility-first CSS framework
- **Recharts** - Data visualization
- **React Router** - Navigation
- **Axios** - HTTP client
- **Lucide React** - Icon library

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - NoSQL database
- **Mongoose** - ODM for MongoDB
- **JWT** - Authentication tokens
- **Razorpay SDK** - Payment gateway
- **Bcrypt** - Password hashing

---

## 📂 Project Structure

```
food-booking-app/
├── backend/                 # Node.js + Express API
│   ├── src/
│   │   ├── config/         # Database configuration
│   │   ├── controllers/     # Business logic
│   │   ├── middlewares/     # Auth & error handling
│   │   ├── models/          # Mongoose schemas
│   │   ├── routes/          # API routes
│   │   └── utils/          # Helper functions
│   ├── package.json
│   └── .env                # Environment variables
│
├── admin/                  # React Admin Dashboard
│   ├── src/
│   │   ├── components/     # Reusable components
│   │   ├── pages/         # Page components
│   │   ├── api/           # API configuration
│   │   └── App.js         # Main app component
│   ├── package.json
│   └── tailwind.config.js
│
└── frontend/               # Flutter Customer App
    ├── lib/
    │   ├── models/        # Data models
    │   ├── screens/       # UI screens
    │   ├── services/      # API service
    │   └── widgets/       # Reusable widgets
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v16 or higher)
- **MongoDB** (v5 or higher) - [Install MongoDB](https://www.mongodb.com/try/download/community)
- **Flutter** (v3.9 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **npm** or **yarn**

---

## 📦 Installation & Setup

### 1️⃣ Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env  # Or create manually
```

**Configure `.env` file:**
```env
# Database
MONGO_URI=mongodb://localhost:27017/food-booking
# Or use MongoDB Atlas: mongodb+srv://username:password@cluster.mongodb.net/food-booking

# Server
PORT=5000
NODE_ENV=development

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Admin Credentials (Optional - for auto-seeding)
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=Admin@123

# Razorpay (Get from https://razorpay.com/dashboard)
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Stripe (Optional)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret
```

**Start the backend:**
```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The backend will run on `http://localhost:5000`

**Seed sample food data (optional):**
```bash
node src/seeder.js
```

---

### 2️⃣ Admin Dashboard Setup

```bash
# Navigate to admin directory
cd admin

# Install dependencies
npm install

# Start development server
npm start
```

The admin dashboard will open at `http://localhost:3000`

---

### 3️⃣ Flutter App Setup

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run                    # Auto-detect device
flutter run -d chrome          # Web browser
flutter run -d windows         # Windows desktop
flutter run -d android         # Android device/emulator
flutter run -d ios             # iOS simulator (Mac only)
```

**Note:** Update the API base URL in `lib/services/api_service.dart` if your backend is running on a different host/port.

---

## 🔐 Login Credentials

### Admin Dashboard

**Default Admin Account:**
- **Email:** `admin@example.com`
- **Password:** `Admin@123`

> ⚠️ **Important:** Change these credentials in production! The admin account is auto-created on first run if `ADMIN_EMAIL` and `ADMIN_PASSWORD` are set in `.env`.

**To create a new admin:**
1. Register a user through the Flutter app
2. Update the user's role to `admin` in MongoDB:
   ```javascript
   db.users.updateOne(
     { email: "your-email@example.com" },
     { $set: { role: "admin" } }
   )
   ```

### Customer App

**Test User (Create via Registration):**
- Register a new account through the app
- Or create manually in MongoDB:
  ```javascript
  db.users.insertOne({
    name: "Test User",
    email: "user@example.com",
    password: "$2b$10$hashed_password_here", // Use bcrypt to hash
    role: "user"
  })
  ```

---

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user profile
- `PUT /api/auth/me` - Update profile

### Foods
- `GET /api/foods` - Get all foods
- `GET /api/foods/:id` - Get food by ID
- `POST /api/foods` - Create food (Admin only)
- `PUT /api/foods/:id` - Update food (Admin only)
- `DELETE /api/foods/:id` - Delete food (Admin only)

### Orders
- `POST /api/orders` - Create order
- `GET /api/orders/mine` - Get user's orders
- `GET /api/orders/:id` - Get order by ID
- `GET /api/orders/admin/daily` - Get today's orders (Admin)
- `GET /api/orders/admin/summary` - Get summary stats (Admin)
- `GET /api/orders/admin/sales-trend` - Get sales trends (Admin)
- `GET /api/orders/admin/demand-forecast` - Demand forecasting (Admin)
- `PATCH /api/orders/:id/mark-paid` - Mark order as paid (Admin)

### Payments
- `POST /api/payments/razorpay/create-order` - Create Razorpay order
- `POST /api/payments/razorpay/verify` - Verify Razorpay payment
- `POST /api/payments/intent` - Create Stripe payment intent (Optional)

---

## 💳 Payment Setup

### Razorpay Configuration

1. **Sign up** at [Razorpay](https://razorpay.com/)
2. **Get API Keys:**
   - Go to Settings → API Keys
   - Copy Key ID and Key Secret
3. **Add to `.env`:**
   ```env
   RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
   RAZORPAY_KEY_SECRET=your_key_secret_here
   ```
4. **Test Mode:**
   - Use test keys for development
   - Test cards: [Razorpay Test Cards](https://razorpay.com/docs/payments/test-cards/)

For detailed Razorpay setup, see [RAZORPAY_SETUP.md](./RAZORPAY_SETUP.md)

---

## 📊 Features Overview

### Demand Forecasting Analytics

The admin dashboard includes predictive analytics:
- **Food Demand Prediction** - Forecast which items will be popular
- **Daily Volume Trends** - Historical order patterns
- **Peak Hours Analysis** - Identify busiest times
- **Day of Week Patterns** - Weekly trends
- **Revenue Forecasting** - Predict future sales
- **Top Predicted Foods** - Items likely to be in high demand

Access via: Admin Dashboard → Analytics

---

## 🎨 UI/UX Features

### Premium Design Elements
- ✨ Modern Material Design 3 (Flutter)
- 🎨 Gradient cards and buttons
- 🌈 Consistent color scheme (Emerald Green primary)
- 📱 Responsive layouts
- ⚡ Smooth animations and transitions
- 🎯 Intuitive navigation
- 💎 Professional typography

---

## 🧪 Testing

### Backend API Testing
```bash
# Use Postman, Insomnia, or curl
curl http://localhost:5000/api/foods
```

### Flutter Testing
```bash
cd frontend
flutter test
```

### Admin Dashboard
- Manual testing through browser
- React testing library available

---

## 🐛 Troubleshooting

### Backend Issues
- **MongoDB Connection Error:** Ensure MongoDB is running and `MONGO_URI` is correct
- **Port Already in Use:** Change `PORT` in `.env` or kill the process using port 5000
- **JWT Errors:** Verify `JWT_SECRET` is set in `.env`

### Admin Dashboard Issues
- **Tailwind CSS Errors:** Run `npm install` again and restart dev server
- **API Connection:** Check backend is running and CORS is configured

### Flutter Issues
- **Build Errors:** Run `flutter clean` then `flutter pub get`
- **API Connection:** Update base URL in `api_service.dart` for your network
- **Payment Not Working:** Verify Razorpay keys are set correctly

---

## 📝 Environment Variables Reference

### Backend (.env)
```env
# Required
MONGO_URI=mongodb://localhost:27017/food-booking
PORT=5000
JWT_SECRET=your-secret-key

# Optional
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=Admin@123
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
STRIPE_SECRET_KEY=your_stripe_key
NODE_ENV=development
```

---

## 🚀 Deployment

### Backend
- Deploy to **Heroku**, **Railway**, **Render**, or **AWS**
- Set environment variables in hosting platform
- Use MongoDB Atlas for cloud database

### Admin Dashboard
- Build: `npm run build`
- Deploy to **Vercel**, **Netlify**, or **AWS S3**

### Flutter App
- **Android:** `flutter build apk` or `flutter build appbundle`
- **iOS:** `flutter build ios`
- **Web:** `flutter build web`

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Support

For support, email support@example.com or create an issue in the repository.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [React](https://reactjs.org/) - Admin dashboard
- [Razorpay](https://razorpay.com/) - Payment gateway
- [MongoDB](https://www.mongodb.com/) - Database
- [Tailwind CSS](https://tailwindcss.com/) - Styling

---

## 📸 Screenshots

### Customer App
- Login/Register screens with premium design
- Food menu with beautiful cards
- Shopping cart with payment options
- Order history with status tracking
- Profile management

### Admin Dashboard
- Analytics dashboard with charts
- Food management interface
- Order management system
- Demand forecasting analytics

![Admin Dashboard](Screenshot/Admin%20page.png)

---

**Made with ❤️ using Flutter, React, and Node.js**
