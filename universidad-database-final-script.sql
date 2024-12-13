-- Crear base de datos
CREATE DATABASE universidad_db;

-- Conectarse a la base de datos
\c universidad_db;

-- Extensiones de seguridad
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Tabla de Usuarios
CREATE TABLE usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(100) UNIQUE NOT NULL,
    contraseña VARCHAR(255) NOT NULL,
    tipo_usuario VARCHAR(20) NOT NULL 
        CHECK (tipo_usuario IN ('alumno', 'profesor', 'admin', 'centro_estudiantil')),
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ultimo_inicio_sesion TIMESTAMP WITH TIME ZONE,
    intentos_fallidos INTEGER DEFAULT 0,
    bloqueado_hasta TIMESTAMP WITH TIME ZONE
);

-- Índices para optimización
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_tipo ON usuarios(tipo_usuario);

-- Tabla de Carreras
CREATE TABLE carreras (
    id_carrera SERIAL PRIMARY KEY,
    codigo_carrera VARCHAR(10) UNIQUE NOT NULL,
    nombre_carrera VARCHAR(100) NOT NULL,
    descripcion TEXT,
    duracion_semestres INT CHECK (duracion_semestres > 0),
    requisitos_ingreso TEXT,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    area_conocimiento VARCHAR(100),
    modalidad VARCHAR(50) CHECK (modalidad IN ('presencial', 'virtual', 'mixta'))
);

-- Tabla de Alumnos
CREATE TABLE alumnos (
    id_alumno UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_usuario UUID REFERENCES usuarios(id_usuario),
    id_carrera INT REFERENCES carreras(id_carrera),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE,
    documento_identidad VARCHAR(20) UNIQUE NOT NULL,
    direccion TEXT,
    telefono VARCHAR(20),
    email_institucional VARCHAR(100) UNIQUE,
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(20) CHECK (estado IN ('activo', 'graduado', 'suspendido', 'egresado')),
    promedio_general DECIMAL(4,2) DEFAULT 0
);

-- Tabla de Profesores
CREATE TABLE profesores (
    id_profesor UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_usuario UUID REFERENCES usuarios(id_usuario),
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    especialidad VARCHAR(100),
    fecha_contratacion DATE,
    email_institucional VARCHAR(100) UNIQUE,
    departamento VARCHAR(100),
    grado_academico VARCHAR(50),
    tipo_contrato VARCHAR(50) CHECK (tipo_contrato IN ('tiempo_completo', 'medio_tiempo', 'por_horas'))
);

-- Tabla de Materias/Cursos
CREATE TABLE materias (
    id_materia SERIAL PRIMARY KEY,
    id_carrera INT REFERENCES carreras(id_carrera),
    codigo_materia VARCHAR(10) UNIQUE NOT NULL,
    nombre_materia VARCHAR(100) NOT NULL,
    semestre INT CHECK (semestre > 0),
    creditos INT CHECK (creditos > 0),
    descripcion TEXT,
    prerequisitos INT[] DEFAULT ARRAY[]::INT[],
    area_conocimiento VARCHAR(100),
    tipo_materia VARCHAR(50) CHECK (tipo_materia IN ('obligatoria', 'electiva', 'optativa'))
);

-- Tabla de Notas/Calificaciones
CREATE TABLE notas (
    id_nota SERIAL PRIMARY KEY,
    id_alumno UUID REFERENCES alumnos(id_alumno),
    id_materia INT REFERENCES materias(id_materia),
    id_profesor UUID REFERENCES profesores(id_profesor),
    nota_parcial1 DECIMAL(4,2) CHECK (nota_parcial1 BETWEEN 0 AND 10),
    nota_parcial2 DECIMAL(4,2) CHECK (nota_parcial2 BETWEEN 0 AND 10),
    nota_final DECIMAL(4,2) CHECK (nota_final BETWEEN 0 AND 10),
    semestre VARCHAR(10),
    año INT,
    estado_nota VARCHAR(20) 
        CHECK (estado_nota IN ('cursando', 'aprobado', 'reprobado')),
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    UNIQUE(id_alumno, id_materia, semestre, año)
);

-- Tabla de Noticias
CREATE TABLE noticias (
    id_noticia SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    contenido TEXT NOT NULL,
    fecha_publicacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    autor VARCHAR(100),
    categoria VARCHAR(50),
    activa BOOLEAN DEFAULT TRUE,
    imagen_url TEXT,
    ultima_modificacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Auditoria
CREATE TABLE auditoria_accesos (
    id_auditoria SERIAL PRIMARY KEY,
    usuario VARCHAR(100),
    accion TEXT,
    tabla_afectada VARCHAR(100),
    detalles JSONB,
    fecha_hora TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45)
);

-- Índices adicionales para rendimiento
CREATE INDEX idx_notas_alumno ON notas(id_alumno);
CREATE INDEX idx_notas_materia ON notas(id_materia);
CREATE INDEX idx_noticias_categoria ON noticias(categoria);
CREATE INDEX idx_auditoria_usuario ON auditoria_accesos(usuario);
CREATE INDEX idx_auditoria_fecha ON auditoria_accesos(fecha_hora);

-- Función de encriptación
CREATE OR REPLACE FUNCTION encrypt_data(data TEXT, key TEXT)
RETURNS bytea AS $$
BEGIN
    RETURN encrypt(data::bytea, key::bytea, 'aes-cbc/pad:pkcs');
END;
$$ LANGUAGE plpgsql;

-- Función de desencriptación
CREATE OR REPLACE FUNCTION decrypt_data(encrypted_data bytea, key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN decrypt(encrypted_data, key::bytea, 'aes-cbc/pad:pkcs')::text;
END;
$$ LANGUAGE plpgsql;

-- Crear roles
CREATE ROLE admin_universidad;
CREATE ROLE profesor_role;
CREATE ROLE alumno_role;
CREATE ROLE centro_estudiantil;

-- Permisos para cada rol
GRANT SELECT, INSERT, UPDATE, DELETE ON usuarios TO admin_universidad;
GRANT SELECT, UPDATE ON notas TO profesor_role;
GRANT SELECT ON materias, carreras TO alumno_role;
GRANT SELECT ON noticias, carreras TO centro_estudiantil;

-- Comentarios para documentación
COMMENT ON TABLE usuarios IS 'Almacena información de usuarios del sistema';
COMMENT ON TABLE carreras IS 'Información de carreras ofrecidas por la universidad';
COMMENT ON TABLE alumnos IS 'Registro de estudiantes matriculados';
COMMENT ON TABLE profesores IS 'Información de profesores';
COMMENT ON TABLE materias IS 'Catálogo de materias por carrera';
COMMENT ON TABLE notas IS 'Registro de calificaciones de estudiantes';
COMMENT ON TABLE noticias IS 'Publicaciones y avisos de la universidad';
