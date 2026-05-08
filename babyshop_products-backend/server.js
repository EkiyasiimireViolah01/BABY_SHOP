const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// Middleware - CORS fixed for Flutter Web
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.options('*', cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// MongoDB Connection
const MONGODB_URI = process.env.MONGO_URI;
if (!MONGODB_URI) {
  console.log('❌ MONGO_URI not set in environment variables');
  process.exit(1);
}

mongoose.connect(MONGODB_URI)
.then(() => console.log('✅ MongoDB connected successfully'))
.catch(err => {
  console.log('❌ MongoDB connection error:', err);
  process.exit(1);
});

// ==================== MODELS ====================

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, default: '' },
  address: { type: String, default: '' },
  role: { type: String, default: 'customer' },
  location: {
    lat: Number,
    lng: Number,
    address: String
  },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  price: { type: Number, required: true },
  description: { type: String, default: '' },
  category: { type: String, default: '' },
  image: { type: String, default: '' },
  stock: { type: Number, default: 0 }
}, { timestamps: true });

const Product = mongoose.model('Product', productSchema);

const orderSchema = new mongoose.Schema({
  orderNumber: { type: String, unique: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  customerName: { type: String, required: true },
  customerEmail: { type: String, required: true },
  phone: { type: String, required: true },
  location: { type: String, required: true },
  items: [{
    productId: String,
    name: String,
    price: Number,
    quantity: Number,
    image: String
  }],
  totalAmount: { type: Number, required: true },
  paymentMethod: { type: String, default: 'cod' },
  status: { type: String, default: 'Pending' },
  date: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

const Order = mongoose.model('Order', orderSchema);

const feedbackSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  customerName: { type: String, required: true },
  customerEmail: { type: String, required: true },
  message: { type: String, required: true },
  date: { type: String, default: '' },
  status: { type: String, default: 'New' },
  reply: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

const Feedback = mongoose.model('Feedback', feedbackSchema);

// ==================== AUTH ROUTES ====================

app.post('/api/auth/register', async (req, res) => {
  try {
    console.log('📝 Register request:', req.body.email);
    const { name, email, password, phone, address } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({
      name,
      email,
      password: hashedPassword,
      phone: phone || '',
      address: address || '',
      role: 'customer'
    });

    await user.save();
    console.log('✅ User saved:', user._id);

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET);
    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.log('❌ Register error:', error.message);
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET);
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/auth/admin-login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (username === 'admin' && password === 'admin1234') {
      let admin = await User.findOne({ email: 'admin@babyshop.com' });

      if (!admin) {
        const hashedPassword = await bcrypt.hash('admin1234', 10);
        admin = new User({
          name: 'Admin',
          email: 'admin@babyshop.com',
          password: hashedPassword,
          role: 'admin'
        });
        await admin.save();
      }

      const token = jwt.sign({ userId: admin._id }, process.env.JWT_SECRET);
      res.json({
        token,
        user: {
          id: admin._id,
          name: admin.name,
          email: admin.email,
          role: 'admin'
        }
      });
    } else {
      res.status(401).json({ message: 'Invalid admin credentials' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ==================== PRODUCT ROUTES ====================

app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.find().sort({ createdAt: -1 });
    console.log(`📦 Found ${products.length} products`);
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    console.log('➕ Creating product:', req.body.name);
    const product = new Product(req.body);
    await product.save();
    console.log('✅ Product saved:', product._id);
    res.status(201).json(product);
  } catch (error) {
    console.log('❌ Create product error:', error.message);
    res.status(400).json({ message: error.message });
  }
});

app.put('/api/products/:id', async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
    console.log('✏️ Product updated:', product._id);
    res.json(product);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

app.delete('/api/products/:id', async (req, res) => {
  try {
    await Product.findByIdAndDelete(req.params.id);
    console.log('🗑️ Product deleted:', req.params.id);
    res.json({ message: 'Product deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ==================== ORDER ROUTES ====================

app.post('/api/orders', async (req, res) => {
  try {
    console.log('📦 Creating order for:', req.body.customerName);
    const orderNumber = 'ORD-' + Date.now();
    const order = new Order({
  ...req.body,
      orderNumber,
    });
    await order.save();
    console.log('✅ Order saved:', order.orderNumber);
    res.status(201).json(order);
  } catch (error) {
    console.log('❌ Create order error:', error.message);
    res.status(400).json({ message: error.message });
  }
});

app.get('/api/orders', async (req, res) => {
  try {
    const orders = await Order.find().sort({ createdAt: -1 });
    console.log(`📋 Found ${orders.length} orders`);
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/orders/my-orders', async (req, res) => {
  try {
    const orders = await Order.find({ customerEmail: req.query.email }).sort({ createdAt: -1 });
    console.log(`📋 Found ${orders.length} orders for ${req.query.email}`);
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/orders/:id/status', async (req, res) => {
  try {
    const { orderStatus } = req.body;
    const order = await Order.findByIdAndUpdate(req.params.id, { status: orderStatus }, { new: true });
    console.log('🔄 Order status updated:', order.orderNumber, '->', orderStatus);
    res.json(order);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// ==================== FEEDBACK ROUTES ====================

app.post('/api/feedback', async (req, res) => {
  try {
    console.log('💬 Creating feedback from:', req.body.customerName);
    const feedback = new Feedback(req.body);
    await feedback.save();
    console.log('✅ Feedback saved:', feedback._id);
    res.status(201).json(feedback);
  } catch (error) {
    console.log('❌ Create feedback error:', error.message);
    res.status(400).json({ message: error.message });
  }
});

app.get('/api/feedback', async (req, res) => {
  try {
    const feedbacks = await Feedback.find().sort({ createdAt: -1 });
    console.log(`💬 Found ${feedbacks.length} feedbacks`);
    res.json(feedbacks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.put('/api/feedback/:id', async (req, res) => {
  try {
    const { status, reply } = req.body;
    const feedback = await Feedback.findByIdAndUpdate(req.params.id, { status, reply }, { new: true });
    console.log('✏️ Feedback updated:', feedback._id);
    res.json(feedback);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// ==================== ADMIN ROUTES ====================

app.get('/api/admin/stats', async (req, res) => {
  try {
    const totalOrders = await Order.countDocuments();
    const totalProducts = await Product.countDocuments();
    const totalCustomers = await User.countDocuments({ role: 'customer' });
    const totalRevenue = await Order.aggregate([
      { $match: { status: 'Delivered' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);

    const ordersByStatus = await Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    const recentOrders = await Order.find().sort({ createdAt: -1 }).limit(10);

    res.json({
      totalOrders,
      totalProducts,
      totalCustomers,
      totalRevenue: totalRevenue[0]?.total || 0,
      ordersByStatus,
      recentOrders
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/admin/customers', async (req, res) => {
  try {
    const customers = await User.find({ role: 'customer' }).select('-password');
    res.json(customers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ==================== LOCATION ROUTES ====================

app.put('/api/users/location', async (req, res) => {
  try {
    const { email, lat, lng, address } = req.body;
    await User.findOneAndUpdate({ email }, { location: { lat, lng, address } });
    res.json({ message: 'Location updated successfully' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// ==================== START SERVER ====================

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 API available at http://localhost:${PORT}/api`);
});