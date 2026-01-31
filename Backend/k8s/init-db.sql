-- ============================================================================
-- MODELO FINAL DE BASE DE DATOS: PRODUCCIÓN
-- PostgreSQL 14+
-- CUMPLIMIENTO: Mi criterio,ITIL, COBIT
-- NOMENCLATURA: nId{Tabla}, cId{Tabla}, nContador, cCodigo, bFlag, tTimestamp
-- ============================================================================
-- Hecho por ADYX
-- ============================================================================


-- Configuración de Entorno
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE S01AUDIT_LOG (
    nIdAudit BIGSERIAL PRIMARY KEY,
    
    -- Quién y desde dónde
    nIdUserAccount INTEGER, -- ID del usuario que hizo el cambio
    cIpAddress INET,
    cUserAgent TEXT,
    
    -- Qué tabla y qué fila
    cTableName VARCHAR(100) NOT NULL,
    cOperation VARCHAR(10) NOT NULL CHECK (cOperation IN ('INSERT', 'UPDATE', 'DELETE')),
    nRecordId BIGINT NOT NULL, -- El ID de la fila afectada
    
    -- El corazón de ITIL: Antes y Después
    jOldData JSONB, -- NULL en INSERT
    jNewData JSONB, -- NULL en DELETE
    
    -- Contexto adicional
    cSeverity VARCHAR(20) DEFAULT 'INFO', -- INFO, WARNING, CRITICAL
    tCreatedAt TIMESTAMP DEFAULT NOW()
);


