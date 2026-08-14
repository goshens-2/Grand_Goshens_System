-- Run in Supabase SQL Editor so approval can create QR cards reliably.

GRANT SELECT, INSERT, UPDATE, DELETE ON public.appointment_qr_tokens TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT ON public.appointment_status_history TO authenticated;

CREATE OR REPLACE FUNCTION private.ensure_appointment_qr_token()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth, pg_catalog
AS $$
BEGIN
  IF NEW.status = 'scheduled' AND NEW.final_start_at IS NOT NULL THEN
    INSERT INTO public.appointment_qr_tokens (appointment_id, secure_token)
    VALUES (NEW.id, replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
    ON CONFLICT (appointment_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS ensure_appointment_qr_token ON public.appointments;
CREATE TRIGGER ensure_appointment_qr_token
AFTER INSERT OR UPDATE OF status, final_start_at ON public.appointments
FOR EACH ROW
EXECUTE PROCEDURE private.ensure_appointment_qr_token();
