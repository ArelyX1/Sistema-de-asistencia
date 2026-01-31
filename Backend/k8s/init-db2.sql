-- ============================================================================
-- MODELO FINAL DE BASE DE DATOS: PRODUCCIÓN
-- PostgreSQL 14+
-- CUMPLIMIENTO: Mi criterio,ITIL, COBIT
-- NOMENCLATURA: nId{Tabla}, cId{Tabla}, nContador, cCodigo, bFlag, tTimestamp
-- ============================================================================
-- Hecho por ADYX
-- ============================================================================

-- ============================================================================
-- TABLAS MAESTRAS (Inmutables, precarga de datos)
-- ============================================================================

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

INSERT INTO S01IDENTIFICATION_TYPE 
(cCountryIso, cCode, cName, nMinLength, nMaxLength, bIsNumeric, cRegex) VALUES
('PE', '1', 'DNI', 8, 8, TRUE, '^[0-9]{8}$'),
('PE', '6', 'RUC', 11, 11, TRUE, '^(10|20|15|17)[0-9]{9}$'),
('PE', '7', 'PASAPORTE', 5, 20, FALSE, '^[a-zA-Z0-9]+$'),
('PE', '4', 'CARNET EXTRANJERIA', 9, 12, FALSE, NULL)
ON CONFLICT DO NOTHING;


