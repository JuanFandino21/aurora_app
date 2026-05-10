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

async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS \`user\` (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      email VARCHAR(150) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      googleId VARCHAR(255),
      phone VARCHAR(40),
      createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS product (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(150) NOT NULL,
      description TEXT,
      price DECIMAL(10,2) NOT NULL,
      imageUrl TEXT,
      brand VARCHAR(120),
      category VARCHAR(80) NOT NULL,
      stock INT DEFAULT 20,
      active TINYINT(1) DEFAULT 1,
      createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      total DECIMAL(10,2) NOT NULL,
      payment_method VARCHAR(80) DEFAULT 'No especificado',
      status VARCHAR(50) DEFAULT 'CONFIRMED',
      createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES \`user\`(id)
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS order_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      order_id INT NOT NULL,
      product_id INT NOT NULL,
      product_name VARCHAR(150) NOT NULL,
      quantity INT NOT NULL,
      unit_price DECIMAL(10,2) NOT NULL,
      subtotal DECIMAL(10,2) NOT NULL,
      imageUrl TEXT,
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (product_id) REFERENCES product(id)
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS login_history (
      id INT AUTO_INCREMENT PRIMARY KEY,
      user_id INT NOT NULL,
      action VARCHAR(50) NOT NULL,
      device VARCHAR(150),
      createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES \`user\`(id)
    )
  `);

  const [products] = await pool.query("SELECT COUNT(*) AS total FROM product");

  if (products[0].total === 0) {
    await pool.query(`
      INSERT INTO product 
      (name, description, price, imageUrl, brand, category, stock, active)
      VALUES
      ('Labial Matte Pro', 'Labial de alta duración con pigmentación intensa.', 40000, 'https://images.unsplash.com/photo-1586495777744-4413f21062fa', 'Aurora Beauty', 'cosmetica', 30, 1),

      ('Rubor Glow', 'Rubor compacto con acabado natural y luminoso.', 50000, 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9', 'Aurora Beauty', 'cosmetica', 25, 1),

      ('Base Líquida Natural', 'Base ligera para unificar el tono de la piel.', 65000, 'https://images.unsplash.com/photo-1596462502278-27bfdc403348', 'Aurora Beauty', 'cosmetica', 20, 1),

      ('Pestañina Volumen', 'Máscara de pestañas para volumen y definición.', 38000, 'https://images.unsplash.com/photo-1631214524049-0ebbbe6d81aa', 'Aurora Beauty', 'cosmetica', 35, 1),

      ('Crema Hidratante Facial', 'Crema diaria para hidratación y suavidad de la piel.', 35000, 'https://images.unsplash.com/photo-1556228578-8c89e6adf883', 'Aurora Care', 'cuidado', 40, 1),

      ('Protector Solar SPF 50', 'Protección solar diaria para piel sensible.', 45000, 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be', 'Aurora Care', 'cuidado', 30, 1),

      ('Limpiador Facial', 'Gel limpiador suave para uso diario.', 32000, 'https://images.unsplash.com/photo-1556228720-195a672e8a03', 'Aurora Care', 'cuidado', 30, 1),

      ('Sérum Vitamina C', 'Sérum antioxidante para luminosidad facial.', 58000, 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b', 'Aurora Care', 'cuidado', 18, 1)
    `);
  }

  console.log("Base de datos inicializada correctamente");
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
      const quantity = Number(item.quantity || 1);
      const price = Number(item.price || 0);

      total += price * quantity;
    }

    const [orderResult] = await connection.query(
      "INSERT INTO orders (user_id, total, payment_method, status, createdAt) VALUES (?, ?, ?, 'CONFIRMED', NOW())",
      [userId, total, paymentMethod || "No especificado"]
    );

    const orderId = orderResult.insertId;

    for (const item of items) {
      const productId = Number(item.id);
      const quantity = Number(item.quantity || 1);
      const price = Number(item.price || 0);
      const subtotal = price * quantity;

      await connection.query(
        "INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, subtotal, imageUrl) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          orderId,
          productId,
          item.name,
          quantity,
          price,
          subtotal,
          item.imageUrl || "",
        ]
      );

      await connection.query(
        "UPDATE product SET stock = GREATEST(stock - ?, 0) WHERE id = ?",
        [quantity, productId]
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

initializeDatabase()
  .then(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`Aurora API corriendo en puerto ${port}`);
    });
  })
  .catch((error) => {
    console.error("Error inicializando base de datos:", error);
    process.exit(1);
  });