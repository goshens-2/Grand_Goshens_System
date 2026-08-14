-- Goshens Dental Care App - Supabase Schema & Policies

-- 1. Enable pgcrypto for UUID generation if needed
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

-- 3. Tables

CREATE TYPE app_role AS ENUM ('patient', 'admin');

-- Roles are server-managed. Patients can read only their own role and cannot
-- create, update, or delete role assignments through the Data API.
CREATE TABLE user_roles (
        user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
        role app_role NOT NULL DEFAULT 'patient',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CHECK (role <> 'admin' OR user_id IS NOT NULL)
);

CREATE OR REPLACE FUNCTION private.is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = private, public, auth AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    );
$$;

REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated;

-- This procedure is intentionally not callable by authenticated users. Run it
-- only from the Supabase SQL Editor as the project owner after provisioning the
-- permanent admin account in Supabase Auth.
CREATE OR REPLACE FUNCTION private.provision_goshens_admin(admin_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth, pg_catalog AS $$
DECLARE
    admin_email TEXT;
BEGIN
    SELECT lower(email) INTO admin_email
    FROM auth.users
    WHERE id = admin_user_id;

    IF admin_email IS DISTINCT FROM 'admin@goshens.com' THEN
        RAISE EXCEPTION 'Only the permanent Goshens admin account can receive the admin role';
    END IF;

    INSERT INTO public.user_roles (user_id, role)
    VALUES (admin_user_id, 'admin')
    ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;
END;
$$;

REVOKE ALL ON FUNCTION private.provision_goshens_admin(UUID) FROM PUBLIC;

-- PROFILES
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    date_of_birth DATE,
    gender TEXT,
    address TEXT,
    emergency_contact TEXT,
    allergies_or_notes TEXT,
    avatar_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- CLINIC SETTINGS (Single row expected)
CREATE TABLE clinic_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clinic_name TEXT NOT NULL DEFAULT 'Goshens Dental Care',
    tagline TEXT NOT NULL DEFAULT 'Creating Perfect Smiles',
    address TEXT NOT NULL,
    dentist_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    working_days_hours JSONB, -- E.g. {"Monday": "9:00 AM - 5:00 PM"}
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DENTIST AVAILABILITY PERIODS
CREATE TABLE dentist_availability_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    day_of_week INTEGER NOT NULL, -- 1=Monday, 7=Sunday
    period_name TEXT NOT NULL, -- e.g. "Morning", "Afternoon"
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(day_of_week, period_name)
);

-- AVAILABILITY EXCEPTIONS (Holidays, Leaves, Special working days)
CREATE TABLE availability_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exception_date DATE NOT NULL,
    is_closed BOOLEAN DEFAULT TRUE,
    special_start_time TIME,
    special_end_time TIME,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(exception_date)
);

-- SERVICES
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    image_path TEXT,
    estimated_duration_minutes INTEGER,
    preparation_instructions TEXT,
    is_published BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- APPOINTMENTS
CREATE TYPE appointment_status AS ENUM (
    'pending_review',
    'approved',
    'scheduled',
    'checked_in',
    'in_consultation',
    'completed',
    'rejected',
    'cancelled',
    'no_show'
);

CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    appointment_reference TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 8)),
    requested_date DATE NOT NULL,
    preferred_period TEXT NOT NULL, -- "Morning", "Afternoon"
    patient_note TEXT,
    status appointment_status NOT NULL DEFAULT 'pending_review',
    final_start_at TIMESTAMPTZ,
    final_end_at TIMESTAMPTZ,
    dentist_response TEXT,
    rejection_reason TEXT,
    pre_visit_instructions TEXT,
    check_in_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE appointments ADD CONSTRAINT scheduled_appointments_require_times
CHECK (
    status NOT IN ('scheduled', 'checked_in', 'in_consultation', 'completed', 'no_show')
    OR (final_start_at IS NOT NULL AND final_end_at IS NOT NULL AND final_end_at > final_start_at)
);

ALTER TABLE appointments ADD CONSTRAINT no_overlapping_active_appointments
EXCLUDE USING gist (
    tstzrange(final_start_at, final_end_at, '[)') WITH &&
) WHERE (status IN ('scheduled', 'checked_in', 'in_consultation'));

-- APPOINTMENT STATUS HISTORY
CREATE TABLE appointment_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    changed_by_id UUID NOT NULL REFERENCES auth.users(id),
    old_status appointment_status,
    new_status appointment_status NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- APPOINTMENT QR TOKENS (For secure check-in without PII)
CREATE TABLE appointment_qr_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE UNIQUE,
    secure_token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    used_at TIMESTAMPTZ
);

-- CONVERSATIONS (One per patient to clinic)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- MESSAGES
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- NOTIFICATIONS
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- e.g., 'appointment_update', 'new_message', 'prescription'
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    related_appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    related_prescription_id UUID, -- Will reference prescriptions table once created
    related_conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PRESCRIPTIONS
CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_reference TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 10)),
    patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE RESTRICT,
    issued_by_admin_id UUID NOT NULL REFERENCES auth.users(id),
    instructions TEXT,
    additional_notes TEXT,
    revision_of_id UUID REFERENCES prescriptions(id),
    revision_number INTEGER DEFAULT 1,
    pdf_path TEXT,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PRESCRIPTION ITEMS (if you want structured medicines instead of just text instructions)
CREATE TABLE prescription_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    duration TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE notifications ADD CONSTRAINT fk_notifications_prescription FOREIGN KEY (related_prescription_id) REFERENCES prescriptions(id) ON DELETE SET NULL;

-- VISIT NOTES (Internal dentist notes)
CREATE TABLE visit_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE UNIQUE,
    consultation_summary TEXT,
    treatment_performed TEXT,
    follow_up_recommendation TEXT,
    follow_up_date DATE,
    internal_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION private.enforce_patient_appointment_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = private, public, auth AS $$
BEGIN
    IF private.is_admin() THEN
        RETURN NEW;
    END IF;

    IF OLD.patient_id <> auth.uid()
         OR OLD.status NOT IN ('pending_review', 'approved', 'scheduled')
         OR NEW.status <> 'cancelled'
         OR NEW.patient_id IS DISTINCT FROM OLD.patient_id
         OR NEW.service_id IS DISTINCT FROM OLD.service_id
         OR NEW.requested_date IS DISTINCT FROM OLD.requested_date
         OR NEW.preferred_period IS DISTINCT FROM OLD.preferred_period
         OR NEW.patient_note IS DISTINCT FROM OLD.patient_note
         OR NEW.final_start_at IS DISTINCT FROM OLD.final_start_at
         OR NEW.final_end_at IS DISTINCT FROM OLD.final_end_at
         OR NEW.dentist_response IS DISTINCT FROM OLD.dentist_response
         OR NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason
         OR NEW.pre_visit_instructions IS DISTINCT FROM OLD.pre_visit_instructions
         OR NEW.check_in_at IS DISTINCT FROM OLD.check_in_at
         OR NEW.completed_at IS DISTINCT FROM OLD.completed_at
    THEN
        RAISE EXCEPTION 'Patients may only cancel their own pending or future appointments';
    END IF;

    NEW.cancelled_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER enforce_patient_appointment_update
BEFORE UPDATE ON appointments
FOR EACH ROW EXECUTE PROCEDURE private.enforce_patient_appointment_update();


-- 4. Enable Row Level Security
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clinic_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE dentist_availability_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_qr_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE visit_notes ENABLE ROW LEVEL SECURITY;


-- 5. RLS Policies

CREATE POLICY "Users can view own role" ON user_roles FOR SELECT
USING (auth.uid() = user_id);
CREATE POLICY "Admin has full access to roles" ON user_roles FOR ALL
USING (private.is_admin()) WITH CHECK (private.is_admin());

-- PROFILES
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admin has full access to profiles" ON profiles FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- CLINIC SETTINGS
CREATE POLICY "Anyone can view clinic settings" ON clinic_settings FOR SELECT USING (true);
CREATE POLICY "Admin has full access to clinic settings" ON clinic_settings FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- DENTIST AVAILABILITY PERIODS & EXCEPTIONS
CREATE POLICY "Anyone can view availability" ON dentist_availability_periods FOR SELECT USING (true);
CREATE POLICY "Admin has full access to availability" ON dentist_availability_periods FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

