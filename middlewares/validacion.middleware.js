// Middleware para validar y sanitizar inputs
const validateInput = (req, res, next) => {
    const sensitiveFields = ['email', 'password', 'documento_identidad'];
    
    sensitiveFields.forEach(field => {
        if (req.body[field]) {
            req.body[field] = sanitizeInput(req.body[field]);
        }
    });

    next();
};