CREATE TABLE S01PHONE_TYPE (
    nIdPhoneType SERIAL PRIMARY KEY,
    cCode VARCHAR(20) NOT NULL UNIQUE,
    cName VARCHAR(50) NOT NULL UNIQUE,
    cDescription TEXT,
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

INSERT INTO S01PHONE_TYPE (cCode, cName, cDescription, bIsActive) VALUES
('MOBILE', 'Teléfono Móvil', 'Celular personal o empresarial', TRUE),
('LANDLINE', 'Teléfono Fijo', 'Línea telefónica fija', TRUE),
('OFFICE', 'Teléfono Oficina', 'Extensión de oficina', TRUE),
('FAX', 'Fax', 'Línea de fax', TRUE)
ON CONFLICT (cCode) DO NOTHING;

-- ============================================================================ control de permisos

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

-- Inserción de roles base
INSERT INTO S01ROLE (cName, cDescription, bIsSystemRole) VALUES
('GOD_MODE', 'Control total del sistema (SaaS Owner)', TRUE),
('ORG_ADMIN', 'Administrador de la empresa organizadora', TRUE),
('EVENT_STAFF', 'Personal de apoyo (Porteros/Scanners)', TRUE),
('SALES_STAFF', 'Personal de ventas de tickets', TRUE)
ON CONFLICT (cName) DO NOTHING;
-- Tipo de entrada: Preventa 1, preventa 2, puerta etc.============================================================================

CREATE TABLE S01TICKET_CATEGORY (
    nIdTicketCategory SERIAL PRIMARY KEY,
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent) ON DELETE CASCADE,
    cName VARCHAR(50) NOT NULL, -- Ej: 'PREVENTA SOCIOS', 'GENERAL'
    cDescription TEXT,
    nMaxCapacity INTEGER NOT NULL, -- Capacidad total de la zona
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_ticket_category_event_active 
ON S01TICKET_CATEGORY(nIdEvent, bIsActive);

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

-- Índice vital para el Trigger de S01TICKET
-- Permitirá encontrar el precio actual en milisegundos
CREATE INDEX idx_ticket_price_lookup 
ON S01TICKET_PRICE (nIdTicketCategory, tValidFrom, tValidUntil) 
WHERE bIsActive = TRUE;

-- FUncion TODO en la tabla ticket, hacer una relación de ticket a discount, pero generalizar y juntar la tabla ticketprcephase y discountrule y que la tabla resultante tenga la relacion con category, asi generar tickets individuales sea cual sea el descuento como 2x1 o 3x2
-- TODO hacer el schema ticket


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

-- Inserción corregida por cCode
INSERT INTO S01PAYMENT_METHOD (cType, cCode, cName, bIsGateway) VALUES
('CASH', '001', 'Efectivo', FALSE),
('TRANSFER', '002', 'Transferencia Bancaria', FALSE),
('GATEWAY', '003', 'Tarjeta de Crédito/Débito', TRUE),
('E-WALLET', '005', 'Yape', FALSE),
('E-WALLET', '006', 'Plin', FALSE)
ON CONFLICT (cCode) DO NOTHING;

-- ============================================================================
-- PASO 2: ENTIDADES PRINCIPALES
-- ============================================================================
-- 1. LIMPIEZA DE TABLAS PADRE
ALTER TABLE S01COMPANY DROP COLUMN IF EXISTS cAddress, DROP COLUMN IF EXISTS cCity, DROP COLUMN IF EXISTS cCountryIso;
ALTER TABLE S01CLIENT DROP COLUMN IF EXISTS cCity, DROP COLUMN IF EXISTS cCountryIso;

-- 2. TABLA CENTRALIZADA DE DIRECCIONES
CREATE TABLE S01ADDRESS (
    nIdAddress BIGSERIAL PRIMARY KEY,
    
    -- Relación Polimórfica
    cEntityType VARCHAR(50) NOT NULL CHECK (cEntityType IN ('COMPANY', 'CLIENT', 'EMPLOYEE', 'VENUE')),
    nEntityId INTEGER NOT NULL,
    
    -- Clasificación
    cAddressType VARCHAR(20) DEFAULT 'MAIN' CHECK (cAddressType IN ('MAIN', 'FISCAL', 'DELIVERY', 'BRANCH', 'HOME')),
    
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

-- Índice para que al cargar el perfil del cliente los datos salgan al instante
CREATE INDEX idx_address_entity ON S01ADDRESS(cEntityType, nEntityId);



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
    
    -- Datos de ubicación (Provisionales hasta que normalices S01ADDRESS)
    cAddress VARCHAR(200) NOT NULL,
    cCity VARCHAR(50) NOT NULL,
    cCountryIso CHAR(2) DEFAULT 'PE', -- Usando el estándar ISO que definimos
    
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

-- Índice para búsquedas rápidas por RUC (muy común en facturación)
CREATE INDEX idx_company_ruc ON S01COMPANY(cIdentificationNumber);


-- TODO el cliente no debe depender del evento, asi reciclar datos de asistencia, y si va a 2 eventos pues registrarlo en su metadata, pero la cuestion seria si es valido entre empresas.
CREATE TABLE S01CLIENT (
    nIdClient SERIAL PRIMARY KEY,
    
    -- Datos de Identidad (Inmutables)
    cName VARCHAR(100) NOT NULL, -- Ampliado a 100 por nombres largos
    cLastName VARCHAR(100) NOT NULL,
    nIdIdentificationType INTEGER NOT NULL REFERENCES S01IDENTIFICATION_TYPE(nIdIdentificationType),
    cIdentificationNumber VARCHAR(20) NOT NULL,
    
    -- Contacto Global (Último conocido)
    cEmail VARCHAR(100) UNIQUE, -- El email suele ser único por persona en el sistema
    cPhonePrimary VARCHAR(20),
    
    -- Ubicación (Usando el estándar ISO que ya definimos)
    cCountryIso CHAR(2) DEFAULT 'PE',
    cCity VARCHAR(50) DEFAULT 'Arequipa',
    
    -- Metadata GLOBAL (Preferencias del sistema)
    jMetadata JSONB DEFAULT '{}'::JSONB,
    
    -- Auditoría
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,
    
    -- Un solo registro por DNI/Pasaporte en todo el sistema
    CONSTRAINT uq_client_id UNIQUE(nIdIdentificationType, cIdentificationNumber)
);

-- Índice para búsqueda rápida por documento (frecuente en ventas)
CREATE INDEX idx_client_doc ON S01CLIENT(cIdentificationNumber);

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

CREATE TABLE S01USER_ACCOUNT (
    nIdUserAccount SERIAL PRIMARY KEY,
    cEmail VARCHAR(100) NOT NULL UNIQUE,
    cPasswordHash VARCHAR(255) NOT NULL,
    cName VARCHAR(100),
    cLastName VARCHAR(100),
    
    -- Para recuperación de cuenta y seguridad
    bEmailVerified BOOLEAN DEFAULT FALSE,
    tLastLogin TIMESTAMP,
    
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP
);
CREATE TABLE S01USER_COMPANY_ROLE (
    nIdUserCompanyRole SERIAL PRIMARY KEY,
    nIdUserAccount INTEGER NOT NULL REFERENCES S01USER_ACCOUNT(nIdUserAccount),
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole),
    
    bIsDefault BOOLEAN DEFAULT FALSE, -- Para saber qué empresa cargar por defecto al entrar
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(nIdUserAccount, nIdCompany) -- Un usuario no puede tener dos roles base en la misma empresa
);

CREATE TABLE S01EMPLOYEE (
    nIdEmployee SERIAL PRIMARY KEY,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
    
    -- Identificación
	 cName VARCHAR(50) NOT NULL,
    cLastName VARCHAR(50) NOT NULL,    
    nIdIdentificationType INTEGER NOT NULL REFERENCES S01IDENTIFICATION_TYPE(nIdIdentificationType) ON DELETE RESTRICT,
    cIdentificationNumber VARCHAR(20) NOT NULL, -- Normalmente tiene que identificarse por su ruc
    
    -- SUNAT validation (nunca NULL)
    bIdentificationValidated BOOLEAN DEFAULT FALSE,
    tIdentificationValidationDate TIMESTAMP,
    cIdentificationValidationStatus VARCHAR(50),
    
    -- Contacto
    cEmail VARCHAR(100) NOT NULL UNIQUE,
    cPhonePrimary VARCHAR(20),
    cPhoneAlternative VARCHAR(20),
    
    -- Rol
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole) ON DELETE RESTRICT,
    
    -- Control
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW(),
    tModifiedAt TIMESTAMP,
    nIdUserAccount INTEGER REFERENCES S01USER_ACCOUNT(nIdUserAccount);
    
    -- Un usuario no puede ser dos empleados distintos en la misma empresa
    CONSTRAINT uq_employee_user_company UNIQUE(nIdUserAccount, nIdCompany),
    -- La empresa no puede tener el mismo documento duplicado
    CONSTRAINT uq_employee_doc_company UNIQUE(nIdCompany, nIdIdentificationType, cIdentificationNumber)
);
-- Nota: cuando el emppleado inicie sesion, que le liste las empresas a las que esta trabajando, solo cuando esta iniciando sesion, evitar mostrar primero las empresas y luego que el user inicie sesion
CREATE TABLE S01VENUE (
    nIdVenue SERIAL PRIMARY KEY,
    -- Un local suele ser registrado por una empresa específica
    nIdCompany INTEGER REFERENCES S01COMPANY(nIdCompany) ON DELETE CASCADE,
    
    cName VARCHAR(100) NOT NULL, -- Ampliado por nombres largos
    cDescription TEXT,
    cLogoUrl VARCHAR(500),
    cEmail VARCHAR(100),
    cPhonePrimary VARCHAR(20),
    
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
);

