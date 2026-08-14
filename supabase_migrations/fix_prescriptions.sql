-- Run in Supabase SQL Editor so admin can write prescriptions from a patient record.
-- Adds the columns the app uses, allows scripts without an appointment, and enables PDF storage.

ALTER TABLE public.prescriptions
  ALTER COLUMN appointment_id DROP NOT NULL;

ALTER TABLE public.prescriptions
  ADD COLUMN IF NOT EXISTS doctor_name TEXT,
  ADD COLUMN IF NOT EXISTS medications TEXT[] NOT NULL DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS pdf_url TEXT;

ALTER TABLE public.prescriptions
  ALTER COLUMN issued_by_admin_id DROP NOT NULL;

INSERT INTO storage.buckets (id, name, public)
VALUES ('prescriptions', 'prescriptions', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Prescription PDFs are readable" ON storage.objects;
CREATE POLICY "Prescription PDFs are readable"
ON storage.objects FOR SELECT
USING (bucket_id = 'prescriptions');

DROP POLICY IF EXISTS "Admins can upload prescriptions" ON storage.objects;
CREATE POLICY "Admins can upload prescriptions"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'prescriptions'
  AND private.is_admin()
);

DROP POLICY IF EXISTS "Admins can update prescriptions" ON storage.objects;
CREATE POLICY "Admins can update prescriptions"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'prescriptions'
  AND private.is_admin()
)
WITH CHECK (
  bucket_id = 'prescriptions'
  AND private.is_admin()
);

DROP POLICY IF EXISTS "Admins can delete prescriptions" ON storage.objects;
CREATE POLICY "Admins can delete prescriptions"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'prescriptions'
  AND private.is_admin()
);
