-- Activar extensión pgcrypto para gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ====================================
-- 1. mae_role (sin FK a mae_user inicialmente para evitar dependencia circular)
CREATE TABLE mae_role (
    id_role SERIAL PRIMARY KEY,
    role_name VARCHAR(100) UNIQUE,
    role_code VARCHAR(50) UNIQUE,
    description TEXT,
    permissions JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER,
    updated_by INTEGER,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER
);

CREATE INDEX idx_mae_role_active ON mae_role(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_mae_role_role_code ON mae_role(role_code) WHERE deleted_at IS NULL;

-- ====================================
-- 2. mae_document_type (sin FK a mae_user para evitar dependencia circular)
CREATE TABLE mae_document_type (
    id_document_type SERIAL PRIMARY KEY,
    document_name VARCHAR(100) UNIQUE,
    document_code VARCHAR(20) UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER,
    updated_by INTEGER,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER
);

CREATE INDEX idx_document_type_active ON mae_document_type(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 3. mae_user (Referencia a mae_role y mae_document_type)
CREATE TABLE mae_user (
    id_user SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    password_salt VARCHAR(255),
    id_role INTEGER,
    id_document_type INTEGER,
    document_number VARCHAR(50),
    full_name VARCHAR(255),
    phone VARCHAR(30),
    last_login_at TIMESTAMPTZ,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    email_verified_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER,
    updated_by INTEGER,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER
);

-- Añadir restricciones de clave foránea tras creación para evitar problemas de dependencia cíclica
ALTER TABLE mae_user
    ADD CONSTRAINT fk_mae_user_role FOREIGN KEY (id_role) REFERENCES mae_role(id_role) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_user_document_type FOREIGN KEY (id_document_type) REFERENCES mae_document_type(id_document_type) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_user_created_by FOREIGN KEY (created_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_user_updated_by FOREIGN KEY (updated_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_user_deleted_by FOREIGN KEY (deleted_by) REFERENCES mae_user(id_user) ON DELETE SET NULL;

CREATE INDEX idx_mae_user_email_active ON mae_user(email) WHERE deleted_at IS NULL;

-- ====================================
-- Actualizar mae_role y mae_document_type para FK a mae_user (created_by, updated_by, deleted_by)
ALTER TABLE mae_role
    ADD CONSTRAINT fk_mae_role_created_by FOREIGN KEY (created_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_role_updated_by FOREIGN KEY (updated_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_mae_role_deleted_by FOREIGN KEY (deleted_by) REFERENCES mae_user(id_user) ON DELETE SET NULL;

ALTER TABLE mae_document_type
    ADD CONSTRAINT fk_document_type_created_by FOREIGN KEY (created_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_document_type_updated_by FOREIGN KEY (updated_by) REFERENCES mae_user(id_user) ON DELETE SET NULL,
    ADD CONSTRAINT fk_document_type_deleted_by FOREIGN KEY (deleted_by) REFERENCES mae_user(id_user) ON DELETE SET NULL;

-- ====================================
-- 4. mae_organizer
CREATE TABLE mae_organizer (
    id_organizer SERIAL PRIMARY KEY,
    organizer_name VARCHAR(255),
    organizer_code VARCHAR(50) UNIQUE,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    email VARCHAR(255),
    phone VARCHAR(30),
    address TEXT,
    id_user INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    tax_id VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_organizer_active ON mae_organizer(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 5. mae_event_site
CREATE TABLE mae_event_site (
    id_event_site SERIAL PRIMARY KEY,
    site_name VARCHAR(255),
    site_code VARCHAR(50) UNIQUE,
    description TEXT,
    capacity INTEGER,
    address TEXT,
    city VARCHAR(100),
    state_province VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    facilities JSONB DEFAULT '{}'::jsonb,
    contact_phone VARCHAR(30),
    contact_email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_event_site_active ON mae_event_site(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 6. mae_seat
CREATE TABLE mae_seat (
    id_seat SERIAL PRIMARY KEY,
    id_event_site INTEGER REFERENCES mae_event_site(id_event_site) ON DELETE CASCADE,
    seat_code VARCHAR(50),
    section VARCHAR(50),
    row_name VARCHAR(50),
    seat_number VARCHAR(20),
    seat_type VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    UNIQUE (id_event_site, seat_code)
);

CREATE INDEX idx_mae_seat_active ON mae_seat(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 7. mae_event
CREATE TABLE mae_event (
    id_event SERIAL PRIMARY KEY,
    event_name VARCHAR(255),
    event_code VARCHAR(50) UNIQUE,
    description TEXT,
    event_type VARCHAR(100),
    event_category VARCHAR(100),
    start_datetime TIMESTAMPTZ,
    end_datetime TIMESTAMPTZ,
    id_event_site INTEGER REFERENCES mae_event_site(id_event_site) ON DELETE SET NULL,
    id_organizer INTEGER REFERENCES mae_organizer(id_organizer) ON DELETE SET NULL,
    logo_url VARCHAR(500),
    banner_url VARCHAR(500),
    min_age INTEGER,
    max_capacity INTEGER,
    registration_start_datetime TIMESTAMPTZ,
    registration_end_datetime TIMESTAMPTZ,
    status VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_mae_event_active ON mae_event(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 8. mae_ticket_type
CREATE TABLE mae_ticket_type (
    id_ticket_type SERIAL PRIMARY KEY,
    id_event INTEGER REFERENCES mae_event(id_event) ON DELETE CASCADE,
    ticket_name VARCHAR(100),
    ticket_code VARCHAR(50),
    description TEXT,
    price NUMERIC(12,2),
    currency VARCHAR(10),
    quantity_available INTEGER,
    quantity_sold INTEGER DEFAULT 0,
    max_per_person INTEGER,
    sale_start_datetime TIMESTAMPTZ,
    sale_end_datetime TIMESTAMPTZ,
    is_refundable BOOLEAN DEFAULT FALSE,
    refund_deadline_hours INTEGER,
    benefits JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    UNIQUE (id_event, ticket_code)
);

CREATE INDEX idx_mae_ticket_type_active ON mae_ticket_type(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 9. mae_client
CREATE TABLE mae_client (
    id_client SERIAL PRIMARY KEY,
    full_name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    id_document_type INTEGER REFERENCES mae_document_type(id_document_type) ON DELETE SET NULL,
    document_number VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state_province VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    id_user INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    marketing_consent BOOLEAN,
    newsletter_consent BOOLEAN,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_mae_client_active ON mae_client(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 10. mae_payment_method
CREATE TABLE mae_payment_method (
    id_payment_method SERIAL PRIMARY KEY,
    payment_name VARCHAR(100) UNIQUE,
    payment_code VARCHAR(50) UNIQUE,
    description TEXT,
    provider VARCHAR(100),
    is_online BOOLEAN DEFAULT TRUE,
    processing_fee_percentage NUMERIC(5,2),
    processing_fee_fixed NUMERIC(10,2),
    currency VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_mae_payment_method_active ON mae_payment_method(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 11. trs_ticket
CREATE TABLE trs_ticket (
    id_ticket SERIAL PRIMARY KEY,
    ticket_uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    id_client INTEGER REFERENCES mae_client(id_client) ON DELETE SET NULL,
    id_event INTEGER REFERENCES mae_event(id_event) ON DELETE SET NULL,
    id_ticket_type INTEGER REFERENCES mae_ticket_type(id_ticket_type) ON DELETE SET NULL,
    id_seat INTEGER REFERENCES mae_seat(id_seat) ON DELETE SET NULL,
    ticket_code VARCHAR(100) UNIQUE,
    purchase_datetime TIMESTAMPTZ,
    status VARCHAR(50),
    quantity INTEGER DEFAULT 1,
    unit_price NUMERIC(12, 2),
    total_price NUMERIC(14, 2),
    discount_amount NUMERIC(12, 2),
    tax_amount NUMERIC(12, 2),
    service_fee NUMERIC(12, 2),
    currency VARCHAR(10),
    qr_code_data TEXT,
    used_datetime TIMESTAMPTZ,
    used_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    cancellation_datetime TIMESTAMPTZ,
    cancellation_reason TEXT,
    refund_amount NUMERIC(12, 2),
    refund_processed_datetime TIMESTAMPTZ,
    special_requirements TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_trs_ticket_active ON trs_ticket(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 12. trs_payment
CREATE TABLE trs_payment (
    id_payment SERIAL PRIMARY KEY,
    payment_uuid UUID DEFAULT gen_random_uuid() UNIQUE,
    id_ticket INTEGER REFERENCES trs_ticket(id_ticket) ON DELETE CASCADE,
    id_payment_method INTEGER REFERENCES mae_payment_method(id_payment_method) ON DELETE SET NULL,
    payment_status VARCHAR(50),
    amount NUMERIC(14, 2),
    currency VARCHAR(10),
    processing_fee NUMERIC(14, 2),
    net_amount NUMERIC(14, 2),
    payment_datetime TIMESTAMPTZ,
    payment_gateway_transaction_id VARCHAR(255),
    payment_gateway_response JSONB,
    payment_reference VARCHAR(255),
    refund_amount NUMERIC(14, 2),
    refund_datetime TIMESTAMPTZ,
    refund_reference VARCHAR(255),
    failure_reason TEXT,
    retry_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    updated_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL
);

CREATE INDEX idx_trs_payment_active ON trs_payment(is_active) WHERE deleted_at IS NULL;

-- ====================================
-- 13. audit_log
CREATE TABLE audit_log (
    id_audit BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(255),
    record_id BIGINT,
    operation VARCHAR(20),
    changed_by INTEGER REFERENCES mae_user(id_user) ON DELETE SET NULL,
    change_datetime TIMESTAMPTZ DEFAULT NOW(),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT,
    client_ip INET,
    user_agent TEXT,
    session_id VARCHAR(255)
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_changed_by ON audit_log(changed_by);

ALTER TABLE mae_client
ADD CONSTRAINT unique_client_user UNIQUE (id_user);