-- Índice para buscar locales por empresa rápidamente
CREATE INDEX idx_venue_company ON S01VENUE(nIdCompany);


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

-- colocar una cantidad maxima de tickets que se puede generar, cuando se llegue al tope colocar el estado soldout, crear trigger o funcion de eso
CREATE TABLE S01EVENT (
    nIdEvent SERIAL PRIMARY KEY,
    
    -- Identificación y Propiedad
    cName VARCHAR(150) NOT NULL,
    cDescription TEXT,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany) ON DELETE RESTRICT,
    nIdEmployeeCreatedBy INTEGER REFERENCES S01EMPLOYEE(nIdEmployee) ON DELETE SET NULL,
    
    -- Ubicación y Visual
    nIdVenue INTEGER REFERENCES S01VENUE(nIdVenue) ON DELETE SET NULL,
    cFlyerUrl VARCHAR(500),
    
    -- Gestión de Inventario Global
    nMaxTicket INTEGER NOT NULL CHECK (nMaxTicket > 0),
    nSoldTickets INTEGER DEFAULT 0, -- PAID + PENDING acumulados
    
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

-- Índice para que el usuario encuentre eventos próximos rápido
CREATE INDEX idx_event_dates ON S01EVENT(tStartDate, cStatus) WHERE cStatus != 'CANCELLED';
ALTER TABLE S01EVENT 
ADD CONSTRAINT chk_event_dates_logic 
CHECK (tEndDate IS NULL OR tEndDate > tStartDate);

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

-- Índice para cierres de caja (Ventas del día por empresa)
CREATE INDEX idx_payment_report ON S01PAYMENT (nIdCompany, tCreatedAt, cStatus);

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

-- ============================================================================

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

-- ============================================================================
-- Tabña DE TELÉFONOS NORMALIZADA, esto es para una relacion 'virtual' para polimorfismo
-- ============================================================================

CREATE TABLE S01PHONE (
    nIdPhone BIGSERIAL PRIMARY KEY,
    
    -- Relación (polimorfa: puede ser cliente, empleado o empresa)
    cEntityType VARCHAR(50) NOT NULL CHECK (cEntityType IN ('CLIENT', 'EMPLOYEE', 'COMPANY')),
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
    UNIQUE(cEntityType, nEntityId, cPhoneNumber)
);

-- ============================================================================
-- TICKET, pero hay que considerar que ya tiene legado, ademas hay que ver que no supere el limite de max de tickets por evento pero contando solo los tickets con estado de paid y pending, en ese caso no deberia dejar de crear mas tickets, pero hay que dar timeout de los pendig antes del evento pq esos normalmente son cancelados, seria buena idea tener un estado de 'WAITING'?
-- Un user puede comprar 2 o mas tickets adicionales al suyo pero no necesariamente sabiendo para quienes seran el resto ademas del suyo
-- Imagina 1 user compra 3 entradas, 1 para el y 2 para amigos que no saben nada, el organizador debe registrar los datos, pero es necesario saber los DNIs de los 3? porque no solo poner las 3 a nombre de 1 solo, ahora deben generarse los 3 tickets individuales pero todos con el mismo pin secreto (de esta manera cualquier puede usar cualquier de los 3 tickets, hay que ver sus desventajas), y cuando se liste los tickets al ingresar el dni con los 3 ultimos digitos de su numero telefonico le mostraran los 3 tickets en frontend, ahora cuando se registre 1 ya no le apareceran los 3, le pareceran 2 pero debe tener la opcion de ver todos los tickets, en todos sus estados.
-- El secret pin por el moemtno seran los 3 ultimos digitos de su numero celular del comprador, luego habra que optimizarse.
-- ============================================================================
CREATE TABLE S01STAFF_SESSION (
    nIdStaffSession SERIAL PRIMARY KEY,
    nIdAccessToken INTEGER NOT NULL REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken),
    
    -- Información del dispositivo (para detectar si comparten la cuenta)
    cDeviceFingerprint VARCHAR(255), 
    cIPAddress INET,
    
    -- Tiempos de actividad
    tSessionStart TIMESTAMP DEFAULT NOW(),
    tSessionEnd TIMESTAMP, -- Se llena cuando el portero hace "Logout"
    tLastActivity TIMESTAMP DEFAULT NOW(),
    
    -- Estadísticas de la sesión (Denormalizado para rapidez en el dashboard)
    nScanCount INTEGER DEFAULT 0,
    
    bIsActive BOOLEAN DEFAULT TRUE
);