CREATE POLICY "Anyone can view availability exceptions" ON availability_exceptions FOR SELECT USING (true);
CREATE POLICY "Admin has full access to exceptions" ON availability_exceptions FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- SERVICES
CREATE POLICY "Anyone can view published services" ON services FOR SELECT USING (is_published = true OR private.is_admin());
CREATE POLICY "Admin has full access to services" ON services FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- APPOINTMENTS
CREATE POLICY "Patients can view own appointments" ON appointments FOR SELECT USING (auth.uid() = patient_id);
CREATE POLICY "Patients can create appointments" ON appointments FOR INSERT WITH CHECK (auth.uid() = patient_id AND status = 'pending_review');
CREATE POLICY "Patients can cancel own future appointments" ON appointments FOR UPDATE
USING (auth.uid() = patient_id) WITH CHECK (auth.uid() = patient_id AND status = 'cancelled');
CREATE POLICY "Admin has full access to appointments" ON appointments FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- APPOINTMENT STATUS HISTORY
CREATE POLICY "Patients can view own appointment history" ON appointment_status_history FOR SELECT USING (
    EXISTS (SELECT 1 FROM appointments a WHERE a.id = appointment_id AND a.patient_id = auth.uid())
);
CREATE POLICY "Admin has full access to status history" ON appointment_status_history FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- APPOINTMENT QR TOKENS
CREATE POLICY "Patients can view own QR tokens" ON appointment_qr_tokens FOR SELECT USING (
    EXISTS (SELECT 1 FROM appointments a WHERE a.id = appointment_id AND a.patient_id = auth.uid())
);
CREATE POLICY "Admin has full access to QR tokens" ON appointment_qr_tokens FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- CONVERSATIONS
CREATE POLICY "Patients can view own conversation" ON conversations FOR SELECT USING (auth.uid() = patient_id);
CREATE POLICY "Admin has full access to conversations" ON conversations FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- MESSAGES
CREATE POLICY "Patients can view/send own messages" ON messages FOR ALL USING (
    EXISTS (SELECT 1 FROM conversations c WHERE c.id = conversation_id AND c.patient_id = auth.uid())
) WITH CHECK (
    EXISTS (SELECT 1 FROM conversations c WHERE c.id = conversation_id AND c.patient_id = auth.uid())
    AND auth.uid() = sender_id
);
CREATE POLICY "Admin has full access to messages" ON messages FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- NOTIFICATIONS
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = recipient_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = recipient_id);
CREATE POLICY "Admin has full access to notifications" ON notifications FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- PRESCRIPTIONS
CREATE POLICY "Patients can view own prescriptions" ON prescriptions FOR SELECT USING (auth.uid() = patient_id);
CREATE POLICY "Admin has full access to prescriptions" ON prescriptions FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

CREATE POLICY "Patients can view own prescription items" ON prescription_items FOR SELECT USING (
    EXISTS (SELECT 1 FROM prescriptions p WHERE p.id = prescription_id AND p.patient_id = auth.uid())
);
CREATE POLICY "Admin has full access to prescription items" ON prescription_items FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- VISIT NOTES
CREATE POLICY "Admin only can view and edit visit notes" ON visit_notes FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT role::text
  FROM public.user_roles
  WHERE user_id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;

GRANT SELECT ON public.user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;


-- 6. Trigger for Profile Creation and server-managed role assignment
-- Automatically creates patient records when a user signs up via Supabase Auth.
-- Admin elevation is deliberately separate from public registration.
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_path)
  VALUES (
    new.id,
    COALESCE(NULLIF(trim(new.raw_user_meta_data->>'full_name'), ''), 'New Patient'),
    new.raw_user_meta_data->>'avatar_path'
  )
  ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_roles (user_id, role) VALUES (new.id, 'patient')
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO public.conversations (patient_id) VALUES (new.id)
  ON CONFLICT (patient_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = private, public, auth;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE private.handle_new_user();


-- 7. Realtime Replication
-- Enable realtime for tables that need it
ALTER PUBLICATION supabase_realtime ADD TABLE appointments, messages, notifications, appointment_qr_tokens;


-- 8. Seed Data (Optional for Demo)
INSERT INTO clinic_settings (clinic_name, tagline, address, dentist_name, phone, email, working_days_hours)
VALUES (
    'Goshens Dental Care', 
    'Creating Perfect Smiles', 
    '123 Main St, Kampala, Uganda', 
    'Dr. Example', 
    '+256 123 456 789', 
    'info@goshens.com', 
    '{"Monday - Friday": "9:00 AM - 5:00 PM", "Saturday": "9:00 AM - 1:00 PM"}'
);

INSERT INTO services (name, description, estimated_duration_minutes, is_published, sort_order)
VALUES 
('General Checkup', 'Comprehensive dental examination to ensure your oral health.', 30, true, 1),
('Teeth Cleaning', 'Professional cleaning to remove plaque and tartar.', 45, true, 2),
('Tooth Extraction', 'Safe and painless removal of problematic teeth.', 60, true, 3),
('Teeth Whitening', 'Cosmetic procedure to brighten your smile.', 60, true, 4);

INSERT INTO dentist_availability_periods (day_of_week, period_name, start_time, end_time)
VALUES 
(1, 'Morning', '09:00:00', '12:00:00'), (1, 'Afternoon', '14:00:00', '17:00:00'),
(2, 'Morning', '09:00:00', '12:00:00'), (2, 'Afternoon', '14:00:00', '17:00:00'),
(3, 'Morning', '09:00:00', '12:00:00'), (3, 'Afternoon', '14:00:00', '17:00:00'),
(4, 'Morning', '09:00:00', '12:00:00'), (4, 'Afternoon', '14:00:00', '17:00:00'),
(5, 'Morning', '09:00:00', '12:00:00'), (5, 'Afternoon', '14:00:00', '17:00:00'),
(6, 'Morning', '09:00:00', '13:00:00');

-- 9. Storage Buckets (You will need to run these manually in SQL editor as well, or via Dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
-- INSERT INTO storage.buckets (id, name, public) VALUES ('prescriptions', 'prescriptions', false);

-- And you would need Storage RLS policies similar to table RLS.
