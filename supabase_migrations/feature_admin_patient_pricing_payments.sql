-- Run in the Supabase SQL Editor.
-- Adds everything needed for:
--   * Admin "add patient" flow (full demographics + login credentials)
--   * Service pricing used by the "Doctor's use only" screen and QR payments
--   * A doctor-only passcode for the pricing / payment records screens
--   * Payment records + running balance per patient
--   * Distinguishing "doctor registered" patients from self sign-ups, and
--     making "Patients enrolled" only count accounts created from now on.

-- 1. Patient profile additions -------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS registration_source TEXT NOT NULL DEFAULT 'self';

-- Anything that already existed before this migration is "legacy" so the
-- "Patients enrolled" analytics card only counts accounts created from now on.
UPDATE public.profiles SET registration_source = 'legacy' WHERE registration_source = 'self';

-- 2. Service pricing ------------------------------------------------------------
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS price NUMERIC(10, 2) NOT NULL DEFAULT 0;

-- 3. Doctor-only passcode (single row) ------------------------------------------
CREATE TABLE IF NOT EXISTS public.doctor_lock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passcode_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.doctor_lock ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin only can access the doctor lock" ON public.doctor_lock;
CREATE POLICY "Admin only can access the doctor lock" ON public.doctor_lock
  FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

-- 4. Payments ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
    service_name TEXT,
    service_price NUMERIC(10, 2) NOT NULL DEFAULT 0,
    amount_paid NUMERIC(10, 2) NOT NULL DEFAULT 0,
    balance_after NUMERIC(10, 2) NOT NULL DEFAULT 0,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS payments_patient_service_idx ON public.payments (patient_id, service_id, created_at DESC);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin has full access to payments" ON public.payments;
CREATE POLICY "Admin has full access to payments" ON public.payments
  FOR ALL USING (private.is_admin()) WITH CHECK (private.is_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctor_lock TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO authenticated;

-- 5. Extend the new-user trigger so admin-entered demographics (and email /
--    registration source) are saved on sign up, whether the account was
--    created by a patient or entered by the doctor/admin.
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (
    id, full_name, avatar_path, email, phone, gender, address,
    emergency_contact, allergies_or_notes, registration_source
  )
  VALUES (
    new.id,
    COALESCE(NULLIF(trim(new.raw_user_meta_data->>'full_name'), ''), 'New Patient'),
    new.raw_user_meta_data->>'avatar_path',
    COALESCE(NULLIF(trim(new.raw_user_meta_data->>'email'), ''), new.email),
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'gender',
    new.raw_user_meta_data->>'address',
    new.raw_user_meta_data->>'emergency_contact',
    new.raw_user_meta_data->>'allergies_or_notes',
    COALESCE(NULLIF(trim(new.raw_user_meta_data->>'registration_source'), ''), 'self')
  )
  ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_roles (user_id, role) VALUES (new.id, 'patient')
    ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO public.conversations (patient_id) VALUES (new.id)
  ON CONFLICT (patient_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = private, public, auth;

NOTIFY pgrst, 'reload schema';
