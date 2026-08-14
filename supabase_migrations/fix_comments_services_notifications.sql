-- Run in Supabase SQL Editor.
-- Service images, moderated comments, and reliable appointment/comment notifications.

ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS image_paths JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS icon_name TEXT NOT NULL DEFAULT 'medical_services';

UPDATE public.services
SET image_paths = jsonb_build_array(image_path)
WHERE image_path IS NOT NULL
  AND image_path <> ''
  AND (image_paths = '[]'::jsonb OR image_paths IS NULL);

CREATE TABLE IF NOT EXISTS public.service_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  author_name TEXT NOT NULL DEFAULT 'Patient',
  author_avatar_path TEXT,
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_comments_status ON public.service_comments(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_comments_service ON public.service_comments(service_id, status);

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS related_service_id UUID REFERENCES public.services(id) ON DELETE SET NULL;
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS related_comment_id UUID REFERENCES public.service_comments(id) ON DELETE SET NULL;

ALTER TABLE public.service_comments ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.service_comments TO authenticated;
GRANT SELECT ON public.service_comments TO anon;

DROP POLICY IF EXISTS "Anyone can read approved comments" ON public.service_comments;
CREATE POLICY "Anyone can read approved comments"
ON public.service_comments FOR SELECT
USING (
  status = 'approved'
  OR patient_id = auth.uid()
  OR private.is_admin()
);

DROP POLICY IF EXISTS "Patients can submit comments" ON public.service_comments;
CREATE POLICY "Patients can submit comments"
ON public.service_comments FOR INSERT
TO authenticated
WITH CHECK (
  patient_id = auth.uid()
  AND status = 'pending'
  AND length(trim(body)) > 0
);

DROP POLICY IF EXISTS "Admin can manage comments" ON public.service_comments;
CREATE POLICY "Admin can manage comments"
ON public.service_comments FOR ALL
USING (private.is_admin())
WITH CHECK (private.is_admin());

CREATE OR REPLACE FUNCTION private.snapshot_comment_author()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
DECLARE
  profile_name TEXT;
  profile_avatar TEXT;
BEGIN
  SELECT full_name, avatar_path
  INTO profile_name, profile_avatar
  FROM public.profiles
  WHERE id = NEW.patient_id;

  NEW.author_name := COALESCE(NULLIF(profile_name, ''), 'Patient');
  NEW.author_avatar_path := profile_avatar;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS snapshot_comment_author ON public.service_comments;
CREATE TRIGGER snapshot_comment_author
BEFORE INSERT ON public.service_comments
FOR EACH ROW
EXECUTE PROCEDURE private.snapshot_comment_author();

CREATE OR REPLACE FUNCTION private.notify_admins(
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_appointment_id UUID DEFAULT NULL,
  p_service_id UUID DEFAULT NULL,
  p_comment_id UUID DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
BEGIN
  INSERT INTO public.notifications (
    recipient_id, type, title, body,
    related_appointment_id, related_service_id, related_comment_id
  )
  SELECT
    ur.user_id, p_type, p_title, p_body,
    p_appointment_id, p_service_id, p_comment_id
  FROM public.user_roles ur
  WHERE ur.role = 'admin';
END;
$$;

REVOKE ALL ON FUNCTION private.notify_admins(TEXT, TEXT, TEXT, UUID, UUID, UUID) FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.handle_appointment_notifications()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
DECLARE
  service_name TEXT;
  patient_name TEXT;
BEGIN
  SELECT name INTO service_name FROM public.services WHERE id = NEW.service_id;
  SELECT full_name INTO patient_name FROM public.profiles WHERE id = NEW.patient_id;

  IF TG_OP = 'INSERT' AND NEW.status = 'pending_review' THEN
    PERFORM private.notify_admins(
      'new_booking',
      'New appointment request',
      COALESCE(patient_name, 'A patient') || ' requested ' || COALESCE(service_name, 'a service') ||
        ' for ' || NEW.requested_date::text || '.',
      NEW.id,
      NEW.service_id,
      NULL
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    IF NEW.status IN ('scheduled', 'approved') THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.notifications
        WHERE recipient_id = NEW.patient_id
          AND related_appointment_id = NEW.id
          AND type IN ('appointment_confirmed', 'appointment_update')
          AND created_at > NOW() - INTERVAL '2 minutes'
      ) THEN
        INSERT INTO public.notifications (recipient_id, type, title, body, related_appointment_id, related_service_id)
        VALUES (
          NEW.patient_id,
          'appointment_confirmed',
          'Appointment confirmed',
          'Your ' || COALESCE(service_name, 'dental') ||
            ' appointment has been confirmed. Open your appointment card for the QR code.',
          NEW.id,
          NEW.service_id
        );
      END IF;
    ELSIF NEW.status IN ('rejected', 'cancelled') THEN
      INSERT INTO public.notifications (recipient_id, type, title, body, related_appointment_id, related_service_id)
      VALUES (
        NEW.patient_id,
        'appointment_update',
        'Appointment ' || replace(NEW.status::text, '_', ' '),
        COALESCE(NEW.dentist_response, 'Your appointment was ' || replace(NEW.status::text, '_', ' ') || '.'),
        NEW.id,
        NEW.service_id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS appointment_notifications ON public.appointments;
CREATE TRIGGER appointment_notifications
AFTER INSERT OR UPDATE OF status ON public.appointments
FOR EACH ROW
EXECUTE PROCEDURE private.handle_appointment_notifications();

CREATE OR REPLACE FUNCTION private.handle_comment_notifications()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, auth AS $$
DECLARE
  service_name TEXT;
BEGIN
  SELECT name INTO service_name FROM public.services WHERE id = NEW.service_id;

  IF TG_OP = 'INSERT' THEN
    PERFORM private.notify_admins(
      'comment_submitted',
      'New service comment',
      NEW.author_name || ' commented on ' || COALESCE(service_name, 'a service') ||
        '. Approve it before it appears on the home page.',
      NULL,
      NEW.service_id,
      NEW.id
    );
  ELSIF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    IF NEW.status = 'approved' THEN
      INSERT INTO public.notifications (recipient_id, type, title, body, related_service_id, related_comment_id)
      VALUES (
        NEW.patient_id,
        'comment_approved',
        'Your comment was published',
        'Your comment on ' || COALESCE(service_name, 'a service') || ' is now visible on the home page.',
        NEW.service_id,
        NEW.id
      );
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO public.notifications (recipient_id, type, title, body, related_service_id, related_comment_id)
      VALUES (
        NEW.patient_id,
        'comment_rejected',
        'Comment not published',
        'Your comment on ' || COALESCE(service_name, 'a service') || ' was not approved.',
        NEW.service_id,
        NEW.id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS comment_notifications ON public.service_comments;
CREATE TRIGGER comment_notifications
AFTER INSERT OR UPDATE OF status ON public.service_comments
FOR EACH ROW
EXECUTE PROCEDURE private.handle_comment_notifications();

INSERT INTO storage.buckets (id, name, public)
VALUES ('service-images', 'service-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Service images are publicly accessible" ON storage.objects;
CREATE POLICY "Service images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'service-images');

DROP POLICY IF EXISTS "Admins can upload service images" ON storage.objects;
CREATE POLICY "Admins can upload service images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'service-images' AND private.is_admin());

DROP POLICY IF EXISTS "Admins can update service images" ON storage.objects;
CREATE POLICY "Admins can update service images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'service-images' AND private.is_admin())
WITH CHECK (bucket_id = 'service-images' AND private.is_admin());

DROP POLICY IF EXISTS "Admins can delete service images" ON storage.objects;
CREATE POLICY "Admins can delete service images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'service-images' AND private.is_admin());

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_comments;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
END $$;

NOTIFY pgrst, 'reload schema';