-- Índice para ver quiénes están escaneando en vivo
CREATE INDEX idx_active_sessions ON S01STAFF_SESSION(bIsActive) WHERE bIsActive = TRUE;

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
    
    -- Trazabilidad de escaneo (Lo que hablamos del portero)
    nIdAccessToken INTEGER REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken)
);
-- Esto esta de locos pero para los porteros, un qr que escaneen y les da acceso a una cuenta de acceso temporal para que puedan registrar, el qr debe tener un access token, agregar rol de godmod, el admin, que puede ser cualquiera a cargo del evento
CREATE OR REPLACE FUNCTION fn_sync_ticket_counters()
RETURNS TRIGGER AS $$
BEGIN
    -- CASO 1: NUEVO TICKET (Reserva de cupo)
    IF (TG_OP = 'INSERT') THEN
        IF NEW.cStatus IN ('PENDING', 'PAID') THEN
            -- Sumar al precio
            UPDATE S01TICKET_PRICE 
            SET nSoldTickets = nSoldTickets + 1 
            WHERE nIdPrice = NEW.nIdPrice;
        END IF;
        RETURN NEW;

    -- CASO 2: CAMBIO DE ESTADO (Pago, Cancelación o Uso)
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Si pasa de activo (PENDING/PAID) a inactivo (CANCELLED)
        IF (OLD.cStatus IN ('PENDING', 'PAID') AND NEW.cStatus = 'CANCELLED') THEN
            UPDATE S01TICKET_PRICE 
            SET nSoldTickets = nSoldTickets - 1 
            WHERE nIdPrice = NEW.nIdPrice;
        
        -- Si por error estaba cancelado y lo reactivan (poco común pero posible)
        ELSIF (OLD.cStatus = 'CANCELLED' AND NEW.cStatus IN ('PENDING', 'PAID')) THEN
            UPDATE S01TICKET_PRICE 
            SET nSoldTickets = nSoldTickets + 1 
            WHERE nIdPrice = NEW.nIdPrice;
        END IF;
        
        -- Actualizar timestamp de modificación
        NEW.tModifiedAt = NOW();
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- B. Creación del Trigger
CREATE TRIGGER trg_sync_ticket_counters
AFTER INSERT OR UPDATE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_sync_ticket_counters();
CREATE OR REPLACE FUNCTION fn_validate_ticket_stock()
RETURNS TRIGGER AS $$
DECLARE
    v_nMaxTickets INTEGER;
    v_nSoldTickets INTEGER;
BEGIN
    -- Consultar el stock actual de la fase de precio
    SELECT nMaxTickets, nSoldTickets INTO v_nMaxTickets, v_nSoldTickets
    FROM S01TICKET_PRICE WHERE nIdPrice = NEW.nIdPrice;

    -- Validar si hay espacio
    IF v_nMaxTickets IS NOT NULL AND v_nSoldTickets >= v_nMaxTickets THEN
        RAISE EXCEPTION 'Lo sentimos, esta categoría de precio se ha agotado (Sold Out).';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_ticket_stock
BEFORE INSERT ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_validate_ticket_stock();


CREATE TABLE S01SYSTEM_CONFIG (
    nIdConfig SERIAL PRIMARY KEY,
    nIdCompany INTEGER REFERENCES S01COMPANY(nIdCompany),
    cParamKey VARCHAR(50) NOT NULL, 
    cParamValue VARCHAR(100) NOT NULL,
    cUnit VARCHAR(20) DEFAULT 'MINUTES' CHECK (cUnit IN ('MINUTES', 'HOURS', 'DAYS')),
    cDescription TEXT,
    
    UNIQUE(nIdCompany, cParamKey)
);

-- Ejemplo: Configuración para pagos en efectivo (48 horas de plazo)
INSERT INTO S01SYSTEM_CONFIG (nIdCompany, cParamKey, cParamValue, cUnit, cDescription)
VALUES (1, 'TICKET_CASH_TIMEOUT', '48', 'HOURS', 'Plazo para que el cliente pague en efectivo antes de liberar stock');

-- Ejemplo: Configuración para pagos online (15 minutos de plazo)
INSERT INTO S01SYSTEM_CONFIG (nIdCompany, cParamKey, cParamValue, cUnit, cDescription)
VALUES (1, 'TICKET_ONLINE_TIMEOUT', '15', 'MINUTES', 'Plazo para completar el pago con tarjeta');

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


