# Razorpay Payment Integration Setup

## Backend Setup

1. **Install Razorpay SDK** (Already done)
   ```bash
   npm install razorpay
   ```

2. **Get Razorpay API Keys**
   - Go to https://razorpay.com/
   - Sign up or log in
   - Go to Settings → API Keys
   - Generate Key ID and Key Secret

3. **Add Environment Variables**
   Create or update `.env` file in the `backend` folder:
   ```env
   RAZORPAY_KEY_ID=your_key_id_here
   RAZORPAY_KEY_SECRET=your_key_secret_here
   ```

## Flutter App Setup

1. **Install Razorpay Flutter Package** (Already added to pubspec.yaml)
   ```bash
   flutter pub get
   ```

2. **Android Configuration**
   - The package should work out of the box for Android
   - No additional configuration needed

3. **iOS Configuration** (if needed)
   - Add to `ios/Runner/Info.plist`:
   ```xml
   <key>razorpay</key>
   <string>your_key_id_here</string>
   ```

## API Endpoints

### Create Razorpay Order
- **POST** `/api/payments/razorpay/create-order`
- **Body:**
  ```json
  {
    "orderId": "order_id_from_database"
  }
  ```
- **Response:**
  ```json
  {
    "id": "order_xxx",
    "amount": 10000,
    "currency": "INR",
    "key": "your_razorpay_key_id"
  }
  ```

### Verify Payment
- **POST** `/api/payments/razorpay/verify`
- **Body:**
  ```json
  {
    "orderId": "order_id",
    "razorpay_order_id": "order_xxx",
    "razorpay_payment_id": "pay_xxx",
    "razorpay_signature": "signature_xxx"
  }
  ```

## Testing

### Test Mode
- Use Razorpay Test Mode keys for development
- Test cards: https://razorpay.com/docs/payments/test-cards/

### Test UPI IDs
- Use test UPI IDs provided by Razorpay for testing

## Payment Flow

1. User adds items to cart
2. User clicks "Place Order"
3. Order is created in database
4. Razorpay order is created via API
5. Razorpay checkout opens
6. User completes payment
7. Payment is verified on backend
8. Order status updated to "paid"

## Features

- ✅ Razorpay payment integration
- ✅ Payment verification with signature
- ✅ Cash on Delivery option
- ✅ Payment method selection UI
- ✅ Error handling
- ✅ Loading states

## Notes

- Make sure to use HTTPS in production
- Keep your Razorpay Key Secret secure (never expose in frontend)
- Always verify payment signature on backend
- Test thoroughly before going live

