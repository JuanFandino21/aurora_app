const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const mysql = require("mysql2/promise");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json({ limit: "2mb" }));

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

function cleanText(value, maxLength = 255) {
  return String(value || "").trim().slice(0, maxLength);
}

function cleanNullableText(value, maxLength = 255) {
  const clean = String(value || "").trim().slice(0, maxLength);
  return clean.length > 0 ? clean : null;
}

function cleanEmail(value) {
  return String(value || "").trim().toLowerCase();
}

function isValidId(value) {
  const id = Number(value);
  return Number.isInteger(id) && id > 0;
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(
    String(email || "").trim().toLowerCase()
  );
}

function isValidGmail(email) {
  const clean = cleanEmail(email);
  return isValidEmail(clean) && clean.endsWith("@gmail.com");
}

function isValidName(name) {
  const cleanName = String(name || "").trim();
  return cleanName.length >= 2 && cleanName.length <= 120;
}

function isValidPassword(password) {
  const cleanPassword = String(password || "").trim();
  return cleanPassword.length >= 6 && cleanPassword.length <= 60;
}

function isValidIdentification(identification) {
  if (!identification) return true;
  const cleanIdentification = String(identification || "").trim();
  return /^[0-9A-Za-z.-]{5,30}$/.test(cleanIdentification);
}

function isValidPhone(phone) {
  if (!phone) return true;
  const cleanPhone = String(phone || "").trim();
  return /^[0-9+\-\s()]{7,40}$/.test(cleanPhone);
}

function cleanPaymentMethod(value) {
  const method = String(value || "Pago contra entrega").trim();

  const allowed = [
    "Pago contra entrega",
    "Contra entrega",
    "Efectivo",
    "Tarjeta",
    "Transferencia",
    "Nequi",
    "Daviplata",
    "No especificado",
  ];

  if (!allowed.includes(method)) {
    return "Pago contra entrega";
  }

  if (method === "Efectivo" || method === "Contra entrega") {
    return "Pago contra entrega";
  }

  return method;
}

function cleanTone(value) {
  const tone = String(value || "").trim();

  if (!tone) return "";

  const isHex = /^#?[A-Fa-f0-9]{6,8}$/.test(tone);
  const isArgbInt = /^[0-9]{6,12}$/.test(tone);

  if (isHex || isArgbInt) return tone.slice(0, 50);

  return "";
}

function cleanProductType(value) {
  const type = String(value || "").trim().toLowerCase();

  const allowed = [
    "labial",
    "rubor",
    "base",
    "pestañina",
    "cosmetica",
    "cuidado",
    "",
  ];

  if (allowed.includes(type)) return type;

  return "";
}

async function ensureColumn(tableName, columnName, definition) {
  const [rows] = await pool.query(
    `
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = ?
      AND COLUMN_NAME = ?
    LIMIT 1
    `,
    [tableName, columnName]
  );

  if (rows.length === 0) {
    await pool.query(
      `ALTER TABLE \`${tableName}\` ADD COLUMN \`${columnName}\` ${definition}`
    );
  }
}

async function normalizeEmptyValues(tableName, columnName) {
  await pool.query(
    `
    UPDATE \`${tableName}\`
    SET \`${columnName}\` = NULL
    WHERE \`${columnName}\` = ''
    `
  );
}

async function ensureUniqueIndex(tableName, indexName, columnName) {
  const [indexes] = await pool.query(
    `
    SELECT INDEX_NAME
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = ?
      AND INDEX_NAME = ?
    LIMIT 1
    `,
    [tableName, indexName]
  );

  if (indexes.length > 0) return;

  const [duplicates] = await pool.query(
    `
    SELECT \`${columnName}\`, COUNT(*) AS total
    FROM \`${tableName}\`
    WHERE \`${columnName}\` IS NOT NULL
      AND \`${columnName}\` <> ''
    GROUP BY \`${columnName}\`
    HAVING COUNT(*) > 1
    LIMIT 1
    `
  );

  if (duplicates.length > 0) {
    console.log(
      `No se creó índice único ${indexName} porque existen duplicados en ${columnName}`
    );
    return;
  }

  await pool.query(
    `ALTER TABLE \`${tableName}\` ADD UNIQUE KEY \`${indexName}\` (\`${columnName}\`)`
  );
}