CREATE TABLE S01STAFF_ACCESS_TOKEN (
    nIdAccessToken SERIAL PRIMARY KEY,
    nIdEvent INTEGER NOT NULL REFERENCES S01EVENT(nIdEvent),
    nIdVenue INTEGER REFERENCES S01VENUE(nIdVenue) ON DELETE SET NULL,
    
    -- El token secreto que irá dentro del QR
    cToken VARCHAR(64) UNIQUE NOT NULL, 
    
    -- Quién autorizó este acceso (GodMode / Admin)
    nIdEmployeeAuthorizer INTEGER REFERENCES S01EMPLOYEE(nIdEmployee),
	 nIdEmployee INTEGER REFERENCES S01EMPLOYEE(nIdEmployee), -- Opcional si es genérico
	 cDeviceIdentifier VARCHAR(100), -- Para amarrar el token a un celular físico
    -- Datos del portero (los ingresa al "canjear" el QR)
    cStaffName VARCHAR(100),
    cStaffDni VARCHAR(20),
    
    -- Control de tiempo (Vulnerabilidad mitigada)
    tExpiresAt TIMESTAMP NOT NULL,
    bIsUsed BOOLEAN DEFAULT FALSE, -- ¿Ya se logueó alguien con este QR?
    bIsActive BOOLEAN DEFAULT TRUE,
    
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

-- Índice para validación ultra rápida de tokens
CREATE INDEX idx_access_token_lookup ON S01STAFF_ACCESS_TOKEN(cToken) WHERE bIsActive = TRUE;

-- ============================================================================
-- PASO 5: AUDITORÍA CENTRALIZADA (Unidireccional, sin cíclicas)
-- ============================================================================

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

-- Índices para que el oficial de cumplimiento encuentre cambios rápido
CREATE INDEX idx_audit_table_record ON S01AUDIT_LOG(cTableName, nRecordId);
CREATE INDEX idx_audit_timestamp ON S01AUDIT_LOG(tCreatedAt);
CREATE OR REPLACE FUNCTION fn_generic_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_user_id INTEGER;
BEGIN
    -- Intentar obtener el ID de usuario desde una variable de sesión de la DB
    -- (Tu backend debe ejecutar: SET LOCAL audit.user_id = 123; al abrir la conexión)
    v_user_id := current_setting('audit.user_id', true);

    IF (TG_OP = 'UPDATE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := to_jsonb(OLD);
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := to_jsonb(NEW);
    END IF;

    INSERT INTO S01AUDIT_LOG (
        nIdUserAccount,
        cTableName,
        cOperation,
        nRecordId,
        jOldData,
        jNewData,
        cIpAddress
    ) VALUES (
        v_user_id,
        TG_TABLE_NAME,
        TG_OP,
        COALESCE(NEW.nIdTicket, NEW.nIdPayment, NEW.nIdEvent, OLD.nIdTicket, OLD.nIdPayment, OLD.nIdEvent), -- Ajustar según ID
        v_old_data,
        v_new_data,
        inet_client_addr()
    );

    RETURN NULL; -- Los triggers AFTER pueden retornar NULL
END;
$$ LANGUAGE plpgsql;

-- Auditar Tickets
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

-- ============================================================================
-- PASO 6: TABLAS DE PERMISOS Y ROLES
-- ============================================================================

CREATE TABLE S01PERMISSION (
    nIdPermission SERIAL PRIMARY KEY,
    cCode VARCHAR(50) NOT NULL UNIQUE,
    cName VARCHAR(100) NOT NULL UNIQUE,
    cDescription TEXT,
    cModule VARCHAR(50),
    bIsActive BOOLEAN DEFAULT TRUE,
    tCreatedAt TIMESTAMP DEFAULT NOW()
);

INSERT INTO S01PERMISSION (cCode, cName, cDescription, cModule, bIsActive) VALUES
-- Permisos para Eventos
('CREATE_EVENT', 'Crear Evento', 'Permite crear nuevos eventos', 'EVENTS', TRUE),
('VIEW_EVENT', 'Ver Evento', 'Permite ver detalles de eventos', 'EVENTS', TRUE),
('EDIT_EVENT', 'Editar Evento', 'Permite editar eventos en estado DRAFT', 'EVENTS', TRUE),
('PUBLISH_EVENT', 'Publicar Evento', 'Permite publicar eventos (cambiar estado a PUBLISHED)', 'EVENTS', TRUE),
('DELETE_EVENT', 'Eliminar Evento', 'Permite eliminar/anular eventos', 'EVENTS', TRUE),


('CREATE_ACCESSTMP', 'Crear AccessTmp', 'Permite crear nuevos eventos', 'EVENTS', TRUE),


-- Permisos para Tickets (similar estructura)
('CREATE_TICKET', 'Crear Ticket', 'Permite crear nuevos tickets de evento', 'TICKETS', TRUE),
('VIEW_TICKET', 'Ver Ticket', 'Permite ver detalles de tickets', 'TICKETS', TRUE),
('EDIT_TICKET', 'Editar Ticket', 'Permite editar tickets en estado PENDING', 'TICKETS', TRUE),
('ISSUE_TICKET', 'Emitir Ticket', 'Permite emitir tickets (cambiar estado a ISSUED)', 'TICKETS', TRUE),
('CANCEL_TICKET', 'Cancelar Ticket', 'Permite cancelar tickets', 'TICKETS', TRUE),
('CREATE_CLIENT', 'Crear Cliente', 'Permite crear nuevos clientes', 'CLIENTS', TRUE),
('VIEW_CLIENT', 'Ver Cliente', 'Permite ver detalles de clientes', 'CLIENTS', TRUE),
('EDIT_CLIENT', 'Editar Cliente', 'Permite editar datos de clientes', 'CLIENTS', TRUE),
('DELETE_CLIENT', 'Eliminar Cliente', 'Permite eliminar clientes', 'CLIENTS', TRUE),
('CREATE_PAYMENT', 'Crear Pago', 'Permite registrar nuevos pagos', 'PAYMENTS', TRUE),
('VIEW_PAYMENT', 'Ver Pago', 'Permite ver detalles de pagos', 'PAYMENTS', TRUE),
('REFUND_PAYMENT', 'Revertir Pago', 'Permite revertir pagos (REFUND)', 'PAYMENTS', TRUE),
('DELETE_PAYMENT', 'Eliminar Pago', 'Permite eliminar pagos', 'PAYMENTS', TRUE),
('CREATE_PRODUCT', 'Crear Producto', 'Permite crear nuevos productos', 'PRODUCTS', TRUE),
('VIEW_PRODUCT', 'Ver Producto', 'Permite ver productos', 'PRODUCTS', TRUE),
('EDIT_PRODUCT', 'Editar Producto', 'Permite editar datos de productos', 'PRODUCTS', TRUE),
('DELETE_PRODUCT', 'Eliminar Producto', 'Permite eliminar productos', 'PRODUCTS', TRUE),
('VIEW_AUDIT_LOG', 'Ver Auditoría', 'Permite acceder a logs de auditoría', 'AUDIT', TRUE),
('VIEW_REPORTS', 'Ver Reportes', 'Permite acceder a reportes del sistema', 'REPORTS', TRUE),
('MANAGE_USERS', 'Gestionar Usuarios', 'Permite crear/editar/eliminar usuarios', 'ADMIN', TRUE),
('MANAGE_ROLES', 'Gestionar Roles', 'Permite crear/editar permisos y roles', 'ADMIN', TRUE),
('SYSTEM_CONFIG', 'Configuración del Sistema', 'Permite acceso a configuración global', 'ADMIN', TRUE)
ON CONFLICT (cCode) DO NOTHING;

-- Permisos críticos añadidos
INSERT INTO S01PERMISSION (cCode, cName, cDescription, cModule) VALUES
('SCAN_TICKET', 'Escanear Ticket', 'Permiso para validar entrada en puerta', 'OPERATIONS'),
('MANAGE_VENUES', 'Gestionar Locales', 'Crear y editar sedes de eventos', 'EVENTS'),
('VIEW_DASHBOARD', 'Ver Dashboard', 'Ver estadísticas generales de la empresa', 'REPORTS')
ON CONFLICT (cCode) DO NOTHING;

CREATE TABLE S01SERIES_CONFIG (
    nIdSeries SERIAL PRIMARY KEY,
    nIdCompany INTEGER NOT NULL REFERENCES S01COMPANY(nIdCompany),
    cDocumentType VARCHAR(20) NOT NULL, -- 'TICKET', 'PAYMENT', 'CREDIT_NOTE'
    cPrefix CHAR(4) NOT NULL,           -- Ej: 'T001', 'F001'
    nLastNumber INTEGER DEFAULT 0,
    
    UNIQUE(nIdCompany, cDocumentType, cPrefix)
);


ALTER TABLE S01STAFF_ACCESS_TOKEN 
ADD COLUMN cBoundDeviceFingerprint VARCHAR(255), -- El ID único del celular del portero
ADD COLUMN cBoundIp INET,                       -- IP de la primera conexión
ADD COLUMN tBoundAt TIMESTAMP,                  -- Cuándo se ancló el dispositivo
ADD COLUMN nMaxConcurrentSessions INTEGER DEFAULT 1; -- Por si un token es para un "team" (raro, pero útil)

-- Índice para validación rápida de tokens ya anclados
CREATE INDEX idx_token_device_security ON S01STAFF_ACCESS_TOKEN(cToken, cBoundDeviceFingerprint);

-- Índice para que el limpiador de stock vuele
CREATE INDEX idx_ticket_expiration_lookup 
ON S01TICKET (tExpiresAt, cStatus) 
WHERE cStatus = 'PENDING' AND bIsActive = FALSE;


ALTER TABLE S01STAFF_SESSION
ADD COLUMN cDeviceFingerprint VARCHAR(255) NOT NULL,
ADD COLUMN bIsRevoked BOOLEAN DEFAULT FALSE; -- Para que el Admin pueda patear a un portero sospechoso


CREATE OR REPLACE VIEW V01TICKET_STOCK_ACTUAL AS
SELECT 
    p.nIdPrice,
    p.nIdTicketCategory,
    p.nMaxTickets,
    -- Contamos solo los PAID y los PENDING que NO han expirado
    COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW() AND t.bIsExpired = FALSE)
    ) AS nRealSoldTickets,
    -- Calculamos el stock disponible real
    p.nMaxTickets - COUNT(t.nIdTicket) FILTER (
        WHERE t.cStatus = 'PAID' 
        OR (t.cStatus = 'PENDING' AND t.tExpiresAt > NOW() AND t.bIsExpired = FALSE)
    ) AS nAvailableStock
