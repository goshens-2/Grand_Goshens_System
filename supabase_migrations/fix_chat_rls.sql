-- Run in Supabase SQL Editor.
-- Fixes: "new row violates row-level security policy for table messages"
-- Cause: opening chat marks the other person's messages as read, but RLS only
-- allowed updates when sender_id = auth.uid().

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;

DROP POLICY IF EXISTS "Patients can view own conversation" ON public.conversations;
CREATE POLICY "Patients can view own conversation"
ON public.conversations FOR SELECT
USING (auth.uid() = patient_id OR private.is_admin());

DROP POLICY IF EXISTS "Patients can create own conversation" ON public.conversations;
CREATE POLICY "Patients can create own conversation"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = patient_id OR private.is_admin());

DROP POLICY IF EXISTS "Patients can update own conversation" ON public.conversations;
CREATE POLICY "Patients can update own conversation"
ON public.conversations FOR UPDATE
USING (auth.uid() = patient_id OR private.is_admin())
WITH CHECK (auth.uid() = patient_id OR private.is_admin());

DROP POLICY IF EXISTS "Admin has full access to conversations" ON public.conversations;
CREATE POLICY "Admin has full access to conversations"
ON public.conversations FOR ALL
USING (private.is_admin())
WITH CHECK (private.is_admin());

DROP POLICY IF EXISTS "Patients can view/send own messages" ON public.messages;
DROP POLICY IF EXISTS "Admin has full access to messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can read messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can update messages" ON public.messages;

CREATE POLICY "Participants can read messages"
ON public.messages FOR SELECT
USING (
  private.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id AND c.patient_id = auth.uid()
  )
);

CREATE POLICY "Participants can send messages"
ON public.messages FOR INSERT
WITH CHECK (
  sender_id = auth.uid()
  AND (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id AND c.patient_id = auth.uid()
    )
  )
);

CREATE POLICY "Participants can update messages"
ON public.messages FOR UPDATE
USING (
  private.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id AND c.patient_id = auth.uid()
  )
)
WITH CHECK (
  private.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id AND c.patient_id = auth.uid()
  )
);

CREATE OR REPLACE FUNCTION private.mark_conversation_read(p_conversation_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
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
  SET
    is_read = TRUE,
    read_at = COALESCE(read_at, NOW()),
    delivered_at = COALESCE(delivered_at, NOW())
  WHERE conversation_id = p_conversation_id
    AND sender_id IS DISTINCT FROM auth.uid()
    AND COALESCE(is_read, FALSE) = FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_conversation_read(p_conversation_id UUID)
RETURNS void
LANGUAGE sql
SECURITY INVOKER
SET search_path = private, public AS $$
  SELECT private.mark_conversation_read(p_conversation_id);
$$;

REVOKE ALL ON FUNCTION private.mark_conversation_read(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_conversation_read(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.mark_conversation_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_conversation_read(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
