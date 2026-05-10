const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const mysql = require("mysql2/promise");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "aurora_db",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

function createToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
    },
    process.env.JWT_SECRET || "aurora_secret_2026",
    {
      expiresIn: "7d",
    }
  );
}

app.get("/", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    return res.json({
      ok: true,
      message: "Aurora API funcionando correctamente",
      database: "Conectada",
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: "No hay conexión con MySQL",
      error: error.message,
    });
  }
});

app.post("/auth/register", async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        ok: false,
        message: "Nombre, email y contraseña son obligatorios",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        ok: false,
        message: "La contraseña debe tener mínimo 6 caracteres",
      });
    }

    const cleanName = String(name).trim();
    const cleanEmail = String(email).trim().toLowerCase();
    const cleanPassword = String(password).trim();
    const cleanPhone = phone ? String(phone).trim() : null;

    const [existingUser] = await pool.query(
      "SELECT id FROM `user` WHERE email = ? LIMIT 1",
      [cleanEmail]
    );

    if (existingUser.length > 0) {
      return res.status(409).json({
        ok: false,
        message: "Este correo ya está registrado",
      });
    }

    const passwordHash = await bcrypt.hash(cleanPassword, 10);

    const [result] = await pool.query(
      "INSERT INTO `user` (name, email, password, phone, googleId, createdAt) VALUES (?, ?, ?, ?, NULL, NOW())",
      [cleanName, cleanEmail, passwordHash, cleanPhone]
    );

    await pool.query(
      "INSERT INTO login_history (user_id, action, device, createdAt) VALUES (?, ?, ?, NOW())",
      [result.insertId, "REGISTER", "Flutter App"]
    );

    return res.status(201).json({
      ok: true,
      message: "Usuario registrado correctamente",
      user: {
        id: result.insertId,
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone || "",
      },
    });
  } catch (error) {
    console.error("REGISTER ERROR:", error);
    return res.status(500).json({
      ok: false,
      message: "Error interno registrando usuario",
      error: error.message,
    });
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        message: "Email y contraseña son obligatorios",
      });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    const cleanPassword = String(password).trim();

    const [rows] = await pool.query(
      "SELECT id, name, email, password, phone, googleId, createdAt FROM `user` WHERE email = ? LIMIT 1",
      [cleanEmail]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        ok: false,
        message: "Credenciales incorrectas",
      });
    }

    const dbUser = rows[0];

    const validPassword = await bcrypt.compare(cleanPassword, dbUser.password);

    if (!validPassword) {
      return res.status(401).json({
        ok: false,
        message: "Credenciales incorrectas",
      });
    }

    await pool.query(
      "INSERT INTO login_history (user_id, action, device, createdAt) VALUES (?, ?, ?, NOW())",
      [dbUser.id, "LOGIN", "Flutter App"]
    );

    const token = createToken(dbUser);

    return res.json({
      ok: true,
      message: "Login correcto",
      token,
      user: {
        id: dbUser.id,
        name: dbUser.name,
        email: dbUser.email,
        phone: dbUser.phone || "",
        googleId: dbUser.googleId || "",
      },
    });
  } catch (error) {
    console.error("LOGIN ERROR:", error);
    return res.status(500).json({
      ok: false,
      message: "Error interno iniciando sesión",
      error: error.message,
    });
  }
});

app.post("/auth/logout", async (req, res) => {
  try {
    const { userId } = req.body;

    if (userId) {
      await pool.query(
        "INSERT INTO login_history (user_id, action, device, createdAt) VALUES (?, ?, ?, NOW())",
        [userId, "LOGOUT", "Flutter App"]
      );
    }

    return res.json({
      ok: true,
      message: "Sesión cerrada",
    });
  } catch (error) {
    return res.json({
      ok: true,
      message: "Sesión cerrada",
    });
  }
});

app.get("/products", async (req, res) => {
  try {
    const { category, search } = req.query;

    let sql =
      "SELECT id, name, description, price, imageUrl, brand, category, stock, active, createdAt FROM product WHERE active = 1";
    const params = [];

    if (category) {
      sql += " AND category = ?";
      params.push(String(category));
    }

    if (search) {
      sql += " AND name LIKE ?";
      params.push(`%${String(search)}%`);
    }

    sql += " ORDER BY id ASC";

    const [rows] = await pool.query(sql, params);

    return res.json({
      ok: true,
      products: rows,
    });
  } catch (error) {
    console.error("PRODUCTS ERROR:", error);
    return res.status(500).json({
      ok: false,
      message: "Error consultando productos",
      error: error.message,
    });
  }
});

app.post("/orders", async (req, res) => {
  const connection = await pool.getConnection();

  try {
    const { userId, paymentMethod, items } = req.body;

    if (!userId || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        ok: false,
        message: "Datos de compra incompletos",
      });
    }

    await connection.beginTransaction();

    let total = 0;

    for (const item of items) {
      total += Number(item.price) * Number(item.quantity);
    }

    const [orderResult] = await connection.query(
      "INSERT INTO orders (user_id, total, payment_method, status, createdAt) VALUES (?, ?, ?, 'CONFIRMED', NOW())",
      [userId, total, paymentMethod || "No especificado"]
    );

    const orderId = orderResult.insertId;

    for (const item of items) {
      const subtotal = Number(item.price) * Number(item.quantity);

      await connection.query(
        "INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, imageUrl) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          orderId,
          item.id,
          item.name,
          item.quantity,
          item.price,
          subtotal,
          item.imageUrl || "",
        ]
      );

      await connection.query(
        "UPDATE product SET stock = GREATEST(stock - ?, 0) WHERE id = ?",
        [item.quantity, item.id]
      );
    }

    await connection.commit();

    return res.status(201).json({
      ok: true,
      message: "Compra registrada correctamente",
      orderId,
      total,
    });
  } catch (error) {
    await connection.rollback();
    console.error("ORDER ERROR:", error);

    return res.status(500).json({
      ok: false,
      message: "Error registrando compra",
      error: error.message,
    });
  } finally {
    connection.release();
  }
});

app.get("/orders/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const [orders] = await pool.query(
      "SELECT id, user_id, total, payment_method, status, createdAt FROM orders WHERE user_id = ? ORDER BY id DESC",
      [userId]
    );

    return res.json({
      ok: true,
      orders,
    });
  } catch (error) {
    console.error("USER ORDERS ERROR:", error);
    return res.status(500).json({
      ok: false,
      message: "Error consultando historial de compras",
      error: error.message,
    });
  }
});

app.get("/orders/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;

    const [orders] = await pool.query(
      "SELECT id, user_id, total, payment_method, status, createdAt FROM orders WHERE id = ? LIMIT 1",
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        ok: false,
        message: "Compra no encontrada",
      });
    }

    const [items] = await pool.query(
      "SELECT id, order_id, product_id, product_name, quantity, unit_price, subtotal, imageUrl FROM order_items WHERE order_id = ?",
      [orderId]
    );

    return res.json({
      ok: true,
      order: orders[0],
      items,
    });
  } catch (error) {
    console.error("ORDER DETAIL ERROR:", error);
    return res.status(500).json({
      ok: false,
      message: "Error consultando detalle de compra",
      error: error.message,
    });
  }
});

const port = process.env.PORT || 3000;

app.listen(port, "0.0.0.0", () => {
  console.log(`Aurora API corriendo en puerto ${port}`);
});