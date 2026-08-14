-- Bootstrap Goshens schema + fix admin sign-in
-- Run this entire file once in Supabase SQL Editor.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('patient', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.appointment_status AS ENUM (
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
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL DEFAULT 'patient',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profiles (
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

CREATE TABLE IF NOT EXISTS public.clinic_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_name TEXT NOT NULL DEFAULT 'Goshens Dental Care',
  tagline TEXT NOT NULL DEFAULT 'Creating Perfect Smiles',
  address TEXT NOT NULL,
  dentist_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  working_days_hours JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.dentist_availability_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  day_of_week INTEGER NOT NULL,
  period_name TEXT NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(day_of_week, period_name)
);

CREATE TABLE IF NOT EXISTS public.availability_exceptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exception_date DATE NOT NULL UNIQUE,
  is_closed BOOLEAN DEFAULT TRUE,
  special_start_time TIME,
  special_end_time TIME,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.services (
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

CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
  appointment_reference TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 8)),
  requested_date DATE NOT NULL,
  preferred_period TEXT NOT NULL,
  patient_note TEXT,
  status public.appointment_status NOT NULL DEFAULT 'pending_review',
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

CREATE TABLE IF NOT EXISTS public.appointment_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  changed_by_id UUID NOT NULL REFERENCES auth.users(id),
  old_status public.appointment_status,
  new_status public.appointment_status NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.appointment_qr_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE UNIQUE,
  secure_token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  used_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_reference TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 10)),
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE RESTRICT,
  issued_by_admin_id UUID NOT NULL REFERENCES auth.users(id),
  instructions TEXT,
  additional_notes TEXT,
  revision_of_id UUID REFERENCES public.prescriptions(id),
  revision_number INTEGER DEFAULT 1,
  pdf_path TEXT,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.prescription_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id UUID NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  duration TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  related_prescription_id UUID REFERENCES public.prescriptions(id) ON DELETE SET NULL,
  related_conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.visit_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE UNIQUE,
  consultation_summary TEXT,
  treatment_performed TEXT,
  follow_up_recommendation TEXT,
  follow_up_date DATE,
  internal_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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

  INSERT INTO public.user_roles (user_id, role)
  VALUES (new.id, 'patient')
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.conversations (patient_id)
  VALUES (new.id)
  ON CONFLICT (patient_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = private, public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE private.handle_new_user();

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dentist_availability_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability_exceptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_qr_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visit_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own role" ON public.user_roles;
CREATE POLICY "Users can view own role" ON public.user_roles FOR SELECT
USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admin has full access to roles" ON public.user_roles;
CREATE POLICY "Admin has full access to roles" ON public.user_roles FOR ALL
USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Admin has full access to profiles" ON public.profiles;
CREATE POLICY "Admin has full access to profiles" ON public.profiles FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Anyone can view clinic settings" ON public.clinic_settings;
CREATE POLICY "Anyone can view clinic settings" ON public.clinic_settings FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admin has full access to clinic settings" ON public.clinic_settings;
CREATE POLICY "Admin has full access to clinic settings" ON public.clinic_settings FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Anyone can view availability" ON public.dentist_availability_periods;
CREATE POLICY "Anyone can view availability" ON public.dentist_availability_periods FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admin has full access to availability" ON public.dentist_availability_periods;
CREATE POLICY "Admin has full access to availability" ON public.dentist_availability_periods FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Anyone can view availability exceptions" ON public.availability_exceptions;
CREATE POLICY "Anyone can view availability exceptions" ON public.availability_exceptions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Admin has full access to exceptions" ON public.availability_exceptions;
CREATE POLICY "Admin has full access to exceptions" ON public.availability_exceptions FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Anyone can view published services" ON public.services;
CREATE POLICY "Anyone can view published services" ON public.services FOR SELECT USING (is_published = true OR private.is_admin());
DROP POLICY IF EXISTS "Admin has full access to services" ON public.services;
CREATE POLICY "Admin has full access to services" ON public.services FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own appointments" ON public.appointments;
CREATE POLICY "Patients can view own appointments" ON public.appointments FOR SELECT USING (auth.uid() = patient_id);
DROP POLICY IF EXISTS "Patients can create appointments" ON public.appointments;
CREATE POLICY "Patients can create appointments" ON public.appointments FOR INSERT WITH CHECK (auth.uid() = patient_id AND status = 'pending_review');
DROP POLICY IF EXISTS "Patients can cancel own future appointments" ON public.appointments;
CREATE POLICY "Patients can cancel own future appointments" ON public.appointments FOR UPDATE
USING (auth.uid() = patient_id) WITH CHECK (auth.uid() = patient_id AND status = 'cancelled');
DROP POLICY IF EXISTS "Admin has full access to appointments" ON public.appointments;
CREATE POLICY "Admin has full access to appointments" ON public.appointments FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own appointment history" ON public.appointment_status_history;
CREATE POLICY "Patients can view own appointment history" ON public.appointment_status_history FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.appointments a WHERE a.id = appointment_id AND a.patient_id = auth.uid())
);
DROP POLICY IF EXISTS "Admin has full access to status history" ON public.appointment_status_history;
CREATE POLICY "Admin has full access to status history" ON public.appointment_status_history FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own QR tokens" ON public.appointment_qr_tokens;
CREATE POLICY "Patients can view own QR tokens" ON public.appointment_qr_tokens FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.appointments a WHERE a.id = appointment_id AND a.patient_id = auth.uid())
);
DROP POLICY IF EXISTS "Admin has full access to QR tokens" ON public.appointment_qr_tokens;
CREATE POLICY "Admin has full access to QR tokens" ON public.appointment_qr_tokens FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own conversation" ON public.conversations;
CREATE POLICY "Patients can view own conversation" ON public.conversations FOR SELECT USING (auth.uid() = patient_id);
DROP POLICY IF EXISTS "Admin has full access to conversations" ON public.conversations;
CREATE POLICY "Admin has full access to conversations" ON public.conversations FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view/send own messages" ON public.messages;
CREATE POLICY "Patients can view/send own messages" ON public.messages FOR ALL USING (
  EXISTS (SELECT 1 FROM public.conversations c WHERE c.id = conversation_id AND c.patient_id = auth.uid())
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.conversations c WHERE c.id = conversation_id AND c.patient_id = auth.uid())
  AND auth.uid() = sender_id
);
DROP POLICY IF EXISTS "Admin has full access to messages" ON public.messages;
CREATE POLICY "Admin has full access to messages" ON public.messages FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = recipient_id);
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = recipient_id);
DROP POLICY IF EXISTS "Admin has full access to notifications" ON public.notifications;
CREATE POLICY "Admin has full access to notifications" ON public.notifications FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own prescriptions" ON public.prescriptions;
CREATE POLICY "Patients can view own prescriptions" ON public.prescriptions FOR SELECT USING (auth.uid() = patient_id);
DROP POLICY IF EXISTS "Admin has full access to prescriptions" ON public.prescriptions;
CREATE POLICY "Admin has full access to prescriptions" ON public.prescriptions FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view own prescription items" ON public.prescription_items;
CREATE POLICY "Patients can view own prescription items" ON public.prescription_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.prescriptions p WHERE p.id = prescription_id AND p.patient_id = auth.uid())
);
DROP POLICY IF EXISTS "Admin has full access to prescription items" ON public.prescription_items;
CREATE POLICY "Admin has full access to prescription items" ON public.prescription_items FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Admin only can view and edit visit notes" ON public.visit_notes;
CREATE POLICY "Admin only can view and edit visit notes" ON public.visit_notes FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