FROM S01TICKET_PRICE p
LEFT JOIN S01TICKET t ON p.nIdPrice = t.nIdPrice
GROUP BY p.nIdPrice;


-- ============================================================================

CREATE TABLE S01ROLE_PERMISSION (
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole) ON DELETE CASCADE,
    nIdPermission INTEGER NOT NULL REFERENCES S01PERMISSION(nIdPermission) ON DELETE CASCADE,
    tAssignedAt TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (nIdRole, nIdPermission)
);

-- ============================================================================

CREATE TABLE S01EMPLOYEE_ROLE (
    nIdEmployee INTEGER NOT NULL REFERENCES S01EMPLOYEE(nIdEmployee) ON DELETE CASCADE,
    nIdRole INTEGER NOT NULL REFERENCES S01ROLE(nIdRole) ON DELETE CASCADE,
    tAssignedAt TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (nIdEmployee, nIdRole)
);

-- ============================================================================
-- 
-- ============================================================================

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

ALTER TABLE S01STAFF_SESSION 
ADD COLUMN cSessionToken UUID DEFAULT gen_random_uuid(), -- Token único para ese navegador
ADD COLUMN tLastActivity TIMESTAMP DEFAULT NOW(),        -- Para el "Heartbeat"
ADD COLUMN tExpiresAt TIMESTAMP NOT NULL;               -- Fecha de muerte automática

