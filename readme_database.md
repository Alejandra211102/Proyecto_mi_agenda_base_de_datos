# 🗄️ Base de Datos - Agenda Personal

Configuración y despliegue de la base de datos MySQL en AWS RDS para el sistema de agenda personal.

## 📋 Descripción

Base de datos MySQL 8.0 optimizada para almacenar eventos, con soporte completo de caracteres UTF-8, índices optimizados y configuración para alta disponibilidad en AWS RDS.

## 🏗️ Esquema de la Base de Datos

### Tabla: `eventos`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INT | ID único autoincremental (PK) |
| `titulo` | VARCHAR(255) | Título del evento (requerido) |
| `descripcion` | TEXT | Descripción detallada (opcional) |
| `fecha_hora` | DATETIME | Fecha y hora del evento (requerido) |
| `prioridad` | ENUM | Nivel: 'urgente', 'importante', 'normal', 'leve' |
| `completado` | BOOLEAN | Estado de completado (default: FALSE) |
| `notificado` | BOOLEAN | Si ya fue notificado (default: FALSE) |
| `created_at` | TIMESTAMP | Fecha de creación (automático) |
| `updated_at` | TIMESTAMP | Última actualización (automático) |

### Índices

```sql
PRIMARY KEY (id)
INDEX idx_fecha_hora (fecha_hora)
INDEX idx_prioridad (prioridad)
INDEX idx_completado (completado)
INDEX idx_fecha_completado (fecha_hora, completado)
```

## 🚀 Despliegue en AWS RDS

### Paso 1: Crear Instancia RDS

#### 1.1 Acceder a RDS en AWS Console

