-- =============================================================================
-- Goshens Dental Care — handover wipe (run ONCE in the Supabase SQL Editor)
-- =============================================================================
-- Irreversible. Makes the live database look brand-new for the client.
--
-- KEEPS
--   • Schema, RLS, functions, triggers, storage buckets
--   • Permanent admin: admin@goshens.com (auth user, role, profile)
--   • clinic_settings, dentist_availability_periods, published services
--   • Service catalog images in storage bucket "service-images"
--
-- DELETES
--   • Every other Auth user (test patients) and their profiles
--   • Appointments, QR tokens, status history, visit notes
--   • Prescriptions and prescription items
--   • Chat conversations / messages
--   • Notifications
--   • Service comments
--   • Availability exceptions (test holidays / special days)
--   • Uploaded files: empty these in Dashboard → Storage (SQL cannot delete them):
--       avatars, chat-media, prescriptions
--     Leave service-images (clinic catalog photos).
--
-- After this, sign in as admin@goshens.com only. Patients register fresh.
-- =============================================================================

DO $$
DECLARE
  v_admin_id UUID;
  v_admin_email TEXT := 'admin@goshens.com';
BEGIN
  SELECT id
  INTO v_admin_id
  FROM auth.users
  WHERE lower(email) = v_admin_email
  LIMIT 1;

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION
      'Aborting wipe: % was not found. Provision the admin account first.',
      v_admin_email;
  END IF;

  RAISE NOTICE 'Wiping test data. Keeping admin % (%)', v_admin_email, v_admin_id;

  -- Operational rows first (FKs that would block user deletes).
  TRUNCATE TABLE
    public.prescription_items,
    public.prescriptions,
    public.notifications,
    public.visit_notes,
    public.appointment_qr_tokens,
    public.appointment_status_history,
    public.messages,
    public.conversations,
    public.appointments,
    public.service_comments,
    public.availability_exceptions
    RESTART IDENTITY;

  -- Test patient profiles / roles. Admin row stays.
  DELETE FROM public.profiles
  WHERE id <> v_admin_id;

  DELETE FROM public.user_roles
  WHERE user_id <> v_admin_id
    AND role IS DISTINCT FROM 'admin';

  -- Safety: admin must remain admin.
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_admin_id, 'admin')
  ON CONFLICT (user_id) DO UPDATE SET role = 'admin';

  UPDATE public.profiles
  SET
    avatar_path = NULL,
    phone = NULL,
    date_of_birth = NULL,
    gender = NULL,
    address = NULL,
    emergency_contact = NULL,
    allergies_or_notes = NULL,
    updated_at = NOW()
  WHERE id = v_admin_id;

  -- Storage files cannot be deleted from SQL (Supabase protect_delete).
  -- Empty buckets avatars, chat-media, and prescriptions in the Dashboard.

  -- Auth accounts except the permanent admin.
  -- user_id is uuid on some tables and varchar on others (refresh_tokens).
  -- Optional tables vary by Auth version; skip if they are not present.
  BEGIN
    DELETE FROM auth.identities WHERE user_id::text <> v_admin_id::text;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;

  BEGIN
    DELETE FROM auth.sessions WHERE user_id::text <> v_admin_id::text;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;

  BEGIN
    DELETE FROM auth.refresh_tokens WHERE user_id::text <> v_admin_id::text;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;

  BEGIN
    DELETE FROM auth.mfa_factors WHERE user_id::text <> v_admin_id::text;
  EXCEPTION WHEN undefined_table OR undefined_column THEN
    NULL;
  END;

  DELETE FROM auth.users
  WHERE id <> v_admin_id;

  RAISE NOTICE 'Wipe complete.';
END
$$;

-- Quick confirmation. Admin should be 1; transactional tables should be 0.
SELECT 'auth.users' AS item, COUNT(*)::bigint AS remaining FROM auth.users
UNION ALL
SELECT 'user_roles', COUNT(*) FROM public.user_roles
UNION ALL
SELECT 'profiles', COUNT(*) FROM public.profiles
UNION ALL
SELECT 'appointments', COUNT(*) FROM public.appointments
UNION ALL
SELECT 'conversations', COUNT(*) FROM public.conversations
UNION ALL
SELECT 'messages', COUNT(*) FROM public.messages
UNION ALL
SELECT 'notifications', COUNT(*) FROM public.notifications
UNION ALL
SELECT 'prescriptions', COUNT(*) FROM public.prescriptions
UNION ALL
SELECT 'service_comments', COUNT(*) FROM public.service_comments
UNION ALL
SELECT 'availability_exceptions', COUNT(*) FROM public.availability_exceptions
UNION ALL
SELECT 'clinic_settings', COUNT(*) FROM public.clinic_settings
UNION ALL
SELECT 'services', COUNT(*) FROM public.services
UNION ALL
SELECT 'availability_periods', COUNT(*) FROM public.dentist_availability_periods
UNION ALL
SELECT 'storage.objects (empty avatars/chat-media/prescriptions in Dashboard)', COUNT(*)
FROM storage.objects
WHERE bucket_id IN ('avatars', 'chat-media', 'prescriptions')
ORDER BY 1;
