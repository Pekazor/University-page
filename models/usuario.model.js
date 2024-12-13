const db = require('../config/database');
const bcrypt = require('bcryptjs');

class UsuarioModel {
    async crearUsuario(email, contraseña, tipoUsuario) {
        try {
            // Hash de contraseña
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(contraseña, salt);

            const query = `
                INSERT INTO usuarios 
                (email, contraseña, tipo_usuario, activo) 
                VALUES ($1, $2, $3, TRUE) 
                RETURNING id_usuario
            `;

            const values = [email, hashedPassword, tipoUsuario];
            const result = await db.query(query, values);

            return result.rows[0];
        } catch (error) {
            throw error;
        }
    }

    async encontrarPorEmail(email) {
        const query = `
            SELECT * FROM usuarios 
            WHERE email = $1 AND activo = TRUE
        `;

        const result = await db.query(query, [email]);
        return result.rows[0];
    }
}

module.exports = new UsuarioModel();