-- Índice para validar sesiones activas por token de sesión
CREATE INDEX idx_staff_session_lookup ON S01STAFF_SESSION(cSessionToken) WHERE bIsActive = TRUE;

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
ALTER TABLE S01TICKET 
-- El ID de la sesión específica que hizo el UPDATE a 'USED'
ADD COLUMN nIdStaffSession INTEGER REFERENCES S01STAFF_SESSION(nIdStaffSession),

-- Denormalizamos un poco el ID del Access Token para reportes rápidos de "Tickets por Puerta"
ADD COLUMN nIdStaffAccessToken INTEGER REFERENCES S01STAFF_ACCESS_TOKEN(nIdAccessToken),

-- Guardamos el IP de ese escaneo específico por si hay reclamos de ubicación
ADD COLUMN cScannedIp INET;

-- Índice para auditoría: ¿Cuántos tickets escaneó X sesión?
CREATE INDEX idx_ticket_audit_scan ON S01TICKET(nIdStaffSession) WHERE cStatus = 'USED';

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

CREATE TRIGGER trg_audit_ticket_scan
BEFORE UPDATE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_audit_ticket_scanning();


-- ============================================================================
-- PASO 8: FUNCIONES BASE
-- ============================================================================







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
-- ============================================================================
-- PASO 9: FUNCIÓN DE VALIDACIÓN Y FORMATEO DE TELÉFONO
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
-- PASO 10: FUNCIONES AUXILIARES PARA TELÉFONOS
-- ============================================================================

CREATE OR REPLACE FUNCTION get_primary_phone(p_cEntityType VARCHAR, p_nEntityId INTEGER)
RETURNS VARCHAR AS $$
DECLARE
    v_phone_formatted VARCHAR;
BEGIN
    SELECT cPhoneFormatted INTO v_phone_formatted
    FROM S01PHONE
    WHERE cEntityType = p_cEntityType
        AND nEntityId = p_nEntityId
        AND bIsPrimary = TRUE
        AND bIsActive = TRUE
    LIMIT 1;
    
    RETURN COALESCE(v_phone_formatted, '');
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================

CREATE OR REPLACE FUNCTION get_all_phones(p_cEntityType VARCHAR, p_nEntityId INTEGER)
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
    WHERE p.cEntityType = p_cEntityType
        AND p.nEntityId = p_nEntityId
        AND p.bIsActive = TRUE
    ORDER BY p.bIsPrimary DESC, p.tCreatedAt DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- PASO 11: TRIGGER PARA VALIDACIÓN DE TELÉFONO
-- ============================================================================

CREATE TRIGGER phone_format_before_insert_update
BEFORE INSERT OR UPDATE ON S01PHONE
FOR EACH ROW EXECUTE FUNCTION validate_and_format_phone();

-- ============================================================================
-- PASO 12: ÍNDICES PARA TELÉFONOS
-- ============================================================================

CREATE INDEX idx_phone_entity ON S01PHONE(cEntityType, nEntityId);
CREATE INDEX idx_phone_number ON S01PHONE(cPhoneNumber);
CREATE INDEX idx_phone_type ON S01PHONE(nIdPhoneType);
CREATE INDEX idx_phone_primary ON S01PHONE(cEntityType, nEntityId, bIsPrimary);

-- ============================================================================
-- PASO 13: VISTAS CONSOLIDADAS (CORREGIDAS + TELÉFONOS)
-- ============================================================================


-- ============================================================================

-- ============================================================================

-- ============================================================================

CREATE VIEW V_CLIENT_WITH_PHONES AS
SELECT 
    cl.nIdClient,
    cl.cName || ' ' || cl.cLastName AS cClientName,
    cl.cIdentificationNumber,
    cl.cEmail,
    pt.cName AS cPrimaryPhoneType,
    p.cPhoneFormatted AS cPrimaryPhone,
    COUNT(p2.nIdPhone) AS nTotalPhones
FROM S01CLIENT cl
LEFT JOIN S01PHONE p ON cl.nIdClient = p.nEntityId 
    AND p.cEntityType = 'CLIENT' 
    AND p.bIsPrimary = TRUE 
    AND p.bIsActive = TRUE
LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType
LEFT JOIN S01PHONE p2 ON cl.nIdClient = p2.nEntityId 
    AND p2.cEntityType = 'CLIENT' 
    AND p2.bIsActive = TRUE
GROUP BY cl.nIdClient, cClientName, cl.cIdentificationNumber, cl.cEmail, pt.cName, p.cPhoneFormatted;

-- ============================================================================