CREATE TABLE S01ENTITY_TYPE (
    nIdEntityType SERIAL PRIMARY KEY,
    cName VARCHAR(30) NOT NULL, 
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

CREATE TABLE S01ADDRESS_TYPE (
    nIdAddressType SERIAL PRIMARY KEY,
    cName VARCHAR(30) NOT NULL, 
    tCreatedAt TIMESTAMP DEFAULT NOW()
);


CREATE TABLE S01IDENTIFICATION_TYPE (
    nIdIdentificationType SERIAL PRIMARY KEY,
    
    -- Código ISO 3166-1 alpha-2 (PE, CL, CO, etc.)
    cCountryIso CHAR(2) DEFAULT 'PE' NOT NULL, 
    
    -- El código de la entidad tributaria (SUNAT en Perú)
    cCode VARCHAR(5) NOT NULL,  
    
    cName VARCHAR(50) NOT NULL,
    nMinLength INTEGER NOT NULL DEFAULT 1,
    nMaxLength INTEGER NOT NULL,
    bIsNumeric BOOLEAN DEFAULT TRUE,
    cRegex VARCHAR(100), -- Patrón de validación
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    
    -- La combinación PAÍS + CÓDIGO es lo que no se debe repetir
    CONSTRAINT uq_country_code UNIQUE(cCountryIso, cCode),
    -- El nombre también debe ser único por país
    CONSTRAINT uq_country_document_name UNIQUE(cCountryIso, cName)
);


CREATE TABLE S01PHONE_TYPE (
    nIdPhoneType SERIAL PRIMARY KEY,
    cCode VARCHAR(20) NOT NULL UNIQUE,
    cName VARCHAR(50) NOT NULL UNIQUE,
    cDescription TEXT,
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);


CREATE TABLE S01ROLE (
    nIdRole SERIAL PRIMARY KEY,
    
    -- Nombre del rol (Ej: 'ADMIN', 'SCANNER_STAFF', 'SALES_AGENT')
    cName VARCHAR(50) NOT NULL UNIQUE, 
    
    cDescription TEXT,
    
    -- Si es TRUE, el sistema sabe que es un rol base y no permite borrarlo
    bIsSystemRole BOOLEAN DEFAULT FALSE,
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

-- Ejecutar después de S01ROLE
CREATE TABLE S01PERMISSION (
    nIdPermission SERIAL PRIMARY KEY,
    cCode VARCHAR(50) NOT NULL UNIQUE,  -- Tu identificador único
    cName VARCHAR(100) NOT NULL,
    cDescription TEXT,
    cModule VARCHAR(50),
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

CREATE TABLE S01ROLE_PERMISSION (
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole) ON DELETE CASCADE,
    nIdPermission INTEGER NOT NULL REFERENCES S01PERMISSION(nIdPermission) ON DELETE CASCADE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (nIdRole, nIdPermission)
);


CREATE TABLE S01PAYMENT_METHOD (
    nIdPaymentMethod SERIAL PRIMARY KEY,
    
    -- Tipo general (CASH, BANK, GATEWAY, E-WALLET)
    cType VARCHAR(50) NOT NULL, 
    
    -- Código estándar (Sugerido usar códigos SUNAT o ISO)
    cCode VARCHAR(20) NOT NULL UNIQUE, 
    
    cName VARCHAR(100) NOT NULL,
    
    -- Lógica de procesamiento
    bIsGateway BOOLEAN DEFAULT FALSE,
    cGatewayProvider VARCHAR(100), -- 'STRIPE', 'CULQI', 'NIUBIZ'
    
    -- Configuración dinámica (Credenciales, Endpoints, etc.)
    jConfig JSONB DEFAULT '{}'::JSONB, 
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

CREATE TABLE S01PERSON (
	nIdPerson BIGSERIAL PRIMARY KEY,
	cName VARCHAR(100) NOT NULL,
	cLastName VARCHAR(100) NOT NULL,
	nIdIdentificationType INTEGER NOT NULL REFERENCES S01IDENTIFICATION_TYPE(nIdIdentificationType),
	cIdentificationNumber VARCHAR(20) NOT NULL,
	cEmail VARCHAR(100) UNIQUE, -- El email suele ser único por persona en el sistema
	tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,
    
    -- Un solo registro por DNI/Pasaporte en todo el sistema
    CONSTRAINT uq_person_id UNIQUE(nIdIdentificationType, cIdentificationNumber)
);


CREATE TABLE S01USER_ACCOUNT (
    nIdUserAccount SERIAL PRIMARY KEY,
    cEmail VARCHAR(100) NOT NULL UNIQUE,
    cPasswordHash VARCHAR(255) NOT NULL,
    cNick VARCHAR(100),
    nIdPerson BIGINT NULL REFERENCES S01PERSON(nIdPerson), -- Conexión opcional
    
    -- Para recuperación de cuenta y seguridad
    bEmailVerified BOOLEAN DEFAULT FALSE,
    tLastLogin TIMESTAMP,
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);


CREATE TABLE S01COMPANY (
    nIdCompany SERIAL PRIMARY KEY,
    
    -- Identificación (Garantiza que no haya RUCs duplicados)
    nIdIdentificationType INTEGER NOT NULL REFERENCES S01IDENTIFICATION_TYPE(nIdIdentificationType),
    cIdentificationNumber VARCHAR(20) NOT NULL,
    
    cBusinessName VARCHAR(150) NOT NULL, -- Razón Social
    cTradeName VARCHAR(150),             -- Nombre Comercial
    cDescription TEXT,
    cLogoUrl VARCHAR(500),
    cEmail VARCHAR(100),
    
    -- SUNAT / Compliance
    bIsRucValidated BOOLEAN DEFAULT FALSE,
    tRucValidationDate TIMESTAMP,
    cRucValidationStatus VARCHAR(50),
    
    -- Metadata (JSONB para mejor rendimiento en filtros)
    jMetadata JSONB DEFAULT '{}'::JSONB,
    
    -- Control
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,

    -- Restricción de unicidad
    CONSTRAINT uq_company_identification UNIQUE(nIdIdentificationType, cIdentificationNumber)
);

CREATE TABLE S01SERIES_CONFIG (
    nIdSeries SERIAL PRIMARY KEY,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    cDocumentType VARCHAR(20) NOT NULL, -- 'TICKET', 'PAYMENT', 'CREDIT_NOTE', 'DEBIT_NOTE'
    cPrefix CHAR(4) NOT NULL,           -- Ej: 'T001', 'B001' (Boleta), 'F001' (Factura)
    nLastNumber INTEGER DEFAULT 0,
    
    UNIQUE(nIdCompany, cDocumentType, cPrefix)
);

CREATE TABLE S01CLIENT (
    nIdClient SERIAL PRIMARY KEY,
    
    -- Datos de Identidad (Inmutables)
    nIdPerson BIGINT NULL REFERENCES S01PERSON(nIdPerson), -- Conexión opcional
    
    -- Metadata GLOBAL (Preferencias del sistema)
    jMetadata JSONB DEFAULT '{}'::JSONB,
    
    -- Auditoría
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

ALTER TABLE S01CLIENT
ADD CONSTRAINT chk_metadata_valid CHECK (
    CASE WHEN jMetadata ? 'nCreditLimit' 
         THEN (jMetadata->>'nCreditLimit')::NUMERIC > 0 
         ELSE TRUE 
    END
);


-- Nota: cuando el emppleado inicie sesion, que le liste las empresas a las que esta trabajando, solo cuando esta iniciando sesion, evitar mostrar primero las empresas y luego que el user inicie sesion
CREATE TABLE S01VENUE (
    nIdVenue SERIAL PRIMARY KEY,
    -- Un local suele ser registrado por una empresa específica
    
    cName VARCHAR(100) NOT NULL, -- Ampliado por nombres largos
    cDescription TEXT,
    cLogoUrl VARCHAR(500),
    cEmail VARCHAR(100),
    
    -- Ubicación
    cAddress VARCHAR(200) NOT NULL,
    cCity VARCHAR(50) NOT NULL,
    cCountryIso CHAR(2) DEFAULT 'PE', -- Usando tu estándar ISO
    
    -- Geolocalización (VITAL para Google Maps en el ticket)
    nLatitude DECIMAL(10, 8),
    nLongitude DECIMAL(11, 8),
    
    -- Capacidad física máxima
    nMaxCapacity INTEGER NOT NULL CHECK (nMaxCapacity > 0),
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);--======================

CREATE TABLE S01EMPLOYEE (
    nIdEmployee SERIAL PRIMARY KEY,
 
    -- Identificación
	nIdPerson BIGINT NOT NULL REFERENCES S01PERSON(nIdPerson), -- Conexión obligatoria
    -- SUNAT validation (nunca NULL)
    cRuc VARCHAR(11),
	
	bIdentificationValidated BOOLEAN DEFAULT FALSE,
    tIdentificationValidationDate TIMESTAMP,
    cIdentificationValidationStatus VARCHAR(50),
    
          
    -- Control
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,
    nIdUserAccount INTEGER REFERENCES S01USER_ACCOUNT(nIdUserAccount)
);


CREATE TABLE S01EMPLOYEE_CONTEXT(
	nIdEmployeeContext BIGSERIAL PRIMARY KEY,
	nIdEmployee INTEGER NOT NULL REFERENCES S01EMPLOYEE(nIdEmployee) ON DELETE RESTRICT,
	nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
	bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);


CREATE TABLE S01EMPLOYEE_ROLE (
    nIdEmployeeContext BIGINT NOT NULL REFERENCES S01EMPLOYEE_CONTEXT(nIdEmployeeContext) ON DELETE CASCADE,
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole) ON DELETE CASCADE,
    tAssignedAt TIMESTAMP DEFAULT NOW(),
    
    -- La llave primaria compuesta evita que asignes el mismo rol dos veces al mismo empleado
    PRIMARY KEY (nIdEmployeeContext, nIdRole)
);

CREATE TABLE S01USER_COMPANY_ROLE (
    nIdUserCompanyRole SERIAL PRIMARY KEY,
    nIdUserAccount INTEGER NOT NULL REFERENCES S01USER_ACCOUNT(nIdUserAccount),
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole),
    
    tModifiedAt TIMESTAMP,
    bIsDefault BOOLEAN DEFAULT FALSE, -- Para saber qué empresa cargar por defecto al entrar
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(nIdUserAccount, nIdCompany) -- Un usuario no puede tener dos roles base en la misma empresa
);

CREATE TABLE S01CLIENT_COMPANY (
    nIdClientCompany SERIAL PRIMARY KEY,
    nIdClient INTEGER NOT NULL REFERENCES S01CLIENT(nIdClient),
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    
    -- Aquí guardas info específica de este cliente con ESTA empresa
    -- Ej: "Cliente VIP de la discoteca X", "Asistió a 3 eventos de la Empresa Y"
    jCompanySpecificMetadata JSONB DEFAULT '{}'::JSONB,
    
    tLastPurchaseAt TIMESTAMP,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(nIdClient, nIdCompany)
);

CREATE TABLE S01EVENT (
    nIdEvent SERIAL PRIMARY KEY,
    
    -- Identificación y Propiedad
    cName VARCHAR(150) NOT NULL,
    cDescription TEXT,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
    nIdEmployeeCreatedBy INTEGER REFERENCES S01EMPLOYEE_CONTEXT(nIdEmployeeContext) ON DELETE SET NULL,
    
    -- Ubicación y Visual
    nIdVenue INTEGER REFERENCES S01VENUE(nIdVenue) ON DELETE SET NULL,
    cFlyerUrl VARCHAR(500),
    
    -- Gestión de Inventario Global
    nMaxTicket INTEGER NOT NULL CHECK (nMaxTicket > 0),
    nSoldTickets INTEGER DEFAULT 0, -- PAID + PENDING acumulados
    
    
    nMaxStaffSlots INTEGER DEFAULT 5, -- Valor por defecto: 5 porteros
    
    -- Estado
    cStatus VARCHAR(50) NOT NULL DEFAULT 'DRAFT'
        CHECK (cStatus IN ('DRAFT', 'SCHEDULED', 'ONGOING', 'COMPLETED', 'DELAYED', 'CANCELLED', 'SOLDOUT')),
    
    -- Finanzas de Resumen (No calculadas por columna generada, sino por Jobs o Triggers)
    nTotalRevenue NUMERIC(14,2) DEFAULT 0.00, -- Dinero total recaudado
    
    -- Metadata (Artistas, Patrocinadores, Hashtags)
    jEventMetadata JSONB DEFAULT '{}'::JSONB,
    
    -- Tiempos (Importante: Apertura de puertas vs Inicio del show)
    tDoorOpen TIMESTAMP,       -- Cuándo pueden empezar a entrar (Porteros activados)
    tStartDate TIMESTAMP NOT NULL, -- Inicio del show
    tEndDate TIMESTAMP,            -- Fin estimado
    
    -- Auditoría
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

ALTER TABLE S01EVENT 
ADD CONSTRAINT chk_event_dates_logic 
CHECK (tEndDate IS NULL OR tEndDate > tStartDate);


CREATE TABLE S01TICKET_CATEGORY (
    nIdTicketCategory SERIAL PRIMARY KEY,
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent) ON DELETE CASCADE,
    cName VARCHAR(50) NOT NULL, -- Ej: 'PREVENTA SOCIOS', 'GENERAL'
    cDescription TEXT,
    nMaxCapacity INTEGER NOT NULL, -- Capacidad total de la zona
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

CREATE TABLE S01TICKET_PRICE (
    nIdPrice SERIAL PRIMARY KEY,
    nIdTicketCategory INTEGER NOT NULL REFERENCES S01TICKET_CATEGORY(nIdTicketCategory) ON DELETE CASCADE,
    
    -- Monto
    nFinalPrice DECIMAL(10,2) NOT NULL CHECK (nFinalPrice >= 0),
    
    -- Lógica de Packs (2x1, etc.)
    nMinQuantity INTEGER DEFAULT 1 CHECK (nMinQuantity >= 1), 
    
    -- Inventario de esta Fase de Precio
    nMaxTickets INTEGER DEFAULT NULL, 
    nSoldTickets INTEGER DEFAULT 0,
    
    -- Vigencia
    tValidFrom TIMESTAMP NOT NULL,
    tValidUntil TIMESTAMP,
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    
    -- Restricciones de integridad
    CONSTRAINT chk_sold_tickets CHECK (nMaxTickets IS NULL OR nSoldTickets <= nMaxTickets),
    CONSTRAINT chk_dates_logic CHECK (tValidUntil IS NULL OR tValidUntil > tValidFrom)
);

CREATE TABLE S01SYSTEM_CONFIG (
    nIdConfig SERIAL PRIMARY KEY,
    nIdCompany INTEGER REFERENCES S01COMPANY(nIdCompany),
    cParamKey VARCHAR(50) NOT NULL, 
    cParamValue VARCHAR(100) NOT NULL,
    cUnit VARCHAR(20) DEFAULT 'MINUTES' CHECK (cUnit IN ('MINUTES', 'HOURS', 'DAYS')),
    cDescription TEXT,
    
    UNIQUE(nIdCompany, cParamKey)
);

CREATE TABLE S01PAYMENT (
    nIdPayment BIGSERIAL PRIMARY KEY,
    
    -- Multitenancy y Origen (Crucial para reportes rápidos)
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent),
    
    -- Relaciones
    nIdPaymentMethod INTEGER NOT NULL REFERENCES S01PAYMENT_METHOD(nIdPaymentMethod),
    nIdClient INTEGER NOT NULL REFERENCES S01CLIENT(nIdClient),
    
    -- Quién procesó el pago (Solo si fue físico/presencial)
    nIdEmployeeReceivedBy INTEGER REFERENCES S01EMPLOYEE(nIdEmployee),
    
    -- Seguridad Financiera
    cIdempotencyKey VARCHAR(64) NOT NULL UNIQUE,
    cPaymentNumber VARCHAR(20) NOT NULL UNIQUE, -- Ej: 'PAY-2026-00001'
    
    -- Montos (Usamos NUMERIC para evitar errores de redondeo de punto flotante)
    nAmount NUMERIC(14,2) NOT NULL CHECK (nAmount > 0),
    cCurrency VARCHAR(3) DEFAULT 'PEN', -- ISO 4217 (PEN, USD)
    
    -- Estado
    cStatus VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CHECK (cStatus IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED', 'REFUNDED')),
    
    -- Metadata del Gateway (Tokens de transacción, IDs de Culqi/Stripe, Errores)
    jGatewayData JSONB DEFAULT '{}'::JSONB,
    
    -- Tiempos
    tProcessedAt TIMESTAMP,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);


CREATE TABLE S01STAFF_ACCESS_TOKEN (
    nIdAccessToken SERIAL PRIMARY KEY,
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent),
    nIdVenue INTEGER REFERENCES S01VENUE(nIdVenue) ON DELETE SET NULL,
    
    -- El token secreto que irá dentro del QR
    cToken VARCHAR(64) UNIQUE NOT NULL, 
    
    -- Quién autorizó este acceso (GodMode / Admin)
    nIdEmployeeAuthorizer INTEGER REFERENCES S01EMPLOYEE_CONTEXT(nIdEmployeeContext),
	nIdEmployeeContext INTEGER REFERENCES S01EMPLOYEE_CONTEXT(nIdEmployeeContext), -- Opcional si es genérico
	cDeviceIdentifier VARCHAR(100), -- Para amarrar el token a un celular físico
    -- Datos del portero (los ingresa al "canjear" el QR)
    cStaffName VARCHAR(100),
    cStaffDni VARCHAR(20),
    
    cBoundDeviceFingerprint VARCHAR(255), -- El ID único del celular del portero
    cBoundIp INET,                       -- IP de la primera conexión
    tBoundAt TIMESTAMP,                  -- Cuándo se ancló el dispositivo
    nMaxConcurrentSessions INTEGER DEFAULT 1, -- Por si un token es para un "team" (raro, pero útil)
    
    -- Control de tiempo (Vulnerabilidad mitigada)
    tExpiresAt TIMESTAMP NOT NULL,
    bIsUsed BOOLEAN DEFAULT FALSE, -- ¿Ya se logueó alguien con este QR?
    bIsActive BOOLEAN DEFAULT TRUE,
    
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

CREATE TABLE S01STAFF_SESSION (
    nIdStaffSession SERIAL PRIMARY KEY,
    nIdAccessToken INTEGER NOT NULL REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken),
    
    -- Información del dispositivo (para detectar si comparten la cuenta)

    cIPAddress INET,
    
    -- Tiempos de actividad
    tSessionStart TIMESTAMP DEFAULT NOW(),
    tSessionEnd TIMESTAMP, -- Se llena cuando el portero hace "Logout"
    
    
    cSessionToken UUID DEFAULT gen_random_uuid(), -- Token único para ese navegador
    tLastActivity TIMESTAMP DEFAULT NOW(),        -- Para el "Heartbeat"
    tExpiresAt TIMESTAMP NOT NULL,               -- Fecha de muerte automática
    
    cDeviceFingerprint VARCHAR(255) NOT NULL,
    bIsRevoked BOOLEAN DEFAULT FALSE, -- Para que el Admin pueda patear a un portero sospechoso
    
    -- Estadísticas de la sesión (Denormalizado para rapidez en el dashboard)
    nScanCount INTEGER DEFAULT 0,
    
    bIsActive BOOLEAN DEFAULT TRUE
);

CREATE TABLE S01TICKET (
    nIdTicket SERIAL PRIMARY KEY,
    cCode VARCHAR(25) UNIQUE NOT NULL, 
    uUuid UUID DEFAULT gen_random_uuid(), 
    
    cStatus VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CHECK (cStatus IN ('PENDING', 'PAID', 'USED', 'CANCELLED', 'WAITING')),
    
    cSecretPin VARCHAR(3),     
    nPurchasePrice NUMERIC(14,2),
    
    -- Auditoría de tiempos
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tExpiresAt TIMESTAMP, 
    tModifiedAt TIMESTAMP,
    tScannedAt TIMESTAMP, -- Corregido el nombre (snake_case)
    bIsActive BOOLEAN DEFAULT TRUE,
    
    -- Relaciones
    nIdClient INTEGER NOT NULL REFERENCES S01CLIENT(nIdClient),
    nIdTicketCategory INTEGER NOT NULL REFERENCES S01TICKET_CATEGORY(nIdTicketCategory),
    nIdPrice INTEGER NOT NULL REFERENCES S01TICKET_PRICE(nIdPrice), -- VITAL para el trigger
    nIdPayment INTEGER REFERENCES S01PAYMENT(nIdPayment),
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent), -- Denormalizamos para rapidez
    -- El ID de la sesión específica que hizo el UPDATE a 'USED'
    nIdStaffSession INTEGER REFERENCES S01STAFF_SESSION(nIdStaffSession),
    -- Denormalizamos un poco el ID del Access Token para reportes rápidos de "Tickets por Puerta"
    nIdStaffAccessToken INTEGER REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken),
    -- Guardamos el IP de ese escaneo específico por si hay reclamos de ubicación
    cScannedIp INET,
    -- Trazabilidad de escaneo (Lo que hablamos del portero)
    nIdAccessToken INTEGER REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken)
);