async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS \`user\` (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      identification VARCHAR(30) UNIQUE,
      email VARCHAR(150) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      googleId VARCHAR(255),
      phone VARCHAR(40) UNIQUE,
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
      payment_method VARCHAR(80) DEFAULT 'Pago contra entrega',
      delivery_address TEXT,
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
      selected_tone VARCHAR(50),
      product_type VARCHAR(80),
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

  await ensureColumn("user", "identification", "VARCHAR(30)");
  await ensureColumn("user", "phone", "VARCHAR(40)");
  await ensureColumn("product", "stock", "INT DEFAULT 20");
  await ensureColumn("product", "active", "TINYINT(1) DEFAULT 1");
  await ensureColumn("orders", "delivery_address", "TEXT");
  await ensureColumn("order_items", "selected_tone", "VARCHAR(50)");
  await ensureColumn("order_items", "product_type", "VARCHAR(80)");

  await normalizeEmptyValues("user", "identification");
  await normalizeEmptyValues("user", "phone");

  await ensureUniqueIndex("user", "uq_user_identification", "identification");
  await ensureUniqueIndex("user", "uq_user_phone", "phone");

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

app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");

    return res.json({
      ok: true,
      api: "online",
      database: "online",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return res.status(500).json({
      ok: false,
      api: "online",
      database: "offline",
      error: error.message,
    });
  }
});

app.post("/auth/register", async (req, res) => {
  try {
    const cleanName = cleanText(req.body.name, 120);
    const email = cleanEmail(req.body.email);
    const password = String(req.body.password || "").trim();
    const identification = cleanNullableText(req.body.identification, 30);
    const phone = cleanNullableText(req.body.phone, 40);

    if (!cleanName || !email || !password) {
      return res.status(400).json({
        ok: false,
        message: "Nombre, correo y contraseña son obligatorios",
      });
    }

    if (!isValidName(cleanName)) {
      return res.status(400).json({
        ok: false,
        message: "El nombre debe tener entre 2 y 120 caracteres",
      });
    }

    if (!isValidGmail(email)) {
      return res.status(400).json({
        ok: false,
        message: "El correo debe ser válido y terminar en @gmail.com",
      });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        ok: false,
        message: "La contraseña debe tener entre 6 y 60 caracteres",
      });
    }

    if (identification && !isValidIdentification(identification)) {
      return res.status(400).json({
        ok: false,
        message: "La identificación debe tener entre 5 y 30 caracteres",
      });
    }

    if (phone && !isValidPhone(phone)) {
      return res.status(400).json({
        ok: false,
        message: "Ingresa un teléfono válido",
      });
    }

    const [existingEmail] = await pool.query(
      "SELECT id FROM `user` WHERE email = ? LIMIT 1",
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(409).json({
        ok: false,
        message: "Este correo ya está registrado",
      });
    }

    if (identification) {
      const [existingIdentification] = await pool.query(
        "SELECT id FROM `user` WHERE identification = ? LIMIT 1",
        [identification]
      );

      if (existingIdentification.length > 0) {
        return res.status(409).json({
          ok: false,
          message: "Esta identificación ya está registrada",
        });
      }
    }

    if (phone) {
      const [existingPhone] = await pool.query(
        "SELECT id FROM `user` WHERE phone = ? LIMIT 1",
        [phone]
      );

      if (existingPhone.length > 0) {
        return res.status(409).json({
          ok: false,
          message: "Este teléfono ya está registrado",
        });
      }
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const [result] = await pool.query(
      `
      INSERT INTO \`user\`
      (name, identification, email, password, phone, googleId, createdAt)
      VALUES (?, ?, ?, ?, ?, NULL, NOW())
      `,
      [cleanName, identification, email, passwordHash, phone]
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
        identification: identification || "",
        email,
        phone: phone || "",
      },
    });
  } catch (error) {
    console.error("REGISTER ERROR:", error);

    if (error.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        ok: false,
        message: "El correo, identificación o teléfono ya está registrado",
      });
    }

    return res.status(500).json({
      ok: false,
      message: "Error interno registrando usuario",
      error: error.message,
    });
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const email = cleanEmail(req.body.email);
    const password = String(req.body.password || "").trim();

    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        message: "Correo y contraseña son obligatorios",
      });
    }

    if (!isValidGmail(email)) {
      return res.status(400).json({
        ok: false,
        message: "El correo debe ser válido y terminar en @gmail.com",
      });
    }

    if (!isValidPassword(password)) {
      return res.status(400).json({
        ok: false,
        message: "La contraseña debe tener entre 6 y 60 caracteres",
      });
    }

    const [rows] = await pool.query(
      `
      SELECT
        id,
        name,
        identification,
        email,
        password,
        phone,
        googleId,
        createdAt
      FROM \`user\`
      WHERE email = ?
      LIMIT 1
      `,
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        ok: false,
        message: "Credenciales incorrectas",
      });
    }

    const dbUser = rows[0];

    const validPassword = await bcrypt.compare(password, dbUser.password);

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
        identification: dbUser.identification || "",
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

