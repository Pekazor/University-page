// Generar token JWT
const token = jwt.sign(
    { 
        id: usuario.id_usuario, 
        tipo: usuario.tipo_usuario 
    },
    process.env.JWT_SECRET || 'tu_secreto_temporal', 
    { expiresIn: '2h' }
);