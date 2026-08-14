-- Run this LAST in the Supabase SQL Editor before production.
-- Idempotent wrap-up: grants, overlap protection, visit notes, prescriptions, chat RPC.

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated;
REVOKE ALL ON FUNCTION private.provision_goshens_admin(UUID) FROM PUBLIC;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DO $$
BEGIN
  ALTER TABLE public.appointments
    ADD CONSTRAINT no_overlapping_active_appointments
    EXCLUDE USING gist (
      tstzrange(final_start_at, final_end_at, '[)') WITH &&
    )
    WHERE (status IN ('scheduled', 'checked_in', 'in_consultation') AND final_start_at IS NOT NULL AND final_end_at IS NOT NULL);
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN undefined_object THEN NULL;
END $$;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS related_service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS related_comment_id UUID;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.prescriptions TO authenticated;
GRANT SELECT ON public.prescriptions TO anon;

CREATE OR REPLACE FUNCTION private.touch_appointment_lifecycle()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public AS $$
BEGIN
  IF NEW.status = 'checked_in' AND NEW.check_in_at IS NULL THEN
    NEW.check_in_at := NOW();
  END IF;
  IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
    NEW.completed_at := NOW();
  END IF;
  IF NEW.status = 'cancelled' AND NEW.cancelled_at IS NULL THEN
    NEW.cancelled_at := NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS appointment_lifecycle_times ON public.appointments;
CREATE TRIGGER appointment_lifecycle_times
BEFORE UPDATE ON public.appointments
FOR EACH ROW
EXECUTE PROCEDURE private.touch_appointment_lifecycle();

NOTIFY pgrst, 'reload schema';