app.get("/auth/profile/:id", async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!isValidId(userId)) {
      return res.status(400).json({
        ok: false,
        message: "Usuario inválido",
      });
    }

    const [rows] = await pool.query(
      `
      SELECT
        id,
        name,
        identification,
        email,
        phone,
        googleId,
        createdAt
      FROM \`user\`
      WHERE id = ?
      LIMIT 1
      `,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        ok: false,
        message: "Usuario no encontrado",
      });
    }

    const dbUser = rows[0];

    return res.json({
      ok: true,
      user: {
        id: dbUser.id,
        name: dbUser.name,
        identification: dbUser.identification || "",
        email: dbUser.email,
        phone: dbUser.phone || "",
        googleId: dbUser.googleId || "",
      },
    });
  } catch (error) {
    console.error("GET PROFILE ERROR:", error);

    return res.status(500).json({
      ok: false,
      message: "Error consultando perfil",
      error: error.message,
    });
  }
});

app.put("/auth/profile/:id", async (req, res) => {
  try {
    const userId = Number(req.params.id);

    if (!isValidId(userId)) {
      return res.status(400).json({
        ok: false,
        message: "Usuario inválido",
      });
    }

    const [existingRows] = await pool.query(
      `
      SELECT
        id,
        name,
        identification,
        email,
        phone
      FROM \`user\`
      WHERE id = ?
      LIMIT 1
      `,
      [userId]
    );

    if (existingRows.length === 0) {
      return res.status(404).json({
        ok: false,
        message: "Usuario no encontrado",
      });
    }

    const currentUser = existingRows[0];

    const hasName = Object.prototype.hasOwnProperty.call(req.body, "name");
    const hasIdentification = Object.prototype.hasOwnProperty.call(
      req.body,
      "identification"
    );
    const hasPhone = Object.prototype.hasOwnProperty.call(req.body, "phone");

    const nameToSave = hasName
      ? cleanText(req.body.name, 120)
      : currentUser.name;

    const identificationToSave = hasIdentification
      ? cleanNullableText(req.body.identification, 30)
      : currentUser.identification || null;

    const phoneToSave = hasPhone
      ? cleanNullableText(req.body.phone, 40)
      : currentUser.phone || null;

    if (!isValidName(nameToSave)) {
      return res.status(400).json({
        ok: false,
        message: "El nombre debe tener entre 2 y 120 caracteres",
      });
    }

    if (identificationToSave && !isValidIdentification(identificationToSave)) {
      return res.status(400).json({
        ok: false,
        message: "La identificación debe tener entre 5 y 30 caracteres",
      });
    }

    if (phoneToSave && !isValidPhone(phoneToSave)) {
      return res.status(400).json({
        ok: false,
        message: "Ingresa un teléfono válido",
      });
    }

    if (identificationToSave) {
      const [sameIdentification] = await pool.query(
        "SELECT id FROM `user` WHERE identification = ? AND id <> ? LIMIT 1",
        [identificationToSave, userId]
      );

      if (sameIdentification.length > 0) {
        return res.status(409).json({
          ok: false,
          message: "Esta identificación ya está registrada",
        });
      }
    }

    if (phoneToSave) {
      const [samePhone] = await pool.query(
        "SELECT id FROM `user` WHERE phone = ? AND id <> ? LIMIT 1",
        [phoneToSave, userId]
      );

      if (samePhone.length > 0) {
        return res.status(409).json({
          ok: false,
          message: "Este teléfono ya está registrado",
        });
      }
    }

    await pool.query(
      `
      UPDATE \`user\`
      SET name = ?, identification = ?, phone = ?
      WHERE id = ?
      `,
      [nameToSave, identificationToSave, phoneToSave, userId]
    );

    return res.json({
      ok: true,
      message: "Perfil actualizado correctamente",
      user: {
        id: userId,
        name: nameToSave,
        identification: identificationToSave || "",
        email: currentUser.email,
        phone: phoneToSave || "",
      },
    });
  } catch (error) {
    console.error("UPDATE PROFILE ERROR:", error);

    if (error.code === "ER_DUP_ENTRY") {
      return res.status(409).json({
        ok: false,
        message: "La identificación o el teléfono ya están registrados",
      });
    }

    return res.status(500).json({
      ok: false,
      message: "Error actualizando perfil",
      error: error.message,
    });
  }
});