-- TABLA DE NOTAS DE CRÉDITO (Para devoluciones o descuentos posteriores)
CREATE TABLE S01CREDIT_NOTE (
    nIdCreditNote BIGSERIAL PRIMARY KEY,
    cCreditNoteNumber VARCHAR(20) NOT NULL UNIQUE, -- Formato SUNAT: F001-000001
    
    -- Referencia al pago original
    nIdPayment BIGINT NOT NULL REFERENCES S01PAYMENT(nIdPayment) ON DELETE RESTRICT,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
    nIdClient INTEGER NOT NULL REFERENCES S01CLIENT(nIdClient) ON DELETE RESTRICT,
    nIdEmployeeCreatedBy INTEGER REFERENCES S01EMPLOYEE(nIdEmployee),
    
    -- Motivo SUNAT (Catálogo 09)
    cReason VARCHAR(50) NOT NULL 
        CHECK (cReason IN ('ANNULMENT', 'DISCOUNT', 'ITEM_RETURN', 'ERROR_IN_AMOUNT', 'OTHER')),
    cDescription TEXT,
    
    nAmount NUMERIC(14,2) NOT NULL CHECK (nAmount > 0),
    
    cStatus VARCHAR(50) DEFAULT 'EMITTED' 
        CHECK (cStatus IN ('EMITTED', 'SENT_SUNAT', 'ACCEPTED', 'REJECTED')),
    
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

-- TABLA DE NOTAS DE DÉBITO (Para cobrar penalidades o montos omitidos)
CREATE TABLE S01DEBIT_NOTE (
    nIdDebitNote BIGSERIAL PRIMARY KEY,
    cDebitNoteNumber VARCHAR(20) NOT NULL UNIQUE,
    
    nIdPayment BIGINT NOT NULL REFERENCES S01PAYMENT(nIdPayment) ON DELETE RESTRICT,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
    nIdClient INTEGER NOT NULL REFERENCES S01CLIENT(nIdClient) ON DELETE RESTRICT,
    
    cReason VARCHAR(50) NOT NULL 
        CHECK (cReason IN ('INTEREST', 'PENALTY', 'ERROR_IN_AMOUNT', 'OTHER')),
    cDescription TEXT,
    
    nAmount NUMERIC(14,2) NOT NULL CHECK (nAmount > 0),
    
    cStatus VARCHAR(50) DEFAULT 'EMITTED',
    
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);

-- ============================================================================
-- Tabña DE TELÉFONOS NORMALIZADA, esto es para una relacion 'virtual' para polimorfismo
-- ============================================================================


CREATE TABLE S01PHONE (
    nIdPhone BIGSERIAL PRIMARY KEY,
    
    -- Relación (polimorfa: puede ser cliente, empleado o empresa)
    nIdEntityType INTEGER REFERENCES S01ENTITY_TYPE (nIdEntityType),
    nEntityId INTEGER NOT NULL,
    
    -- Tipo de teléfono
    nIdPhoneType INTEGER NOT NULL REFERENCES S01PHONE_TYPE(nIdPhoneType) ON DELETE RESTRICT,
    
    -- Número
    cCountryCode VARCHAR(3) DEFAULT '+51',      -- Perú por defecto
    cAreaCode VARCHAR(5),                        -- Código de área
    cPhoneNumber VARCHAR(20) NOT NULL,           -- Número (sin caracteres especiales)
    cPhoneFormatted VARCHAR(30),                 -- Número formateado para display
    
    -- Validación
    bIsVerified BOOLEAN DEFAULT FALSE,
    tVerificationDate TIMESTAMP,
    
    -- Preferencias
    bIsPrimary BOOLEAN DEFAULT FALSE,
    bReceiveSMS BOOLEAN DEFAULT TRUE,
    bReceiveWhatsapp BOOLEAN DEFAULT FALSE,
    
    -- Control
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,
    
    -- Constraints
    UNIQUE(nIdEntityType, nEntityId, cPhoneNumber)
    
);


-- 2. TABLA CENTRALIZADA DE DIRECCIONES
CREATE TABLE S01ADDRESS (
    nIdAddress BIGSERIAL PRIMARY KEY,
    
    -- Relación Polimórfica
    nIdEntityType INTEGER REFERENCES S01ENTITY_TYPE (nIdEntityType),
    nEntityId INTEGER NOT NULL,
    
    -- Clasificación
    nIdAddressType INTEGER REFERENCES S01ADDRESS_TYPE (nIdAddressType),
    
    -- Datos de la dirección
    cAddressLine1 VARCHAR(255) NOT NULL,
    cAddressLine2 VARCHAR(255),
    cDistrict VARCHAR(100),
    cCity VARCHAR(100) NOT NULL,
    cState VARCHAR(100), -- Departamento / Provincia
    cCountryIso CHAR(2) DEFAULT 'PE',
    
    -- Para el GPS del Ticket
    nLatitude DECIMAL(10, 8),
    nLongitude DECIMAL(11, 8),
    
    bIsPrimary BOOLEAN DEFAULT FALSE,
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);


CREATE TABLE S01AUDIT_LOG_HISTORY (
    nIdAudit BIGINT PRIMARY KEY,
    nIdUserAccount INTEGER,
    cIpAddress INET,
    cUserAgent TEXT,
    cTableName VARCHAR(100),
    cOperation VARCHAR(10),
    nRecordId BIGINT,
    jOldData JSONB,
    jNewData JSONB,
    cSeverity VARCHAR(20),
    tCreatedAt TIMESTAMP,
    tArchivedAt TIMESTAMP DEFAULT NOW() -- Fecha en que se movió al histórico
);

CREATE TABLE S01STAFF_HEARTBEAT (
    nIdHeartbeat BIGSERIAL PRIMARY KEY,
    nIdStaffSession INTEGER REFERENCES S01STAFF_SESSION(nIdStaffSession),
    
    -- Ubicación
    nLatitude NUMERIC(10, 8),
    nLongitude NUMERIC(11, 8),
    
    -- Metadatos de salud del dispositivo
    nBatteryLevel INTEGER, -- 0-100
    bIsOnline BOOLEAN DEFAULT TRUE,
    
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- INDEX
-- ============================================================================
-- ============================================================================
-- 1. IDENTIDAD Y PERSONAS (S01PERSON)
-- ============================================================================
-- Crucial: Búsqueda universal por DNI/Pasaporte (Reemplaza a idx_client_doc)
CREATE INDEX idx_person_identity ON S01PERSON(nIdIdentificationType, cIdentificationNumber);
CREATE INDEX idx_person_full_name ON S01PERSON(cLastName, cName);

-- ============================================================================
-- 2. ESTRUCTURA DE EMPLEADOS Y CONTEXTO (NUEVOS)
-- ============================================================================
-- Para login: Ver empresas de una persona
CREATE INDEX idx_employee_person_lookup ON S01EMPLOYEE(nIdPerson, bIsActive);

-- Para operación: Cargar RUC, multas y sueldo del contexto activo
CREATE INDEX idx_employee_context_main ON S01EMPLOYEE_CONTEXT(nIdEmployee, nIdCompany, bIsActive);

-- Para seguridad: Validar roles asignados al contexto
CREATE INDEX idx_employee_role_lookup ON S01EMPLOYEE_ROLE(nIdEmployeeContext, nIdRole);

-- ============================================================================
-- 3. CONTACTOS POLIMÓRFICOS (CORREGIDOS)
-- ============================================================================
CREATE INDEX idx_phone_entity ON S01PHONE(nIdEntityType, nEntityId);
CREATE INDEX idx_phone_number ON S01PHONE(cPhoneNumber);
CREATE INDEX idx_phone_primary ON S01PHONE(nIdEntityType, nEntityId, bIsPrimary) WHERE bIsActive = TRUE;

CREATE INDEX idx_address_entity ON S01ADDRESS(nIdEntityType, nEntityId);

-- ============================================================================
-- 4. EVENTOS Y TICKETS (LO QUE SE QUEDA Y SE MEJORA)
-- ============================================================================
-- Corregido: El creador ahora es el Contexto
CREATE INDEX idx_event_creator_context ON S01EVENT(nIdEmployeeCreatedBy);

-- Mejorado: Filtra también los terminados para mayor velocidad en app
CREATE INDEX idx_event_dates ON S01EVENT(tStartDate, cStatus) 
WHERE cStatus NOT IN ('CANCELLED', 'COMPLETED');

-- Se quedan (Tal cual los tenías, son correctos)
CREATE INDEX idx_ticket_category_event_active ON S01TICKET_CATEGORY(nIdEvent, bIsActive);
CREATE INDEX idx_ticket_price_lookup ON S01TICKET_PRICE (nIdTicketCategory, tValidFrom, tValidUntil) WHERE bIsActive = TRUE;

-- Auditoría de quién escaneó (Staff Session)
CREATE INDEX idx_ticket_audit_scan ON S01TICKET(nIdStaffSession) WHERE cStatus = 'USED';

-- Expiración de pagos pendientes
CREATE INDEX idx_ticket_expiration_lookup ON S01TICKET (tExpiresAt, cStatus) 
WHERE cStatus = 'PENDING' AND bIsActive = FALSE;

-- ============================================================================
-- 5. SEGURIDAD Y SESIONES (SE QUEDAN)
-- ============================================================================
CREATE INDEX idx_staff_session_lookup ON S01STAFF_SESSION(cSessionToken) WHERE bIsActive = TRUE;
CREATE INDEX idx_active_sessions ON S01STAFF_SESSION(bIsActive) WHERE bIsActive = TRUE;
CREATE INDEX idx_staff_heartbeat_latest ON S01STAFF_HEARTBEAT (nIdStaffSession, tCreatedAt DESC);

CREATE INDEX idx_access_token_lookup ON S01STAFF_ACCESS_TOKEN(cToken) WHERE bIsActive = TRUE;
CREATE INDEX idx_token_device_security ON S01STAFF_ACCESS_TOKEN(cToken, cBoundDeviceFingerprint);

-- ============================================================================
-- 6. AUDITORÍA ITIL (SE QUEDAN / DESC PARA MÁS RECIENTES)
-- ============================================================================
CREATE INDEX idx_audit_table_record ON S01AUDIT_LOG(cTableName, nRecordId, tCreatedAt DESC);
CREATE INDEX idx_audit_timestamp ON S01AUDIT_LOG(tCreatedAt DESC);
CREATE INDEX idx_audit_hist_table ON S01AUDIT_LOG_HISTORY(cTableName, nRecordId);
CREATE INDEX idx_audit_hist_date ON S01AUDIT_LOG_HISTORY(tCreatedAt DESC);

-- ============================================================================
-- 7. EMPRESAS Y LOCALES (SE QUEDAN)
-- ============================================================================
CREATE INDEX idx_company_ruc ON S01COMPANY(cIdentificationNumber);
CREATE INDEX idx_payment_report ON S01PAYMENT (nIdCompany, tCreatedAt, cStatus);


-- ============================================================================
-- INSERTS
-- ============================================================================

INSERT INTO S01IDENTIFICATION_TYPE 
(cCountryIso, cCode, cName, nMinLength, nMaxLength, bIsNumeric, cRegex) VALUES
('PE', '1', 'DNI', 8, 8, TRUE, '^[0-9]{8}$'),
('PE', '6', 'RUC', 11, 11, TRUE, '^(10|20|15|17)[0-9]{9}$'),
('PE', '7', 'PASAPORTE', 5, 20, FALSE, '^[a-zA-Z0-9]+$'),
('PE', '4', 'CARNET EXTRANJERIA', 9, 12, FALSE, NULL)
ON CONFLICT DO NOTHING;

INSERT INTO S01PHONE_TYPE (cCode, cName, cDescription, bIsActive) VALUES
('MOBILE', 'Teléfono Móvil', 'Celular personal o empresarial', TRUE),
('LANDLINE', 'Teléfono Fijo', 'Línea telefónica fija', TRUE),
('OFFICE', 'Teléfono Oficina', 'Extensión de oficina', TRUE),
('FAX', 'Fax', 'Línea de fax', TRUE)
ON CONFLICT (cCode) DO NOTHING;

-- Inserción de roles base
INSERT INTO S01ROLE (cName, cDescription, bIsSystemRole) VALUES
('GOD_MODE', 'Control total del sistema (SaaS Owner)', TRUE),
('ORG_ADMIN', 'Administrador de la empresa organizadora', TRUE),
('EVENT_STAFF', 'Personal de apoyo (Porteros/Scanners)', TRUE),
('SALES_STAFF', 'Personal de ventas de tickets', TRUE)
ON CONFLICT (cName) DO NOTHING;

-- Inserción corregida por cCode
INSERT INTO S01PAYMENT_METHOD (cType, cCode, cName, bIsGateway) VALUES
('CASH', '001', 'Efectivo', FALSE),
('TRANSFER', '002', 'Transferencia Bancaria', FALSE),
('GATEWAY', '003', 'Tarjeta de Crédito/Débito', TRUE),
('E-WALLET', '005', 'Yape', FALSE),
('E-WALLET', '006', 'Plin', FALSE)
ON CONFLICT (cCode) DO NOTHING;

INSERT INTO S01PERMISSION (cCode, cName, cDescription, cModule, bIsActive) VALUES
-- Eventos
('CREATE_EVENT', 'Crear Evento', 'Permite crear nuevos eventos', 'EVENTS', TRUE),
('VIEW_EVENT', 'Ver Evento', 'Permite ver detalles de eventos', 'EVENTS', TRUE),
('EDIT_EVENT', 'Editar Evento', 'Permite editar eventos en estado DRAFT', 'EVENTS', TRUE),
('PUBLISH_EVENT', 'Publicar Evento', 'Permite publicar eventos', 'EVENTS', TRUE),
('DELETE_EVENT', 'Eliminar Evento', 'Permite eliminar/anular eventos', 'EVENTS', TRUE),
('CREATE_ACCESSTMP', 'Crear AccessTmp', 'Permite crear accesos temporales staff', 'EVENTS', TRUE),
('MANAGE_VENUES', 'Gestionar Locales', 'Crear y editar sedes de eventos', 'EVENTS', TRUE),
-- Tickets
('CREATE_TICKET', 'Crear Ticket', 'Permite crear nuevos tickets de evento', 'TICKETS', TRUE),
('VIEW_TICKET', 'Ver Ticket', 'Permite ver detalles de tickets', 'TICKETS', TRUE),
('EDIT_TICKET', 'Editar Ticket', 'Permite editar tickets en estado PENDING', 'TICKETS', TRUE),
('ISSUE_TICKET', 'Emitir Ticket', 'Permite emitir tickets', 'TICKETS', TRUE),
('CANCEL_TICKET', 'Cancelar Ticket', 'Permite cancelar tickets', 'TICKETS', TRUE),
-- Clientes y Pagos
('CREATE_CLIENT', 'Crear Cliente', 'Permite crear nuevos clientes', 'CLIENTS', TRUE),
('VIEW_CLIENT', 'Ver Cliente', 'Permite ver detalles de clientes', 'CLIENTS', TRUE),
('CREATE_PAYMENT', 'Crear Pago', 'Permite registrar nuevos pagos', 'PAYMENTS', TRUE),
('REFUND_PAYMENT', 'Revertir Pago', 'Permite revertir pagos (REFUND)', 'PAYMENTS', TRUE),
-- Operaciones y Admin
('SCAN_TICKET', 'Escanear Ticket', 'Permiso para validar entrada en puerta', 'OPERATIONS', TRUE),
('VIEW_DASHBOARD', 'Ver Dashboard', 'Ver estadísticas generales', 'REPORTS', TRUE),
('MANAGE_USERS', 'Gestionar Usuarios', 'Administración de cuentas', 'ADMIN', TRUE),
('SYSTEM_CONFIG', 'Configuración del Sistema', 'Acceso a config global', 'ADMIN', TRUE)
ON CONFLICT (cCode) DO NOTHING;

SELECT * FROM S01PERMISSION;

-- 1. ASIGNAR TODO AL GOD_MODE (Dueño del SaaS)
INSERT INTO S01ROLE_PERMISSION (nIdRole, nIdPermission)
SELECT r.nIdRole, p.nIdPermission 
FROM S01ROLE r, S01PERMISSION p 
WHERE r.cName = 'GOD_MODE'
ON CONFLICT DO NOTHING;

-- 2. ASIGNAR PERMISOS AL STAFF DE PUERTA (Porteros)
-- Solo pueden ver eventos y escanear tickets
INSERT INTO S01ROLE_PERMISSION (nIdRole, nIdPermission)
SELECT r.nIdRole, p.nIdPermission 
FROM S01ROLE r, S01PERMISSION p 
WHERE r.cName = 'EVENT_STAFF' 
AND p.cCode IN ('VIEW_EVENT', 'SCAN_TICKET', 'VIEW_TICKET')
ON CONFLICT DO NOTHING;

-- 3. ASIGNAR PERMISOS AL ADMIN DE LA ORGANIZADORA
-- Puede hacer casi todo, excepto configuración del sistema global
INSERT INTO S01ROLE_PERMISSION (nIdRole, nIdPermission)
SELECT r.nIdRole, p.nIdPermission 
FROM S01ROLE r, S01PERMISSION p 
WHERE r.cName = 'ORG_ADMIN' 
AND p.cModule IN ('EVENTS', 'TICKETS', 'CLIENTS', 'PAYMENTS', 'REPORTS')
ON CONFLICT DO NOTHING;



-- =======================================================
-- Lo anterior ya son preparativos
-- Ingreso de un test de compañia
--  Ahora miremos el flujo completo del sisetma para saber como debería funcionar
-- =======================================================

/*
 * Preparación del Entorno (Auditoría)

Antes de cualquier INSERT, la base de datos debe saber quién opera. Como es el primer registro, simularemos que el ID '1' será el sistema/admin.
 * */

SET app.current_user_id = '1';

SELECT * FROM S01ROLE;

-- Primer Usuario (Tú)
-- La contraseña debería ser un hash (bcrypt/argon2), aquí pongo un ejemplo

INSERT INTO S01USER_ACCOUNT (cEmail, cPasswordHash, cName, cLastName, bEmailVerified) --Contraseña Elmomer@123_XD:3
VALUES ('andry.caceres@estudiante.ucsm.edu.pe', '$argon2id$v=19$m=19456,t=2,p=1$GMO3YUMOg1ur+DG0zMFoEA$q3cpRFhPX/N+KztrQP1M/Zkxii1w3D3rglDMZFtJuTA', 'Andry', 'Caceres',  TRUE);

SELECT * FROM S01USER_ACCOUNT;

SELECT * FROM s01identification_type;

-- 4. Registro de la Empresa Organizadora
INSERT INTO S01COMPANY (nIdIdentificationType, cIdentificationNumber, cBusinessName, cTradeName, cDescription, bIsRucValidated)
VALUES (2, '10607833791', 'Neravy Corporation', 'Neravy', 'Technologies development corporation', TRUE);

SELECT * FROM s01company;

-- 5. Vincular tu Usuario con la Empresa y un Rol
SELECT * FROM S01ROLE;

INSERT INTO S01USER_COMPANY_ROLE (nIdUserAccount, nIdCompany, nIdRole, bIsDefault)
VALUES (1, 1, 1, TRUE);

SELECT * FROM S01USER_COMPANY_ROLE;


/*
 * Paso 3: Inventario y Logística (El Evento)
Aquí es donde definimos qué vendemos y dónde.
 * */

-- Paso A: Asegurarnos de que existen los tipos (esto solo se hace una vez)
SELECT * FROM S01ENTITY_TYPE;

-- Paso A: Asegurarnos de que existen los tipos (esto solo se hace una vez)
INSERT INTO S01ENTITY_TYPE (cName) 
VALUES ('COMPANY'), ('CLIENT'), ('EMPLOYEE'), ('VENUE');


-- 6. El Recinto (Venue), aca el lugar si tiene el campo address pq es un lugar fisico en donde, si cambia pws ya no seria tecnicamente el lugar
-- OJO: VENUE tiene campo idCompany, pero es nulleable, si tiene valor es un lugar privado de la propia empresa, si es null es público
INSERT INTO S01VENUE (
    cName, 
    cAddress, -- Dirección descriptiva simple
    cCity, 
    nMaxCapacity, 
    cDescription, 
    cCountryIso,
    bIsActive,
    nLatitude,
    nLongitude
) VALUES (
    'La Terraza Rockera', 
    'C. Piérola 314, Cercado', 
    'Arequipa', 
    150, 
    'Espacio cultural para bandas y solistas en formato íntimo.', 
    'PE',
    TRUE,
    -16.4017652,
    -71.5349739
) RETURNING nIdVenue;

SELECT * FROM S01VENUE;

-- Insertamos el celular (Mobile)
INSERT INTO S01PHONE (
    nIdEntityType, 
    nEntityId, 
    nIdPhoneType, 
    cCountryCode,
    cAreaCode,
    cPhoneNumber,
    bIsVerified,
    bIsPrimary,
    bReceiveWhatsapp
) VALUES (
    (SELECT nIdEntityType FROM S01ENTITY_TYPE WHERE cName = 'VENUE'), -- ID 4
    (SELECT nIdVenue FROM S01VENUE WHERE cName = 'La Terraza Rockera'), -- El ID de la Terraza que obtuvimos arriba
    (SELECT nIdPhoneType FROM S01PHONE_TYPE WHERE cCode = 'MOBILE'),
    '+51',
    '54',
    '987654321',
    TRUE,
    TRUE,
    TRUE
);

INSERT INTO S01EMPLOYEE (cEmail, nIdCompany, cName, cLastName, bEmailVerified) --Contraseña Elmomer@123_XD:3
VALUES ('andry.caceres@estudiante.ucsm.edu.pe', '$argon2id$v=19$m=19456,t=2,p=1$GMO3YUMOg1ur+DG0zMFoEA$q3cpRFhPX/N+KztrQP1M/Zkxii1w3D3rglDMZFtJuTA', 'Andry', 'Caceres',  TRUE);


INSERT INTO S01PHONE (
    nIdEntityType, 
    nEntityId, 
    nIdPhoneType, 
    cCountryCode,
    cAreaCode,
    cPhoneNumber,
    bIsVerified,
    bIsPrimary,
    bReceiveWhatsapp
) VALUES (
    (SELECT nIdEntityType FROM S01ENTITY_TYPE WHERE cName = 'EMPLOYEE'), -- ID 4
    1, -- El ID de la Terraza que obtuvimos arriba
    (SELECT nIdPhoneType FROM S01PHONE_TYPE WHERE cCode = 'MOBILE'),
    '+51',
    '54',
    '902177449',
    TRUE,
    TRUE,
    TRUE
);
SELECT * FROM S01PHONE;

SELECT * FROM V_DIRECTORY;

SELECT * FROM s01entity_type;


-- ====================================================================================================

INSERT INTO S01SYSTEM_CONFIG (nIdCompany, cParamKey, cParamValue, cUnit, cDescription)
VALUES (1, 'TICKET_CASH_TIMEOUT', '48', 'HOURS', 'Plazo para que el cliente pague en efectivo antes de liberar stock');

-- Ejemplo: Configuración para pagos online (15 minutos de plazo)
INSERT INTO S01SYSTEM_CONFIG (nIdCompany, cParamKey, cParamValue, cUnit, cDescription)
VALUES (1, 'TICKET_ONLINE_TIMEOUT', '15', 'MINUTES', 'Plazo para completar el pago con tarjeta');


-- ============================================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================================

-- FUNCIÓN PARA OBTENER EL SIGUIENTE NÚMERO FORMATEADO
-- Ejemplo: Toma 'T001' y 45 -> devuelve 'T001-00000045'
CREATE OR REPLACE FUNCTION fn_get_next_document_number(p_nIdCompany INTEGER, p_cType VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_Prefix CHAR(4);
    v_NextNo INTEGER;
BEGIN
    UPDATE S01SERIES_CONFIG 
    SET nLastNumber = nLastNumber + 1
    WHERE nIdCompany = p_nIdCompany AND cDocumentType = p_cType
    RETURNING cPrefix, nLastNumber INTO v_Prefix, v_NextNo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró configuración de serie para % en esta empresa', p_cType;
    END IF;

    RETURN v_Prefix || '-' || LPAD(v_NextNo::TEXT, 8, '0');
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_check_venue_capacity_on_event()
RETURNS TRIGGER AS $$
DECLARE
    v_nVenueCapacity INTEGER;
BEGIN
    -- Obtener la capacidad máxima del local
    SELECT nMaxCapacity INTO v_nVenueCapacity 
    FROM S01VENUE WHERE nIdVenue = NEW.nIdVenue;

    -- Si el evento tiene más tickets que el local, lanzar error o alerta
    IF NEW.nMaxTicket > v_nVenueCapacity THEN
        RAISE EXCEPTION 'Error: La cantidad de tickets (%) supera la capacidad física del local (%)', 
            NEW.nMaxTicket, v_nVenueCapacity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_event_venue_capacity
BEFORE INSERT OR UPDATE ON S01EVENT
FOR EACH ROW EXECUTE FUNCTION fn_check_venue_capacity_on_event();


CREATE OR REPLACE FUNCTION fn_activate_tickets_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- Si el pago cambia a COMPLETED, activar todos sus tickets
    IF (OLD.cStatus != 'COMPLETED' AND NEW.cStatus = 'COMPLETED') THEN
        UPDATE S01TICKET 
        SET cStatus = 'PAID', tModifiedAt = NOW()
        WHERE nIdPayment = NEW.nIdPayment;
        
        -- Actualizar también el revenue en el evento
        UPDATE S01EVENT
        SET nTotalRevenue = nTotalRevenue + NEW.nAmount
        WHERE nIdEvent = NEW.nIdEvent;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_confirm_payment_activation
AFTER UPDATE ON S01PAYMENT
FOR EACH ROW EXECUTE FUNCTION fn_activate_tickets_on_payment();

CREATE OR REPLACE FUNCTION fn_process_credit_note_impact()
RETURNS TRIGGER AS $$
BEGIN
    -- Si la nota de crédito anula el pago original
    IF NEW.cReason = 'ANNULMENT' AND NEW.cStatus = 'EMITTED' THEN
        -- 1. Cancelamos los tickets vinculados al pago de esa nota
        UPDATE S01TICKET 
        SET cStatus = 'CANCELLED', tModifiedAt = NOW()
        WHERE nIdPayment = NEW.nIdPayment;
        
        -- 2. El stock en S01TICKET_PRICE se liberará automáticamente 
        -- gracias al trigger trg_sync_ticket_counters que ya creamos antes.
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_credit_note_impact
AFTER INSERT ON S01CREDIT_NOTE
FOR EACH ROW EXECUTE FUNCTION fn_process_credit_note_impact();

CREATE OR REPLACE FUNCTION fn_sync_ticket_counters()
RETURNS TRIGGER AS $$
DECLARE
    v_nIdPriceToUpdate INTEGER;
    v_nIdEventToUpdate INTEGER;
BEGIN
    -- ==========================================
    -- 1. MANEJO DE INSERCIÓN (INSERT)
    -- ==========================================
    IF (TG_OP = 'INSERT') THEN
        IF NEW.cStatus IN ('PENDING', 'PAID') THEN
            UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets + 1 WHERE nIdPrice = NEW.nIdPrice;
            PERFORM fn_refresh_event_soldout_status(NEW.nIdEvent);
        END IF;

    -- ==========================================
    -- 2. MANEJO DE ACTUALIZACIÓN (UPDATE)
    -- ==========================================
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Escenario A: Cambió el nIdPrice (Categoría de ticket)
        IF (OLD.nIdPrice <> NEW.nIdPrice) THEN
            -- Restar al viejo si estaba activo
            IF OLD.cStatus IN ('PENDING', 'PAID') THEN
                UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets - 1 WHERE nIdPrice = OLD.nIdPrice;
            END IF;
            -- Sumar al nuevo si está activo
            IF NEW.cStatus IN ('PENDING', 'PAID') THEN
                UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets + 1 WHERE nIdPrice = NEW.nIdPrice;
            END IF;
        
        -- Escenario B: Cambió el estado (lo que tú ya tenías)
        ELSIF (OLD.cStatus <> NEW.cStatus) THEN
            -- Si pasa de activo a inactivo
            IF (OLD.cStatus IN ('PENDING', 'PAID') AND NEW.cStatus = 'CANCELLED') THEN
                UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets - 1 WHERE nIdPrice = NEW.nIdPrice;
            -- Si pasa de inactivo a activo
            ELSIF (OLD.cStatus = 'CANCELLED' AND NEW.cStatus IN ('PENDING', 'PAID')) THEN
                UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets + 1 WHERE nIdPrice = NEW.nIdPrice;
            END IF;
        END IF;

        -- SIEMPRE actualizar el estado del evento al final de un UPDATE
        PERFORM fn_refresh_event_soldout_status(NEW.nIdEvent);
        NEW.tModifiedAt = NOW();

    -- ==========================================
    -- 3. MANEJO DE ELIMINACIÓN (DELETE)
    -- ==========================================
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.cStatus IN ('PENDING', 'PAID') THEN
            UPDATE S01TICKET_PRICE SET nSoldTickets = nSoldTickets - 1 WHERE nIdPrice = OLD.nIdPrice;
            PERFORM fn_refresh_event_soldout_status(OLD.nIdEvent);
        END IF;
    END IF;

    IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Función de Estado Global (Corregida para guardar el contador)
CREATE OR REPLACE FUNCTION fn_refresh_event_soldout_status(p_nIdEvent INTEGER)
RETURNS VOID AS $$
DECLARE
    v_nTotalSold INTEGER;
    v_nMaxCapacity INTEGER;
    v_cCurrentStatus VARCHAR(20);
BEGIN
    -- 1. Recalcular el total real sumando los tickets vendidos en todas las categorías del evento
    -- Usamos JOIN porque S01TICKET_PRICE se relaciona con S01TICKET_CATEGORY
    SELECT SUM(COALESCE(tp.nSoldTickets, 0)) 
    INTO v_nTotalSold 
    FROM S01TICKET_PRICE tp
    JOIN S01TICKET_CATEGORY tc ON tp.nIdCategory = tc.nIdCategory
    WHERE tc.nIdEvent = p_nIdEvent;

    -- 2. Obtener capacidad y estado actual del evento
    SELECT nMaxTicket, cStatus 
    INTO v_nMaxCapacity, v_cCurrentStatus 
    FROM S01EVENT 
    WHERE nIdEvent = p_nIdEvent;

    -- 3. ACTUALIZAR EL CONTADOR GLOBAL (Importante para reportes rápidos)
    UPDATE S01EVENT 
    SET nSoldTickets = COALESCE(v_nTotalSold, 0),
        tModifiedAt = NOW()
    WHERE nIdEvent = p_nIdEvent;

    -- 4. GESTIÓN AUTOMÁTICA DE ESTADO (Sold Out dinámico)
    -- Si hay espacio y estaba como SOLDOUT, volver a SCHEDULED
    IF v_nTotalSold < v_nMaxCapacity AND v_cCurrentStatus = 'SOLDOUT' THEN
        UPDATE S01EVENT SET cStatus = 'SCHEDULED' WHERE nIdEvent = p_nIdEvent;
    
    -- Si se llenó y no estaba en un estado final (COMPLETED/CANCELLED), marcar como SOLDOUT
    ELSIF v_nTotalSold >= v_nMaxCapacity AND v_cCurrentStatus NOT IN ('SOLDOUT', 'COMPLETED', 'CANCELLED') THEN
        UPDATE S01EVENT SET cStatus = 'SOLDOUT' WHERE nIdEvent = p_nIdEvent;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_ticket_counters
AFTER INSERT OR UPDATE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_sync_ticket_counters();


CREATE OR REPLACE FUNCTION fn_validate_ticket_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_nMaxTickets INTEGER;
    v_nSoldTickets INTEGER;
BEGIN
    -- EL CAMBIO CLAVE: Usamos FOR UPDATE para bloquear la fila de la fase de precio
    -- Esto obliga a otros procesos a "hacer cola" si intentan leer esta misma fila
    SELECT nMaxTickets, nSoldTickets 
    INTO v_nMaxTickets, v_nSoldTickets
    FROM S01TICKET_PRICE 
    WHERE nIdPrice = NEW.nIdPrice
    FOR UPDATE; -- Bloqueo de fila a nivel de base de datos

    -- Validar si hay espacio después de obtener el valor bloqueado
    IF v_nMaxTickets IS NOT NULL AND v_nSoldTickets >= v_nMaxTickets THEN
        RAISE EXCEPTION 'Lo sentimos, esta categoría de precio se ha agotado (Sold Out).';
    END IF;

    -- Al retornar NEW, el trigger procede con el INSERT y luego libera el bloqueo al terminar la transacción.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validate_ticket_stock
BEFORE INSERT ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_validate_ticket_stock();



CREATE OR REPLACE FUNCTION fn_set_ticket_expiration()
RETURNS TRIGGER AS $$
DECLARE
    v_timeout_val INTEGER;
    v_timeout_unit VARCHAR(20);
    v_is_gateway BOOLEAN;
    v_config_key VARCHAR(50);
BEGIN
    -- 1. Identificar si el pago es Gateway (Online) o Presencial (Cash)
    -- Necesitamos saber el nIdPayment asociado al ticket
    SELECT pm.bIsGateway INTO v_is_gateway
    FROM S01PAYMENT p
    JOIN S01PAYMENT_METHOD pm ON p.nIdPaymentMethod = pm.nIdPaymentMethod
    WHERE p.nIdPayment = NEW.nIdPayment;

    -- 2. Elegir la llave de configuración correcta
    IF v_is_gateway THEN
        v_config_key := 'TICKET_ONLINE_TIMEOUT';
    ELSE
        v_config_key := 'TICKET_CASH_TIMEOUT';
    END IF;

    -- 3. Obtener valores de la tabla S01SYSTEM_CONFIG
    SELECT cParamValue::INTEGER, cUnit 
    INTO v_timeout_val, v_timeout_unit
    FROM S01SYSTEM_CONFIG sc
    JOIN S01EVENT e ON e.nIdCompany = sc.nIdCompany
    WHERE e.nIdEvent = NEW.nIdEvent AND sc.cParamKey = v_config_key
    LIMIT 1;

    -- 4. Valores por defecto por seguridad si no hay config
    IF v_timeout_val IS NULL THEN
        v_timeout_val := CASE WHEN v_is_gateway THEN 15 ELSE 24 END;
        v_timeout_unit := CASE WHEN v_is_gateway THEN 'MINUTES' ELSE 'HOURS' END;
    END IF;

    -- 5. Aplicar la expiración dinámicamente
    NEW.tExpiresAt := NOW() + (v_timeout_val || ' ' || v_timeout_unit)::INTERVAL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_expiration_before_insert
BEFORE INSERT ON S01TICKET
FOR EACH ROW
WHEN (NEW.cStatus = 'PENDING' AND NEW.nIdPayment IS NOT NULL)
EXECUTE FUNCTION fn_set_ticket_expiration();

CREATE OR REPLACE FUNCTION fn_generic_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    -- Capturamos tanto el Usuario como el Contexto Operativo desde la sesión de la App
    v_user_id INTEGER := current_setting('app.current_user_id', true)::INTEGER;
    v_context_id BIGINT := current_setting('app.current_context_id', true)::BIGINT;
    
    v_record_id BIGINT;
    v_id_column_name TEXT;
BEGIN
    -- 1. Identificar dinámicamente el nombre de la PK
    SELECT a.attname INTO v_id_column_name
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = TG_RELID AND i.indisprimary;

    -- 2. Obtener el valor del ID del registro afectado
    IF (TG_OP = 'DELETE') THEN
        EXECUTE format('SELECT ($1).%I', v_id_column_name) USING OLD INTO v_record_id;
    ELSE
        EXECUTE format('SELECT ($1).%I', v_id_column_name) USING NEW INTO v_record_id;
    END IF;

    -- 3. Insertar en el log de auditoría incluyendo el contexto
    -- Nota: Asegúrate de que S01AUDIT_LOG tenga la columna nIdEmployeeContext
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO S01AUDIT_LOG (nIdUserAccount, nRecordId, cTableName, cOperation, jNewData)
        VALUES (v_user_id, v_record_id, TG_TABLE_NAME, TG_OP, to_jsonb(NEW));
        
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Optimización: Solo auditar si realmente hubo cambios en los datos JSON
        IF (to_jsonb(OLD) <> to_jsonb(NEW)) THEN
            INSERT INTO S01AUDIT_LOG (nIdUserAccount, nRecordId, cTableName, cOperation, jOldData, jNewData)
            VALUES (v_user_id, v_record_id, TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        END IF;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO S01AUDIT_LOG (nIdUserAccount, nRecordId, cTableName, cOperation, jOldData)
        VALUES (v_user_id, v_record_id, TG_TABLE_NAME, TG_OP, to_jsonb(OLD));
    END IF;
    
    -- En triggers AFTER, el valor de retorno se ignora, pero por estándar:
    IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_audit_ticket
AFTER INSERT OR UPDATE OR DELETE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_generic_audit_trigger();

-- Auditar Pagos
CREATE TRIGGER trg_audit_payment
AFTER INSERT OR UPDATE OR DELETE ON S01PAYMENT
FOR EACH ROW EXECUTE FUNCTION fn_generic_audit_trigger();

-- Auditar Precios (Vital para evitar fraude interno)
CREATE TRIGGER trg_audit_ticket_price
AFTER INSERT OR UPDATE OR DELETE ON S01TICKET_PRICE
FOR EACH ROW EXECUTE FUNCTION fn_generic_audit_trigger();

-- Función para liberar un token y que pueda ser usado en otro dispositivo
CREATE OR REPLACE PROCEDURE sp_reset_staff_token(p_nIdAccessToken INTEGER)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE S01STAFF_ACCESS_TOKEN 
    SET cBoundDeviceFingerprint = NULL,
        cBoundIp = NULL,
        tBoundAt = NULL,
        bIsUsed = FALSE
    WHERE nIdAccessToken = p_nIdAccessToken;
    
    -- Cerramos todas las sesiones activas de ese token
    UPDATE S01STAFF_SESSION 
    SET bIsActive = FALSE, 
        tSessionEnd = NOW() 
    WHERE nIdAccessToken = p_nIdAccessToken;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_logout_staff(p_cSessionToken UUID)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE S01STAFF_SESSION 
    SET bIsActive = FALSE, 
        tSessionEnd = NOW() 
    WHERE cSessionToken = p_cSessionToken;
    
    -- Opcional: Si quieres que el QR se pueda usar en otro fono después de salir
    -- UPDATE S01STAFF_ACCESS_TOKEN SET cBoundDeviceFingerprint = NULL ...
END;
$$;

CREATE OR REPLACE FUNCTION fn_audit_ticket_scanning()
RETURNS TRIGGER AS $$
BEGIN
    -- Si el ticket cambia a 'USED' y no tiene información de quién lo hizo
    IF (OLD.cStatus != 'USED' AND NEW.cStatus = 'USED') THEN
        
        -- Validar que se esté pasando obligatoriamente una sesión de staff
        IF NEW.nIdStaffSession IS NULL THEN
            RAISE EXCEPTION 'Error de Seguridad: No se puede validar un ticket sin una sesión de personal activa.';
        END IF;

        -- Llenamos automáticamente el tScannedAt si el backend se olvidó
        NEW.tScannedAt := NOW();
        
        -- Incrementamos el contador de la sesión para el dashboard en tiempo real
        UPDATE S01STAFF_SESSION 
        SET nScanCount = nScanCount + 1,
            tLastActivity = NOW()
        WHERE nIdStaffSession = NEW.nIdStaffSession;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Adaptación para tu sistema de Tickets
CREATE OR REPLACE FUNCTION fn_get_client_debt_in_event(p_nIdClient INTEGER, p_nIdEvent INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_total_reserved NUMERIC;
    v_total_paid NUMERIC;
BEGIN
    -- Suma de lo que debería pagar por tickets PENDING o PAID
    SELECT COALESCE(SUM(tp.nFinalPrice), 0) INTO v_total_reserved
    FROM S01TICKET t
    JOIN S01TICKET_PRICE tp ON t.nIdPrice = tp.nIdPrice
    WHERE t.nIdClient = p_nIdClient AND t.nIdEvent = p_nIdEvent
      AND t.cStatus != 'CANCELLED';
    
    -- Suma de lo que realmente pagó
    SELECT COALESCE(SUM(p.nAmount), 0) INTO v_total_paid
    FROM S01PAYMENT p
    WHERE p.nIdClient = p_nIdClient AND p.nIdEvent = p_nIdEvent
      AND p.cStatus = 'COMPLETED';
    
    RETURN v_total_reserved - v_total_paid;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION fn_generate_document_number(p_company_id INT, p_doc_type VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_prefix CHAR(4);
    v_new_number INT;
BEGIN
    -- Incrementar y obtener el nuevo correlativo para esa empresa
    UPDATE S01SERIES_CONFIG 
    SET nLastNumber = nLastNumber + 1
    WHERE nIdCompany = p_company_id AND cDocumentType = p_doc_type
    RETURNING cPrefix, nLastNumber INTO v_prefix, v_new_number;

    RETURN v_prefix || '-' || LPAD(v_new_number::TEXT, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCIÓN DE VALIDACIÓN Y FORMATEO DE TELÉFONO
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_and_format_phone()
RETURNS TRIGGER AS $$
BEGIN
    -- Limpiar número (solo dígitos)
    NEW.cPhoneNumber := regexp_replace(NEW.cPhoneNumber, '[^0-9]', '', 'g');
    
    -- Validar longitud (7-15 dígitos típicos)
    IF LENGTH(NEW.cPhoneNumber) < 7 OR LENGTH(NEW.cPhoneNumber) > 15 THEN
        RAISE EXCEPTION 'Teléfono debe tener entre 7 y 15 dígitos';
    END IF;
    
    -- Generar formato (ejemplo: +51 1 2345 6789)
    IF NEW.cCountryCode IS NOT NULL AND NEW.cAreaCode IS NOT NULL THEN
        NEW.cPhoneFormatted := NEW.cCountryCode || ' ' || NEW.cAreaCode || ' ' || NEW.cPhoneNumber;
    ELSIF NEW.cCountryCode IS NOT NULL THEN
        NEW.cPhoneFormatted := NEW.cCountryCode || ' ' || NEW.cPhoneNumber;
    ELSE
        NEW.cPhoneFormatted := NEW.cPhoneNumber;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCIONES AUXILIARES PARA TELÉFONOS
-- ============================================================================

CREATE OR REPLACE FUNCTION get_primary_phone(p_nIdEntityType VARCHAR, p_nEntityId INTEGER)
RETURNS VARCHAR AS $$
DECLARE
    v_phone_formatted VARCHAR;
BEGIN
    SELECT cPhoneFormatted INTO v_phone_formatted
    FROM S01PHONE
    WHERE nIdEntityType = p_nIdEntityType
        AND nEntityId = p_nEntityId
        AND bIsPrimary = TRUE
        AND bIsActive = TRUE
    LIMIT 1;
    
    RETURN COALESCE(v_phone_formatted, '');
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_phones(p_nIdEntityType VARCHAR, p_nEntityId INTEGER)
RETURNS TABLE(
    cPhoneNumber VARCHAR,
    cPhoneFormatted VARCHAR,
    cPhoneType VARCHAR,
    bIsPrimary BOOLEAN,
    bReceiveSMS BOOLEAN,
    bReceiveWhatsapp BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.cPhoneNumber,
        p.cPhoneFormatted,
        pt.cName,
        p.bIsPrimary,
        p.bReceiveSMS,
        p.bReceiveWhatsapp
    FROM S01PHONE p
    LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType
    WHERE p.nIdEntityType = p_nIdEntityType
        AND p.nEntityId = p_nEntityId
        AND p.bIsActive = TRUE
    ORDER BY p.bIsPrimary DESC, p.tCreatedAt DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- TRIGGER PARA VALIDACIÓN DE TELÉFONO
-- ============================================================================

CREATE TRIGGER phone_format_before_insert_update
BEFORE INSERT OR UPDATE ON S01PHONE
FOR EACH ROW EXECUTE FUNCTION validate_and_format_phone();



CREATE OR REPLACE FUNCTION fn_generate_unique_code(p_prefix VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_code VARCHAR(25);
    v_random_suffix VARCHAR(6);
BEGIN
    -- Prefijo (Ej: TCK) + Año + Random string
    v_random_suffix := upper(substr(md5(random()::text), 0, 6));
    v_code := p_prefix || '-' || to_char(now(), 'YYYY') || '-' || v_random_suffix;
    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- Trigger para aplicar el código antes de insertar un ticket
CREATE OR REPLACE FUNCTION fn_set_ticket_defaults()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.cCode IS NULL THEN
        NEW.cCode := fn_generate_unique_code('TCK');
    END IF;
    -- Generar PIN secreto de 3 dígitos basado en el teléfono del cliente (si existe)
    -- O un número aleatorio por seguridad
    NEW.cSecretPin := LPAD(floor(random() * 999)::text, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ticket_code_gen
BEFORE INSERT ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_set_ticket_defaults();


CREATE TRIGGER trg_audit_ticket_scan
BEFORE UPDATE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_audit_ticket_scanning();

CREATE OR REPLACE FUNCTION fn_cleanup_expired_tickets()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Cambiar a CANCELLED los tickets PENDING cuya tExpiresAt ya pasó
    WITH expired AS (
        UPDATE S01TICKET
        SET cStatus = 'CANCELLED', tModifiedAt = NOW()
        WHERE cStatus = 'PENDING' 
          AND tExpiresAt < NOW()
        RETURNING nIdTicket
    )
    SELECT count(*) INTO v_count FROM expired;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_validate_category_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_total_capacity_categories INTEGER;
    v_venue_max INTEGER;
BEGIN
    SELECT COALESCE(SUM(nMaxCapacity), 0) INTO v_total_capacity_categories
    FROM S01TICKET_CATEGORY WHERE nIdEvent = NEW.nIdEvent AND nIdTicketCategory != NEW.nIdTicketCategory;
    
    SELECT nMaxCapacity INTO v_venue_max
    FROM S01VENUE v JOIN S01EVENT e ON e.nIdVenue = v.nIdVenue
    WHERE e.nIdEvent = NEW.nIdEvent;

    IF (v_total_capacity_categories + NEW.nMaxCapacity) > v_venue_max THEN
        RAISE EXCEPTION 'La suma de capacidades de las zonas (%) supera la capacidad del local (%)', 
            (v_total_capacity_categories + NEW.nMaxCapacity), v_venue_max;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_category_limit
BEFORE INSERT OR UPDATE ON S01TICKET_CATEGORY
FOR EACH ROW EXECUTE FUNCTION fn_validate_category_limit();

CREATE OR REPLACE FUNCTION fn_check_staff_slots()
RETURNS TRIGGER AS $$
DECLARE
    v_nMaxSlots INTEGER;
    v_nCurrentSessions INTEGER;
    v_nIdEvent INTEGER;
BEGIN
    -- 1. Obtener el ID del evento desde el Access Token
    SELECT nIdEvent INTO v_nIdEvent 
    FROM S01STAFF_ACCESS_TOKEN 
    WHERE nIdAccessToken = NEW.nIdAccessToken;

    -- 2. Obtener el máximo permitido para ese evento
    SELECT nMaxStaffSlots INTO v_nMaxSlots 
    FROM S01EVENT WHERE nIdEvent = v_nIdEvent;

    -- 3. Contar sesiones actualmente activas para ese evento
    SELECT COUNT(*) INTO v_nCurrentSessions
    FROM S01STAFF_SESSION ss
    JOIN S01STAFF_ACCESS_TOKEN sat ON ss.nIdAccessToken = sat.nIdAccessToken
    WHERE sat.nIdEvent = v_nIdEvent AND ss.bIsActive = TRUE;

    -- 4. Validar
    IF v_nCurrentSessions >= v_nMaxSlots THEN
        RAISE EXCEPTION 'Límite de porteros alcanzado para este evento (Máx: %). Por favor, cierre una sesión activa.', v_nMaxSlots;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_limit_staff_sessions
BEFORE INSERT ON S01STAFF_SESSION
FOR EACH ROW EXECUTE FUNCTION fn_check_staff_slots();

CREATE OR REPLACE FUNCTION fn_bind_staff_device()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE S01STAFF_ACCESS_TOKEN
    SET cBoundDeviceFingerprint = NEW.cDeviceFingerprint
    WHERE nIdAccessToken = NEW.nIdAccessToken -- Corregido el nombre
      AND cBoundDeviceFingerprint IS NULL;

    IF EXISTS (
        SELECT 1 FROM S01STAFF_ACCESS_TOKEN 
        WHERE nIdAccessToken = NEW.nIdAccessToken -- Corregido el nombre
          AND cBoundDeviceFingerprint IS NOT NULL 
          AND cBoundDeviceFingerprint <> NEW.cDeviceFingerprint
    ) THEN
        RAISE EXCEPTION 'Dispositivo no autorizado para esta sesión de staff.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bind_staff_device
BEFORE INSERT ON S01STAFF_SESSION
FOR EACH ROW EXECUTE FUNCTION fn_bind_staff_device();


CREATE OR REPLACE FUNCTION fn_format_phone_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Limpiamos el número de cualquier espacio o guion que envíe el usuario
    -- Formato deseado: +51 987 654 321
    NEW.cPhoneFormatted := NEW.cCountryCode || ' ' || 
                          SUBSTRING(NEW.cPhoneNumber FROM 1 FOR 3) || ' ' || 
                          SUBSTRING(NEW.cPhoneNumber FROM 4 FOR 3) || ' ' || 
                          SUBSTRING(NEW.cPhoneNumber FROM 7 FOR 3);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_format_phone
BEFORE INSERT OR UPDATE ON S01PHONE
FOR EACH ROW EXECUTE FUNCTION fn_format_phone_number();

CREATE OR REPLACE FUNCTION fn_company_ruc_validation_stamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Si es un INSERT y viene como TRUE, ponemos la fecha
    IF (TG_OP = 'INSERT') THEN
        IF (NEW.bIsRucValidated = TRUE) THEN
            NEW.tRucValidationDate := NOW();
        END IF;
    
    -- Si es un UPDATE, verificamos que haya cambiado de FALSE a TRUE
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (NEW.bIsRucValidated = TRUE AND (OLD.bIsRucValidated = FALSE OR OLD.bIsRucValidated IS NULL)) THEN
            NEW.tRucValidationDate := NOW();
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_company_ruc_validation
BEFORE INSERT OR UPDATE ON S01COMPANY
FOR EACH ROW
EXECUTE FUNCTION fn_company_ruc_validation_stamp();


CREATE OR REPLACE FUNCTION fn_phone_verification_stamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Si es un INSERT y viene como TRUE, ponemos la fecha
    IF (TG_OP = 'INSERT') THEN
        IF (NEW.bIsVerified = TRUE) THEN
            NEW.tVerificationDate := NOW();
        END IF;
    
    -- Si es un UPDATE, verificamos que haya cambiado de FALSE a TRUE
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (NEW.bIsVerified = TRUE AND (OLD.bIsVerified = FALSE OR OLD.bIsVerified IS NULL)) THEN
            NEW.tVerificationDate := NOW();
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_phone_verification
BEFORE INSERT OR UPDATE ON S01PHONE
FOR EACH ROW
EXECUTE FUNCTION fn_phone_verification_stamp();

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE OR REPLACE VIEW V01TICKET_STOCK_ACTUAL AS
SELECT 
    p.nIdPrice,
    tc.cName AS cCategoryName,
    p.nMaxTickets,
    COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW())
    ) AS nRealSoldTickets,
    p.nMaxTickets - COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW())
    ) AS nAvailableStock
FROM S01TICKET_PRICE p
JOIN S01TICKET_CATEGORY tc ON p.nIdTicketCategory = tc.nIdTicketCategory
LEFT JOIN S01TICKET t ON p.nIdPrice = t.nIdPrice
GROUP BY p.nIdPrice, tc.cName, p.nMaxTickets;

CREATE OR REPLACE VIEW V_EVENT_ATTENDANCE_PROGRESS AS
SELECT 
    e.cName AS cEventName,
    COUNT(t.nIdTicket) AS nTicketsSold,
    COUNT(t.nIdTicket) FILTER (WHERE t.cStatus = 'USED') AS nCheckedIn,
    ROUND((COUNT(t.nIdTicket) FILTER (WHERE t.cStatus = 'USED') * 100.0) / 
          NULLIF(COUNT(t.nIdTicket), 0), 2) AS nAttendancePercentage
FROM S01EVENT e
JOIN S01TICKET t ON e.nIdEvent = t.nIdEvent
WHERE t.cStatus IN ('PAID', 'USED')
GROUP BY e.nIdEvent, e.cName;


-- VISTA DE CLIENTES CON SU TELÉFONO PRINCIPAL
DROP VIEW IF EXISTS V_CLIENT_WITH_PHONES;

CREATE VIEW V_CLIENT_WITH_PHONES AS
SELECT 
    cl.nIdClient,
    cl.cName || ' ' || cl.cLastName AS cClientName,
    cl.cEmail,
    p.cPhoneFormatted AS cPrimaryPhone,
    pt.cName AS cPhoneType
FROM S01CLIENT cl
LEFT JOIN S01ENTITY_TYPE et ON et.cName = 'CLIENT'
LEFT JOIN S01PHONE p ON cl.nIdClient = p.nEntityId 
    AND p.nIdEntityType = et.nIdEntityType 
    AND p.bIsPrimary = TRUE 
    AND p.bIsActive = TRUE
LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType;

-- DIRECTORIO UNIFICADO (Clientes, Empleados y Locales)
DROP VIEW IF EXISTS V_DIRECTORY;

CREATE VIEW V_DIRECTORY AS
-- PARTE 1: CLIENTES
SELECT 
    'CLIENT' AS cEntityType, 
    cl.cName || ' ' || cl.cLastName AS cFullName, 
    cl.cEmail,
    p.cPhoneFormatted AS cPhone
FROM S01CLIENT cl
LEFT JOIN S01ENTITY_TYPE et ON et.cName = 'CLIENT'
LEFT JOIN S01PHONE p ON cl.nIdClient = p.nEntityId 
    AND p.nIdEntityType = et.nIdEntityType 
    AND p.bIsPrimary = TRUE

UNION ALL

-- PARTE 2: EMPLEADOS
SELECT 
    'EMPLOYEE' AS cEntityType, 
    e.cName || ' ' || e.cLastName AS cFullName, 
    e.cEmail,
    p.cPhoneFormatted AS cPhone
FROM S01EMPLOYEE e
LEFT JOIN S01ENTITY_TYPE et ON et.cName = 'EMPLOYEE'
LEFT JOIN S01PHONE p ON e.nIdEmployee = p.nEntityId 
    AND p.nIdEntityType = et.nIdEntityType 
    AND p.bIsPrimary = TRUE

UNION ALL

-- PARTE 3: LOCALES (VENUES)
SELECT 
    'VENUE' AS cEntityType, 
    v.cName AS cFullName, 
    v.cEmail,
    p.cPhoneFormatted AS cPhone
FROM S01VENUE v
LEFT JOIN S01ENTITY_TYPE et ON et.cName = 'VENUE'
LEFT JOIN S01PHONE p ON v.nIdVenue = p.nEntityId 
    AND p.nIdEntityType = et.nIdEntityType 
    AND p.bIsPrimary = TRUE;


-- VISTA DE RESUMEN FINANCIERO POR EVENTO
DROP VIEW IF EXISTS V_EVENT_FINANCIAL_SUMMARY;
CREATE VIEW V_EVENT_FINANCIAL_SUMMARY AS
SELECT 
    e.nIdEvent,
    e.cName AS cEventName,
    e.tStartDate,
    COUNT(t.nIdTicket) FILTER (WHERE t.cStatus = 'PAID') AS nTicketsSold,
    COALESCE(SUM(p.nFinalPrice) FILTER (WHERE t.cStatus = 'PAID'), 0) AS nTotalRevenue,
    e.cStatus
FROM S01EVENT e
JOIN S01TICKET_CATEGORY tc ON e.nIdEvent = tc.nIdEvent
JOIN S01TICKET_PRICE p ON tc.nIdTicketCategory = p.nIdTicketCategory
LEFT JOIN S01TICKET t ON p.nIdPrice = t.nIdPrice
GROUP BY e.nIdEvent, e.cName, e.tStartDate, e.cStatus;

-- VISTA DE STOCK DE TICKETS (Categoría y Evento)
DROP VIEW IF EXISTS V01TICKET_STOCK_ACTUAL;
CREATE VIEW V01TICKET_STOCK_ACTUAL AS
SELECT 
    p.nIdPrice,
    e.cName AS cEventName,
    tc.cName AS cCategoryName,
    p.nMaxTickets,
    COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW())
    ) AS nRealSoldTickets,
    p.nMaxTickets - COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW())
    ) AS nAvailableStock
FROM S01TICKET_PRICE p
JOIN S01TICKET_CATEGORY tc ON p.nIdTicketCategory = tc.nIdTicketCategory
JOIN S01EVENT e ON tc.nIdEvent = e.nIdEvent
LEFT JOIN S01TICKET t ON p.nIdPrice = t.nIdPrice
GROUP BY p.nIdPrice, e.cName, tc.cName, p.nMaxTickets;


CREATE OR REPLACE VIEW V_LIVE_EVENT_CAPACITY AS
SELECT 
    e.nIdEvent,
    e.cName AS cEventName,
    v.cName AS cVenueName,
    v.nMaxCapacity AS nPhysicalLimit,
    e.nMaxTicket AS nTicketLimit,
    e.nSoldTickets AS nTotalSold,
    (SELECT count(*) FROM S01TICKET WHERE nIdEvent = e.nIdEvent AND cStatus = 'USED') AS nPeopleInside,
    (e.nSoldTickets - (SELECT count(*) FROM S01TICKET WHERE nIdEvent = e.nIdEvent AND cStatus = 'USED')) AS nExpectedPeople
FROM S01EVENT e
JOIN S01VENUE v ON e.nIdVenue = v.nIdVenue
WHERE e.cStatus IN ('ONGOING', 'SCHEDULED');

-- ============================================================================
-- CRON JOBS / TAREAS PROGRAMADAS REQUERIDAS
-- ============================================================================
/* ESTA SECCIÓN DESCRIBE LOS PROCESOS QUE DEBEN EJECUTARSE EXTERNAMENTE 
  (vía pg_cron, Node-cron o AWS EventBridge) PARA MANTENER LA SALUD DEL SISTEMA.

  1. CLEANUP_EXPIRED_TICKETS (Frecuencia: Cada 1 min)
     - Objetivo: Liberar stock de tickets estancados en 'PENDING'.
     - Lógica: 
        * Busca en S01TICKET donde cStatus = 'PENDING' y tExpiresAt < NOW().
        * Cambia cStatus a 'CANCELLED' y bIsActive a FALSE.
        * El trigger 'trg_sync_ticket_counters' devolverá automáticamente el stock al inventario.

  2. STAFF_SESSION_WATCHDOG (Frecuencia: Cada 30 min)
     - Objetivo: Seguridad perimetral y control de accesos.
     - Lógica: 
        * Busca en S01STAFF_SESSION sesiones 'bIsActive' = TRUE sin actividad (tLastActivity) > 4 horas.
        * Cambia bIsActive a FALSE y tSessionEnd a NOW().

  3. EVENT_STATUS_TRANSITION (Frecuencia: Cada 15 min)
     - Objetivo: Automatizar el ciclo de vida del evento.
     - Lógica:
        * 'SCHEDULED' -> 'ONGOING' si NOW() >= tStartDate.
        * 'ONGOING'   -> 'COMPLETED' si NOW() >= tEndDate (o tStartDate + 6h si tEndDate es NULL).
        * Marcar como 'SOLDOUT' si nSoldTickets >= nMaxTicket.

   4. AUDIT_LOG_ROTATION (Frecuencia: Mensual)
     - Objetivo: Mantener S01AUDIT_LOG por debajo de 1M de registros para no degradar performance.
     - Destino: S01AUDIT_LOG_HISTORY
     - Lógica de Ejecución:
        BEGIN;
          -- 1. Copiar datos viejos (> 90 días) al histórico
          INSERT INTO S01AUDIT_LOG_HISTORY 
          SELECT *, NOW() FROM S01AUDIT_LOG WHERE tCreatedAt < NOW() - INTERVAL '90 days';
          
          -- 2. Eliminar de la tabla activa
          DELETE FROM S01AUDIT_LOG WHERE tCreatedAt < NOW() - INTERVAL '90 days';
        COMMIT;
        UPDATE S01TICKET 
SET cStatus = 'CANCELLED', bIsActive = FALSE 
WHERE cStatus = 'PENDING' 
  AND tExpiresAt < NOW();


UPDATE S01STAFF_SESSION 
SET bIsActive = FALSE, tSessionEnd = NOW() 
WHERE bIsActive = TRUE 
  AND tLastActivity < NOW() - INTERVAL '4 hours';
  
  
Recordatorio Importante

Para que la variable v_user_id no sea nula, en tu aplicación (Node.js, Python, etc.) debes ejecutar lo siguiente justo después de abrir la conexión a la base de datos:
SQL

SET app.current_user_id = '123'; -- El ID del usuario que inició sesión


-- Mover heartbeats antiguos (> 24h) a histórico o borrarlos
DELETE FROM S01STAFF_HEARTBEAT 
WHERE tCreatedAt < NOW() - INTERVAL '24 hours';
*/
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_update_modified_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.tModifiedAt = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Para Empresas
CREATE TRIGGER trg_s01company_modified
BEFORE UPDATE ON S01COMPANY
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

-- Para Locales (Venues)
CREATE TRIGGER trg_s01venue_modified
BEFORE UPDATE ON S01VENUE
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

-- Para Clientes
CREATE TRIGGER trg_s01client_modified
BEFORE UPDATE ON S01CLIENT
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

-- Para Empleados
CREATE TRIGGER trg_s01employee_modified
BEFORE UPDATE ON S01EMPLOYEE
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

-- Para Teléfonos
CREATE TRIGGER trg_s01phone_modified
BEFORE UPDATE ON S01PHONE
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

-- Para Direcciones
CREATE TRIGGER trg_s01address_modified
BEFORE UPDATE ON S01ADDRESS
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();

CREATE TRIGGER trg_s01user_company_role_modified
BEFORE UPDATE ON S01USER_COMPANY_ROLE
FOR EACH ROW EXECUTE FUNCTION fn_update_modified_at_column();