INSERT INTO public.clinic_settings (clinic_name, tagline, address, dentist_name, phone, email, working_days_hours)
SELECT
  'Goshens Dental Care',
  'Creating Perfect Smiles',
  '123 Main St, Kampala, Uganda',
  'Dr. Example',
  '+256 123 456 789',
  'info@goshens.com',
  '{"Monday - Friday": "9:00 AM - 5:00 PM", "Saturday": "9:00 AM - 1:00 PM"}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.clinic_settings);

INSERT INTO public.services (name, description, estimated_duration_minutes, is_published, sort_order)
SELECT * FROM (
  VALUES
    ('General Checkup', 'Comprehensive dental examination to ensure your oral health.', 30, true, 1),
    ('Teeth Cleaning', 'Professional cleaning to remove plaque and tartar.', 45, true, 2),
    ('Tooth Extraction', 'Safe and painless removal of problematic teeth.', 60, true, 3),
    ('Teeth Whitening', 'Cosmetic procedure to brighten your smile.', 60, true, 4)
) AS seed(name, description, estimated_duration_minutes, is_published, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.services);

INSERT INTO public.dentist_availability_periods (day_of_week, period_name, start_time, end_time)
SELECT * FROM (
  VALUES
    (1, 'Morning', TIME '09:00', TIME '12:00'), (1, 'Afternoon', TIME '14:00', TIME '17:00'),
    (2, 'Morning', TIME '09:00', TIME '12:00'), (2, 'Afternoon', TIME '14:00', TIME '17:00'),
    (3, 'Morning', TIME '09:00', TIME '12:00'), (3, 'Afternoon', TIME '14:00', TIME '17:00'),
    (4, 'Morning', TIME '09:00', TIME '12:00'), (4, 'Afternoon', TIME '14:00', TIME '17:00'),
    (5, 'Morning', TIME '09:00', TIME '12:00'), (5, 'Afternoon', TIME '14:00', TIME '17:00'),
    (6, 'Morning', TIME '09:00', TIME '13:00')
) AS seed(day_of_week, period_name, start_time, end_time)
WHERE NOT EXISTS (SELECT 1 FROM public.dentist_availability_periods);

UPDATE auth.users
SET
  confirmation_token = COALESCE(confirmation_token, ''),
  email_change = COALESCE(email_change, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  recovery_token = COALESCE(recovery_token, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, '')
WHERE lower(email) = 'admin@goshens.com';

UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE lower(email) = 'admin@goshens.com'
  AND email_confirmed_at IS NULL;

INSERT INTO auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  gen_random_uuid(),
  u.id,
  u.id::text,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  COALESCE(u.last_sign_in_at, NOW()),
  COALESCE(u.created_at, NOW()),
  COALESCE(u.updated_at, NOW())
FROM auth.users u
WHERE lower(u.email) = 'admin@goshens.com'
  AND NOT EXISTS (
    SELECT 1
    FROM auth.identities i
    WHERE i.user_id = u.id
      AND i.provider = 'email'
  );

INSERT INTO public.profiles (id, full_name)
SELECT u.id, 'Goshens Admin'
FROM auth.users u
WHERE lower(u.email) = 'admin@goshens.com'
ON CONFLICT (id) DO UPDATE
SET full_name = COALESCE(NULLIF(trim(public.profiles.full_name), ''), EXCLUDED.full_name);

INSERT INTO public.conversations (patient_id)
SELECT u.id
FROM auth.users u
WHERE lower(u.email) = 'admin@goshens.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.conversations c WHERE c.patient_id = u.id
  );

SELECT private.provision_goshens_admin(u.id)
FROM auth.users u
WHERE lower(u.email) = 'admin@goshens.com';