app.post("/auth/logout", async (req, res) => {
  try {
    const userId = req.body.userId;

    if (isValidId(userId)) {
      await pool.query(
        "INSERT INTO login_history (user_id, action, device, createdAt) VALUES (?, ?, ?, NOW())",
        [Number(userId), "LOGOUT", "Flutter App"]
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
    const category = cleanText(req.query.category, 80).toLowerCase();
    const search = cleanText(req.query.search, 120);

    let sql =
      "SELECT id, name, description, price, imageUrl, brand, category, stock, active, createdAt FROM product WHERE active = 1";
    const params = [];

    if (category) {
      sql += " AND LOWER(category) = ?";
      params.push(category);
    }

    if (search) {
      sql += " AND (name LIKE ? OR description LIKE ? OR brand LIKE ?)";
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
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
    const userId = Number(req.body.userId);
    const paymentMethod = cleanPaymentMethod(req.body.paymentMethod);
    const deliveryAddress = cleanText(
      req.body.deliveryAddress || req.body.address,
      255
    );
    const items = req.body.items;

    if (!isValidId(userId)) {
      return res.status(400).json({
        ok: false,
        message: "Usuario inválido",
      });
    }

    if (deliveryAddress.length < 8) {
      return res.status(400).json({
        ok: false,
        message: "Ingresa una dirección de entrega válida",
      });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        ok: false,
        message: "El carrito está vacío",
      });
    }

    if (items.length > 30) {
      return res.status(400).json({
        ok: false,
        message: "La compra supera el máximo de productos permitidos",
      });
    }

    const [userRows] = await pool.query(
      "SELECT id FROM `user` WHERE id = ? LIMIT 1",
      [userId]
    );

    if (userRows.length === 0) {
      return res.status(404).json({
        ok: false,
        message: "Usuario no encontrado",
      });
    }

    await connection.beginTransaction();

    let total = 0;
    const normalizedItems = [];

    for (const item of items) {
      const productId = Number(item.id);
      const quantity = Number(item.quantity || 1);
      const selectedTone = cleanTone(
        item.selectedTone || item.tone || item.selected_tone
      );
      const productType = cleanProductType(
        item.productType || item.product_type
      );

      if (!isValidId(productId)) {
        throw new Error("Producto inválido en el carrito");
      }

      if (!Number.isInteger(quantity) || quantity <= 0 || quantity > 20) {
        throw new Error("Cantidad inválida en el carrito");
      }

      const [productRows] = await connection.query(
        "SELECT id, name, price, imageUrl, stock, active, category FROM product WHERE id = ? LIMIT 1 FOR UPDATE",
        [productId]
      );

      if (productRows.length === 0) {
        throw new Error("Producto no encontrado");
      }

      const product = productRows[0];

      if (Number(product.active) !== 1) {
        throw new Error(`El producto ${product.name} no está disponible`);
      }

      if (Number(product.stock) < quantity) {
        throw new Error(`Stock insuficiente para ${product.name}`);
      }

      const unitPrice = Number(product.price);
      const subtotal = unitPrice * quantity;
      total += subtotal;

      normalizedItems.push({
        productId: product.id,
        productName: product.name,
        quantity,
        unitPrice,
        subtotal,
        imageUrl: product.imageUrl || "",
        selectedTone,
        productType: productType || product.category || "",
      });
    }

    if (total <= 0) {
      throw new Error("Total inválido");
    }

    const [orderResult] = await connection.query(
      `
      INSERT INTO orders
      (user_id, total, payment_method, delivery_address, status, createdAt)
      VALUES (?, ?, ?, ?, 'CONFIRMED', NOW())
      `,
      [userId, total, paymentMethod, deliveryAddress]
    );

    const orderId = orderResult.insertId;

    for (const item of normalizedItems) {
      await connection.query(
        `
        INSERT INTO order_items
        (order_id, product_id, product_name, quantity, unit_price, subtotal, imageUrl, selected_tone, product_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `,
        [
          orderId,
          item.productId,
          item.productName,
          item.quantity,
          item.unitPrice,
          item.subtotal,
          item.imageUrl,
          item.selectedTone,
          item.productType,
        ]
      );

      await connection.query(
        "UPDATE product SET stock = stock - ? WHERE id = ?",
        [item.quantity, item.productId]
      );
    }

    await connection.commit();

    return res.status(201).json({
      ok: true,
      message:
        "Compra registrada correctamente. Tu pedido tardará de 1 a 4 días en llegar.",
      orderId,
      total,
      paymentMethod,
      deliveryAddress,
      estimatedDelivery: "1 a 4 días",
    });
  } catch (error) {
    await connection.rollback();

    console.error("ORDER ERROR:", error);

    return res.status(400).json({
      ok: false,
      message: error.message || "Error registrando compra",
    });
  } finally {
    connection.release();
  }
});

app.get("/orders/user/:userId", async (req, res) => {
  try {
    const userId = Number(req.params.userId);

    if (!isValidId(userId)) {
      return res.status(400).json({
        ok: false,
        message: "Usuario inválido",
      });
    }

    const [ordersAsc] = await pool.query(
      `
      SELECT
        id,
        user_id,
        total,
        payment_method,
        delivery_address,
        status,
        createdAt
      FROM orders
      WHERE user_id = ?
      ORDER BY createdAt ASC, id ASC
      `,
      [userId]
    );

    if (ordersAsc.length === 0) {
      return res.json({
        ok: true,
        orders: [],
      });
    }

    const orderIds = ordersAsc.map((order) => order.id);
    const placeholders = orderIds.map(() => "?").join(",");

    const [items] = await pool.query(
      `
      SELECT
        id,
        order_id,
        product_id,
        product_name,
        quantity,
        unit_price,
        subtotal,
        imageUrl,
        selected_tone,
        product_type
      FROM order_items
      WHERE order_id IN (${placeholders})
      ORDER BY id ASC
      `,
      orderIds
    );

    const itemsByOrder = {};

    for (const item of items) {
      if (!itemsByOrder[item.order_id]) {
        itemsByOrder[item.order_id] = [];
      }

      itemsByOrder[item.order_id].push(item);
    }

    const orders = ordersAsc
      .map((order, index) => ({
        ...order,
        user_order_number: index + 1,
        items: itemsByOrder[order.id] || [],
      }))
      .reverse();

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
    const orderId = Number(req.params.orderId);

    if (!isValidId(orderId)) {
      return res.status(400).json({
        ok: false,
        message: "Compra inválida",
      });
    }

    const [orders] = await pool.query(
      `
      SELECT
        id,
        user_id,
        total,
        payment_method,
        delivery_address,
        status,
        createdAt
      FROM orders
      WHERE id = ?
      LIMIT 1
      `,
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({
        ok: false,
        message: "Compra no encontrada",
      });
    }

    const order = orders[0];

    const [numberRows] = await pool.query(
      `
      SELECT COUNT(*) AS user_order_number
      FROM orders
      WHERE user_id = ?
        AND (
          createdAt < ?
          OR (createdAt = ? AND id <= ?)
        )
      `,
      [order.user_id, order.createdAt, order.createdAt, order.id]
    );

    const [items] = await pool.query(
      `
      SELECT
        id,
        order_id,
        product_id,
        product_name,
        quantity,
        unit_price,
        subtotal,
        imageUrl,
        selected_tone,
        product_type
      FROM order_items
      WHERE order_id = ?
      ORDER BY id ASC
      `,
      [orderId]
    );

    return res.json({
      ok: true,
      order: {
        ...order,
        user_order_number: Number(numberRows[0].user_order_number || 1),
      },
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