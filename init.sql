-- Crear tabla de eventos
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
  KEY `idx_completado` (`completado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Datos de ejemplo
INSERT INTO `eventos` (`titulo`, `descripcion`, `fecha_hora`, `prioridad`, `completado`) VALUES
('Reunión de equipo', 'Revisión del sprint semanal', CONCAT(CURDATE(), ' 09:00:00'), 'importante', 0),
('Llamada con cliente', 'Presentación de propuesta', CONCAT(CURDATE(), ' 11:30:00'), 'urgente', 0),
('Almuerzo con socio', 'Discutir nuevo proyecto', CONCAT(CURDATE(), ' 13:00:00'), 'normal', 0),
('Gimnasio', 'Rutina de cardio', CONCAT(CURDATE(), ' 18:00:00'), 'leve', 0),
('Revisión de código', 'Pull request', DATE_ADD(CONCAT(CURDATE(), ' 10:00:00'), INTERVAL 1 DAY), 'importante', 0),
('Dentista', 'Limpieza dental', DATE_ADD(CONCAT(CURDATE(), ' 15:00:00'), INTERVAL 1 DAY), 'normal', 0);