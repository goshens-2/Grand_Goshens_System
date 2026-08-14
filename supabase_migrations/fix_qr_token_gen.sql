-- Run this in the Supabase SQL Editor.
-- Fixes: function gen_random_bytes(integer) does not exist
-- when the dentist approves an appointment (QR token creation).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION private.new_secure_token()
RETURNS text
LANGUAGE sql
VOLATILE
SET search_path = public, pg_catalog
AS $$
  SELECT replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
$$;

CREATE OR REPLACE FUNCTION private.ensure_appointment_qr_token()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth, pg_catalog
AS $$
BEGIN
  IF NEW.status = 'scheduled' AND NEW.final_start_at IS NOT NULL THEN
    INSERT INTO public.appointment_qr_tokens (appointment_id, secure_token)
    VALUES (NEW.id, private.new_secure_token())
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

CREATE OR REPLACE FUNCTION public.schedule_appointment(
  p_appointment_id UUID,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_note TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth, pg_catalog
AS $$
DECLARE
  v_patient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;
  IF NOT private.is_admin() THEN
    RAISE EXCEPTION 'Only the clinic admin can schedule appointments.';
  END IF;
  IF p_start IS NULL OR p_end IS NULL OR p_end <= p_start THEN
    RAISE EXCEPTION 'Choose a valid date and time.';
  END IF;

  SELECT patient_id INTO v_patient
  FROM public.appointments
  WHERE id = p_appointment_id;

  IF v_patient IS NULL THEN
    RAISE EXCEPTION 'Appointment not found.';
  END IF;

  BEGIN
    UPDATE public.appointments
    SET
      status = 'scheduled',
      requested_date = (p_start AT TIME ZONE 'Africa/Nairobi')::date,
      final_start_at = p_start,
      final_end_at = p_end,
      dentist_response = COALESCE(NULLIF(trim(p_note), ''), 'Your appointment has been confirmed.'),
      pre_visit_instructions = COALESCE(
        pre_visit_instructions,
        'Please arrive 10 minutes early and bring your appointment QR card for check-in.'
      ),
      rejection_reason = NULL,
      updated_at = NOW()
    WHERE id = p_appointment_id;
  EXCEPTION
    WHEN exclusion_violation THEN
      RAISE EXCEPTION 'That date and time overlaps another appointment. Choose a different slot.';
  END;

  INSERT INTO public.appointment_qr_tokens (appointment_id, secure_token)
  VALUES (p_appointment_id, private.new_secure_token())
  ON CONFLICT (appointment_id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.schedule_appointment(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.schedule_appointment(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) TO authenticated;

NOTIFY pgrst, 'reload schema';