CREATE VIEW V_EMPLOYEE_WITH_PHONES AS
SELECT 
    e.nIdEmployee,
    e.cName || ' ' || e.cLastName AS cEmpName,
    e.cEmail,
    co.cBusinessName AS cCompanyName,
    pt.cName AS cPrimaryPhoneType,
    p.cPhoneFormatted AS cPrimaryPhone,
    COUNT(p2.nIdPhone) AS nTotalPhones
FROM S01EMPLOYEE e
LEFT JOIN S01COMPANY co ON e.nIdCompany = co.nIdCompany
LEFT JOIN S01PHONE p ON e.nIdEmployee = p.nEntityId 
    AND p.cEntityType = 'EMPLOYEE' 
    AND p.bIsPrimary = TRUE 
    AND p.bIsActive = TRUE
LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType
LEFT JOIN S01PHONE p2 ON e.nIdEmployee = p2.nEntityId 
    AND p2.cEntityType = 'EMPLOYEE' 
    AND p2.bIsActive = TRUE
GROUP BY e.nIdEmployee, cEmpName, e.cEmail, co.cBusinessName, pt.cName, p.cPhoneFormatted;

-- ============================================================================

CREATE VIEW V_DIRECTORY AS
SELECT 
    'CLIENT' AS cEntityType,
    cl.nIdClient AS nEntityId,
    cl.cName || ' ' || cl.cLastName AS cEntityName,
    p.cPhoneFormatted,
    pt.cName AS cPhoneType,
    p.bReceiveSMS,
    p.bReceiveWhatsapp,
    p.bIsPrimary
FROM S01CLIENT cl
LEFT JOIN S01PHONE p ON cl.nIdClient = p.nEntityId 
    AND p.cEntityType = 'CLIENT' 
    AND p.bIsActive = TRUE
LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType
WHERE cl.bIsActive = TRUE

UNION ALL

SELECT 
    'EMPLOYEE' AS cEntityType,
    e.nIdEmployee AS nEntityId,
    e.cName || ' ' || e.cLastName AS cEntityName,
    p.cPhoneFormatted,
    pt.cName AS cPhoneType,
    p.bReceiveSMS,
    p.bReceiveWhatsapp,
    p.bIsPrimary
FROM S01EMPLOYEE e
LEFT JOIN S01PHONE p ON e.nIdEmployee = p.nEntityId 
    AND p.cEntityType = 'EMPLOYEE' 
    AND p.bIsActive = TRUE
LEFT JOIN S01PHONE_TYPE pt ON p.nIdPhoneType = pt.nIdPhoneType
WHERE e.bIsActive = TRUE;

-- ============================================================================
-- PASO 14: CONSTRAINT AVANZADO
-- ============================================================================

ALTER TABLE S01CLIENT
ADD CONSTRAINT chk_metadata_valid CHECK (
    CASE WHEN jClientMetadata ? 'nCreditLimit' 
         THEN (jClientMetadata->>'nCreditLimit')::NUMERIC > 0 
         ELSE TRUE 
    END
);

CREATE OR REPLACE FUNCTION fn_check_event_soldout()
RETURNS TRIGGER AS $$
BEGIN
    -- Si las entradas vendidas igualan o superan el máximo del evento
    IF NEW.nSoldTickets >= (SELECT nMaxTicket FROM S01EVENT WHERE nIdEvent = NEW.nIdEvent) THEN
        UPDATE S01EVENT SET cStatus = 'SOLDOUT', tModifiedAt = NOW()
        WHERE nIdEvent = NEW.nIdEvent AND cStatus = 'SCHEDULED';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_event_soldout_monitor
AFTER UPDATE OF nSoldTickets ON S01TICKET_PRICE
FOR EACH ROW EXECUTE FUNCTION fn_check_event_soldout();


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


CREATE OR REPLACE FUNCTION fn_audit_ticket_scan()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.cStatus = 'PAID' AND NEW.cStatus = 'USED') THEN
        NEW.tScannedAt := NOW();
        
        -- Incrementar el contador de la sesión del staff para métricas en vivo
        UPDATE S01STAFF_SESSION 
        SET nScanCount = nScanCount + 1, 
            tLastActivity = NOW()
        WHERE nIdAccessToken = NEW.nIdAccessToken AND bIsActive = TRUE;
    END IF;
    
    -- Bloqueo de re-uso: Si ya está usado, no permitir volver a cambiarlo
    IF (OLD.cStatus = 'USED') THEN
        RAISE EXCEPTION 'ALERTA: Este ticket ya fue utilizado en %', OLD.tScannedAt;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_scan
BEFORE UPDATE ON S01TICKET
FOR EACH ROW EXECUTE FUNCTION fn_audit_ticket_scan();


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

-- Ejecutar cada 5 minutos directamente en la DB
SELECT cron.schedule('*/5 * * * *', 'SELECT fn_cleanup_expired_tickets()');

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

ALTER TABLE S01TICKET 
ALTER COLUMN nIdEvent SET NOT NULL;

-- Y el FK para asegurar que el evento exista
ALTER TABLE S01TICKET
ADD CONSTRAINT fk_ticket_event
FOREIGN KEY (nIdEvent) REFERENCES S01EVENT(nIdEvent);

ALTER TABLE S01EVENT 
ADD COLUMN nMaxStaffSlots INTEGER DEFAULT 5; -- Valor por defecto: 5 porteros

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
