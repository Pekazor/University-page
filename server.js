require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const authRoutes = require('./src/routes/auth.routes');
const usuarioRoutes = require('./src/routes/usuario.routes');

const app = express();

// Middlewares
app.use(express.json());
app.use(helmet());

// Rutas
app.use('/auth', authRoutes);
app.use('/usuarios', usuarioRoutes);

// Manejo de errores
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ 
        error: 'Algo salió mal', 
        mensaje: err.message 
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor corriendo en puerto ${PORT}`);
});