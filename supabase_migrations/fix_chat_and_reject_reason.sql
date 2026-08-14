-- Run in Supabase SQL Editor.
-- WhatsApp-style clinic chat (text/images/videos/files) + conversation policies.

ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS last_message_preview TEXT,
  ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_sender_id UUID;

ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text',
  ADD COLUMN IF NOT EXISTS media_path TEXT,
  ADD COLUMN IF NOT EXISTS media_mime TEXT,
  ADD COLUMN IF NOT EXISTS media_size BIGINT,
  ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

ALTER TABLE public.messages ALTER COLUMN content DROP NOT NULL;
ALTER TABLE public.messages ALTER COLUMN content SET DEFAULT '';
UPDATE public.messages SET content = '' WHERE content IS NULL;

DO $$
BEGIN
  ALTER TABLE public.messages
    ADD CONSTRAINT messages_type_check
    CHECK (message_type IN ('text', 'image', 'video', 'file'));
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;

DROP POLICY IF EXISTS "Patients can view own conversation" ON public.conversations;
CREATE POLICY "Patients can view own conversation"
ON public.conversations FOR SELECT
USING (auth.uid() = patient_id OR private.is_admin());

DROP POLICY IF EXISTS "Patients can create own conversation" ON public.conversations;
CREATE POLICY "Patients can create own conversation"
ON public.conversations FOR INSERT
WITH CHECK (auth.uid() = patient_id);

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

CREATE OR REPLACE FUNCTION private.handle_new_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
DECLARE
  conv public.conversations%ROWTYPE;
  preview TEXT;
  patient_name TEXT;
BEGIN
  preview := CASE NEW.message_type
    WHEN 'image' THEN 'Photo'
    WHEN 'video' THEN 'Video'
    WHEN 'file' THEN 'File'
    ELSE COALESCE(NULLIF(btrim(NEW.content), ''), 'Message')
  END;

  UPDATE public.conversations
  SET
    updated_at = NOW(),
    last_message_preview = preview,
    last_message_at = NEW.created_at,
    last_sender_id = NEW.sender_id
  WHERE id = NEW.conversation_id
  RETURNING * INTO conv;

  SELECT full_name INTO patient_name FROM public.profiles WHERE id = conv.patient_id;

  IF NEW.sender_id = conv.patient_id THEN
    INSERT INTO public.notifications (
      recipient_id, type, title, body, related_conversation_id
    )
    SELECT
      ur.user_id,
      'new_message',
      COALESCE(NULLIF(patient_name, ''), 'Patient'),
      preview,
      conv.id
    FROM public.user_roles ur
    WHERE ur.role = 'admin';
  ELSE
    INSERT INTO public.notifications (
      recipient_id, type, title, body, related_conversation_id
    )
    VALUES (
      conv.patient_id,
      'new_message',
      'Goshens Clinic',
      preview,
      conv.id
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS message_inserted ON public.messages;
CREATE TRIGGER message_inserted
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE PROCEDURE private.handle_new_message();

INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-media', 'chat-media', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "Chat media readable by participants" ON storage.objects;
CREATE POLICY "Chat media readable by participants"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'chat-media'
  AND (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND c.patient_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Chat media upload by participants" ON storage.objects;
CREATE POLICY "Chat media upload by participants"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media'
  AND (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND c.patient_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS "Chat media update by participants" ON storage.objects;
CREATE POLICY "Chat media update by participants"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'chat-media'
  AND (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND c.patient_id = auth.uid()
    )
  )
)
WITH CHECK (
  bucket_id = 'chat-media'
  AND (
    private.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[1]
        AND c.patient_id = auth.uid()
    )
  )
);

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
END $$;

NOTIFY pgrst, 'reload schema';