1. Ingresa a [AWS Console](https://console.aws.amazon.com)
2. Busca **RDS** en el buscador
3. Clic en **"Crear base de datos"**

#### 1.2 Configuración del Motor

- **Método de creación:** Creación estándar
- **Motor:** MySQL
- **Versión:** MySQL 8.0.35 o superior
- **Plantilla:** Capa gratuita (Free Tier)

#### 1.3 Configuración de la Instancia

**Identificador de la instancia:**
```
agenda-db
```

**Credenciales:**
- **Usuario maestro:** `admin`
- **Contraseña maestra:** `[Crear una contraseña segura]`
- ⚠️ **IMPORTANTE:** Guarda estas credenciales en un lugar seguro

**Clase de instancia:**
- **Tipo:** db.t3.micro (Free Tier)
- **vCPU:** 2
- **RAM:** 1 GB

**Almacenamiento:**
- **Tipo:** SSD de uso general (gp2)
- **Tamaño:** 20 GB
- ✅ **Habilitar escalado automático:** Límite 100 GB

#### 1.4 Configuración de Conectividad

**VPC:** (Dejar por defecto o crear una nueva)

**Acceso público:**
- ✅ **Sí** (para permitir conexión desde EC2 e Internet)

**Grupo de seguridad VPC:**
- Crear nuevo: `agenda-db-sg`
- O usar uno existente

**Puerto de base de datos:**
- **Puerto:** 3306 (por defecto)

**Autenticación:**
- Autenticación con contraseña

#### 1.5 Configuración Adicional

**Nombre de base de datos inicial:**
```
agenda_db
```

**Grupo de parámetros:** `default.mysql8.0`

**Backup:**
- ✅ **Habilitar copias de seguridad automáticas**
- **Período de retención:** 7 días
- **Ventana de backup:** Sin preferencia

**Cifrado:**
- ✅ **Habilitar cifrado**

**Monitoreo:**
- ✅ **Habilitar monitoreo mejorado**

#### 1.6 Crear Base de Datos

- Clic en **"Crear base de datos"**
- **Tiempo de creación:** 5-10 minutos
- Estado inicial: **"Creando"** → **"Disponible"**

---

### Paso 2: Configurar Grupo de Seguridad

Una vez creada la base de datos:

#### 2.1 Acceder al Grupo de Seguridad

1. Ve a **RDS** → **Bases de datos** → `agenda-db`
2. En la sección **"Conectividad y seguridad"**
3. Clic en el **Grupo de seguridad** (ejemplo: `agenda-db-sg`)

#### 2.2 Agregar Reglas de Entrada

Clic en **"Editar reglas de entrada"** → **"Agregar regla"**

**Regla 1: Permitir desde Backend EC2**
- **Tipo:** MySQL/Aurora
- **Puerto:** 3306
- **Origen:** Grupo de seguridad del EC2 Backend
  - Buscar: `sg-xxxxx (agenda-backend-sg)`

**Regla 2: Permitir desde tu IP (para desarrollo)**
- **Tipo:** MySQL/Aurora
- **Puerto:** 3306
- **Origen:** Mi IP
  - AWS detectará automáticamente tu IP

⚠️ **Nota de Seguridad:** En producción, eliminar la Regla 2 para mayor seguridad.

Clic en **"Guardar reglas"**

---

### Paso 3: Obtener Endpoint de Conexión

1. Ve a **RDS** → **Bases de datos** → `agenda-db`
2. En **"Conectividad y seguridad"**
3. Copia el **"Punto de enlace"** (Endpoint)

Ejemplo:
```
agenda-db.c9xxxxxxxxxxxx.us-east-1.rds.amazonaws.com
```

**Este endpoint lo necesitarás para configurar el backend.**

---

### Paso 4: Inicializar el Esquema de la Base de Datos

#### 4.1 Conectarse desde tu computadora local

Necesitas un cliente MySQL. Opciones:

**Opción A: MySQL Workbench (GUI)**
1. Descarga: https://dev.mysql.com/downloads/workbench/
2. Nueva conexión:
   - **Hostname:** `agenda-db.xxxxx.rds.amazonaws.com`
   - **Port:** 3306
   - **Username:** admin
   - **Password:** [tu contraseña]

**Opción B: MySQL CLI**

```bash
mysql -h agenda-db.xxxxx.rds.amazonaws.com -P 3306 -u admin -p
# Ingresa la contraseña cuando se solicite
```

#### 4.2 Ejecutar Script de Inicialización

Una vez conectado, ejecuta el script `init.sql`:

```sql
-- Usar la base de datos
USE agenda_db;

-- Crear tabla eventos
CREATE TABLE IF NOT EXISTS `eventos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` varchar(255) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `fecha_hora` datetime NOT NULL,
  `prioridad` enum('urgente','importante','normal','leve') DEFAULT 'normal',
  `completado` tinyint(1) DEFAULT 0,
  `notificado` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_fecha_hora` (`fecha_hora`),
  KEY `idx_prioridad` (`prioridad`),
  KEY `idx_completado` (`completado`),
  KEY `idx_fecha_completado` (`fecha_hora`,`completado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo
INSERT INTO `eventos` (`titulo`, `descripcion`, `fecha_hora`, `prioridad`, `completado`) VALUES
('Reunión de equipo', 'Revisión del sprint semanal', CONCAT(CURDATE(), ' 09:00:00'), 'importante', 0),
('Llamada con cliente', 'Presentación de propuesta', CONCAT(CURDATE(), ' 11:30:00'), 'urgente', 0),
('Almuerzo con socio', 'Discutir nuevo proyecto', CONCAT(CURDATE(), ' 13:00:00'), 'normal', 0),
('Gimnasio', 'Rutina de cardio', CONCAT(CURDATE(), ' 18:00:00'), 'leve', 0);

-- Verificar datos
SELECT * FROM eventos;
```

#### 4.3 Verificar Configuración UTF-8

```sql
-- Verificar charset de la base de datos
SHOW CREATE DATABASE agenda_db;

-- Verificar charset de la tabla
SHOW CREATE TABLE eventos;

-- Verificar variables de sistema
SHOW VARIABLES LIKE 'character%';
SHOW VARIABLES LIKE 'collation%';
```

Todos deben mostrar **utf8mb4**.

---

### Paso 5: Configurar Parámetros de RDS (Opcional pero Recomendado)

#### 5.1 Crear Grupo de Parámetros Personalizado

1. Ve a **RDS** → **Grupos de parámetros**
2. Clic en **"Crear grupo de parámetros"**
3. Configuración:
   - **Familia:** mysql8.0
   - **Nombre:** `agenda-db-params`
   - **Descripción:** Parámetros optimizados para agenda

#### 5.2 Modificar Parámetros

Editar los siguientes parámetros:

```
character_set_server = utf8mb4
collation_server = utf8mb4_unicode_ci
max_connections = 100
wait_timeout = 28800
interactive_timeout = 28800
```

#### 5.3 Aplicar Grupo de Parámetros

1. Ve a **RDS** → **Bases de datos** → `agenda-db`
2. Clic en **"Modificar"**
3. **Grupo de parámetros DB:** `agenda-db-params`
4. **Aplicar inmediatamente:** ✅ Sí
5. Clic en **"Continuar"** → **"Modificar instancia de BD"**
6. La base de datos se reiniciará automáticamente

---

## 🔐 Seguridad

### Mejores Prácticas

#### 1. Contraseñas Fuertes

```
✅ Mínimo 16 caracteres
✅ Mayúsculas y minúsculas
✅ Números y símbolos
✅ No usar palabras del diccionario
```

Ejemplo: `Ag3nd@P3rs0n4l!2025#Secur3`

#### 2. Acceso Restringido

```sql
-- Crear usuario solo para la aplicación (más seguro que usar admin)
CREATE USER 'agenda_app'@'%' IDENTIFIED BY 'password_seguro';
GRANT SELECT, INSERT, UPDATE, DELETE ON agenda_db.* TO 'agenda_app'@'%';
FLUSH PRIVILEGES;
```

#### 3. Habilitar SSL/TLS

En RDS, SSL está habilitado por defecto. Configurar en el backend:

```javascript
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 3306,
  ssl: {
    rejectUnauthorized: true
  }
};
```

#### 4. Backup y Recovery

**Backups Automáticos:**
- Habilitados por defecto en RDS
- Retención: 7-35 días
- Snapshots automáticos diarios

**Crear Snapshot Manual:**
1. Ve a **RDS** → **Bases de datos** → `agenda-db`
2. Acciones → **"Tomar instantánea"**
3. Nombre: `agenda-db-snapshot-2025-11-23`

**Restaurar desde Snapshot:**
1. Ve a **RDS** → **Instantáneas**
2. Selecciona el snapshot
3. Acciones → **"Restaurar instantánea"**

---

## 📊 Monitoreo

### CloudWatch Metrics

Métricas importantes a monitorear:

```
✅ CPUUtilization - Uso de CPU
✅ DatabaseConnections - Conexiones activas
✅ FreeableMemory - Memoria disponible
✅ FreeStorageSpace - Espacio en disco
✅ ReadLatency / WriteLatency - Latencia de I/O
```

### Configurar Alarmas

1. Ve a **CloudWatch** → **Alarmas**
2. **"Crear alarma"**

**Ejemplo: Alarma de CPU Alta**
- **Métrica:** RDS > agenda-db > CPUUtilization
- **Condición:** Mayor que 80%
- **Período:** 5 minutos
- **Acción:** Enviar email a tu correo

### Logs de Consultas Lentas

```sql
-- Habilitar log de consultas lentas
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2; -- Segundos

-- Ver consultas lentas en CloudWatch Logs
```

---

## 🧪 Testing

### Test de Conexión

```bash
# Desde tu computadora
mysql -h agenda-db.xxxxx.rds.amazonaws.com -P 3306 -u admin -p -e "SELECT 1;"

# Desde EC2 Backend
docker exec -it agenda-backend sh
mysql -h agenda-db.xxxxx.rds.amazonaws.com -P 3306 -u admin -p -e "SELECT 1;"
```

### Test de Rendimiento

```sql
-- Ver número de conexiones
SHOW STATUS LIKE 'Threads_connected';

-- Ver consultas por segundo
SHOW GLOBAL STATUS LIKE 'Questions';

-- Ver uptime
SHOW GLOBAL STATUS LIKE 'Uptime';

-- Ver tamaño de las tablas
SELECT 
  table_name,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)"
FROM information_schema.TABLES 
WHERE table_schema = 'agenda_db';
```

---

## 🔄 Mantenimiento

### Optimización de Tablas

```sql
-- Analizar tabla
ANALYZE TABLE eventos;

-- Optimizar tabla
OPTIMIZE TABLE eventos;

-- Reparar tabla (si hay corrupción)
REPAIR TABLE eventos;
```

### Limpieza de Datos Antiguos

```sql
-- Eliminar eventos completados de hace más de 6 meses
DELETE FROM eventos 
WHERE completado = TRUE 
  AND fecha_hora < DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- Ver espacio liberado
OPTIMIZE TABLE eventos;
```

### Actualización de RDS

1. Ve a **RDS** → **Bases de datos** → `agenda-db`
2. Clic en **"Modificar"**
3. **Versión del motor:** Seleccionar nueva versión
4. **Ventana de mantenimiento:** Preferida o inmediata
5. Aplicar cambios

---

## 🐛 Troubleshooting

### Error: "Can't connect to MySQL server"

**Causa:** Grupo de seguridad bloqueando conexión

**Solución:**
```bash
# 1. Verificar que el grupo de seguridad permite el puerto 3306
# 2. Verificar que el endpoint es correcto
# 3. Verificar que la base de datos está "Disponible"
```

### Error: "Access denied for user"

**Causa:** Credenciales incorrectas

**Solución:**
```bash
# Verificar usuario y contraseña
# Reiniciar contraseña desde AWS Console si es necesario
```

### Error: "Too many connections"

**Causa:** Límite de conexiones alcanzado

**Solución:**
```sql
-- Ver conexiones actuales
SHOW PROCESSLIST;

-- Aumentar max_connections en el grupo de parámetros
-- Valor recomendado: 100-200
```

### Base de datos lenta

**Diagnóstico:**
```sql
-- Consultas lentas
SELECT * FROM mysql.slow_log ORDER BY query_time DESC LIMIT 10;

-- Índices no utilizados
SELECT * FROM sys.schema_unused_indexes;

-- Tablas sin índices
SELECT * FROM sys.schema_tables_with_full_table_scans;
```

---

## 💰 Costos

### Free Tier (12 meses)

```
✅ 750 horas/mes de db.t3.micro
✅ 20 GB de almacenamiento SSD
✅ 20 GB de backups
✅ GRATIS durante 12 meses
```

### Post Free Tier

```
💵 db.t3.micro: ~$15/mes
💵 Almacenamiento: ~$0.10/GB/mes
💵 I/O: ~$0.10 por millón de requests
💵 Backups: ~$0.095/GB/mes
```

**Estimado mensual:** $15-20/mes

---

## 📚 Recursos Adicionales

- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Monitoring RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html)

---

## 📝 Checklist de Configuración

```
✅ Instancia RDS creada y disponible
✅ Grupo de seguridad configurado
✅ Endpoint obtenido y guardado
✅ Conexión exitosa desde local
✅ Esquema de base de datos creado
✅ Datos de ejemplo insertados
✅ UTF-8 configurado correctamente
✅ Backups automáticos habilitados
✅ Monitoreo configurado
✅ Credenciales guardadas de forma segura
```

---

**⚠️ IMPORTANTE:** Guarda el endpoint, usuario y contraseña en un lugar seguro. Los necesitarás para configurar el backend.