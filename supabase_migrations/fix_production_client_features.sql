-- Run in Supabase SQL Editor.
-- Client notification isolation, clear/mark-read RPCs, chat delete, admin schedule by date+time.

-- ---------------------------------------------------------------------------
-- Notifications: a client may only ever see / change their own rows.
-- Admin "FOR ALL" previously leaked every patient's notifications to any
-- session that passed is_admin(), and also let the Realtime stream dump
-- the whole table to the device. SELECT is now recipient-only.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admin has full access to notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;

CREATE POLICY "Users can view own notifications"
ON public.notifications FOR SELECT
USING (auth.uid() = recipient_id);

CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
USING (auth.uid() = recipient_id)
WITH CHECK (auth.uid() = recipient_id);

CREATE POLICY "Users can delete own notifications"
ON public.notifications FOR DELETE
USING (auth.uid() = recipient_id);

CREATE POLICY "Admins can insert notifications"
ON public.notifications FOR INSERT
TO authenticated
WITH CHECK (private.is_admin() OR auth.uid() = recipient_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
DECLARE
  n integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  UPDATE public.notifications
  SET is_read = TRUE
  WHERE recipient_id = auth.uid()
    AND COALESCE(is_read, FALSE) = FALSE;

  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;

CREATE OR REPLACE FUNCTION public.clear_all_notifications()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
DECLARE
  n integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  DELETE FROM public.notifications
  WHERE recipient_id = auth.uid();

  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_notification(p_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  DELETE FROM public.notifications
  WHERE id = p_id
    AND recipient_id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.mark_all_notifications_read() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.clear_all_notifications() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_notification(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;
GRANT EXECUTE ON FUNCTION public.clear_all_notifications() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_notification(UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- Admin can assign any date + time when confirming a request.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.schedule_appointment(
  p_appointment_id UUID,
  p_start TIMESTAMPTZ,
  p_end TIMESTAMPTZ,
  p_note TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
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
  VALUES (p_appointment_id, replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
  ON CONFLICT (appointment_id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.schedule_appointment(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.schedule_appointment(UUID, TIMESTAMPTZ, TIMESTAMPTZ, TEXT) TO authenticated;

-- ---------------------------------------------------------------------------
-- Chat: soft-delete messages, delete/clear conversations.
-- ---------------------------------------------------------------------------
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_by UUID;

DROP POLICY IF EXISTS "Participants can delete messages" ON public.messages;
CREATE POLICY "Participants can delete messages"
ON public.messages FOR DELETE
USING (
  private.is_admin()
  OR sender_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id AND c.patient_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Patients can delete own conversation" ON public.conversations;
CREATE POLICY "Patients can delete own conversation"
ON public.conversations FOR DELETE
USING (auth.uid() = patient_id OR private.is_admin());

CREATE OR REPLACE FUNCTION public.delete_chat_message(p_message_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  UPDATE public.messages m
  SET
    deleted_at = NOW(),
    deleted_by = auth.uid(),
    content = '',
    media_path = NULL
  WHERE m.id = p_message_id
    AND m.deleted_at IS NULL
    AND (
      private.is_admin()
      OR m.sender_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = m.conversation_id AND c.patient_id = auth.uid()
      )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.clear_conversation(p_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  IF NOT (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = p_conversation_id AND c.patient_id = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  UPDATE public.messages
  SET deleted_at = NOW(), deleted_by = auth.uid(), content = '', media_path = NULL
  WHERE conversation_id = p_conversation_id
    AND deleted_at IS NULL;

  UPDATE public.conversations
  SET last_message_preview = 'Chat cleared', updated_at = NOW()
  WHERE id = p_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_conversation(p_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not signed in';
  END IF;

  IF NOT (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = p_conversation_id AND c.patient_id = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  DELETE FROM public.conversations WHERE id = p_conversation_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_chat_message(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.clear_conversation(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_conversation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_chat_message(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.clear_conversation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_conversation(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
