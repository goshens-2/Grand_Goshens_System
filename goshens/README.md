# Goshens Dental Care 🦷

**Goshens Dental Care** is a complete, polished Flutter mobile & web application designed for a single-dentist, single-location dental clinic in Uganda.

---

## 🌟 Application Identity & Architecture

- **Brand Name**: Goshens Dental Care
- **Tagline**: *Creating Perfect Smiles*
- **Primary Target**: Android, iOS, and Web (Chrome).
- **Core User Roles**:
  - **Patient**: Requests appointment date/period, views appointment cards & QR codes, receives prescriptions, chats with clinic, tracks notifications.
  - **Dentist / Admin**: Manages clinic availability periods, approves/schedules requests with exact times, issues & revises prescriptions, scans patient QR codes for check-in, manages published services and patient records.

---

## 🛠️ Technology Stack

- **Framework**: Flutter (Material 3 with custom dental cyan/navy design system)
- **State Management**: Riverpod (`flutter_riverpod` + `riverpod_annotation`)
- **Backend & Database**: Supabase (Auth, PostgreSQL DB, Row Level Security, Storage, Realtime subscriptions)
- **Data Models**: Freezed (`freezed_annotation`) with JSON serialization
- **Document Generation**: `pdf` & `printing` packages for printable appointment cards & official prescriptions
- **QR Code System**: `qr_flutter` (generation) & `mobile_scanner` (scanning) with opaque random tokens

---

## 🔐 Environment Configuration

Copy `.env.example` or create a `.env` file in `c:\Official_Goshens\goshens\.env`:

```env
SUPABASE_URL=https://hhrlxwslzowzbyxmkdpd.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Make sure `assets/` in `pubspec.yaml` includes `.env` and `assets/images/Goshens_logo.png`.

---

## 🗄️ Database Setup & Supabase Migrations

1. Open your **Supabase Dashboard** -> **SQL Editor**.
2. Run `supabase_schema.sql`, then every file in `supabase_migrations/` in this order:
   - `fix_admin_login.sql`
   - `fix_appointment_approval.sql`
   - `fix_avatars_storage.sql`
   - `fix_comments_services_notifications.sql`
   - `fix_chat_and_reject_reason.sql`
   - `fix_chat_rls.sql`
   - `fix_prescriptions.sql`
   - `deploy_ready.sql`
3. In Authentication -> URL configuration, add `http://localhost:8082/reset-password` and your production origin `/reset-password` as redirect URLs.

---

## 👑 Creating the Protected Admin Account

Create `admin@goshens.com` from **Supabase Dashboard -> Authentication -> Users** and set its password there. Never hard-code, commit, or paste an admin password into SQL or the mobile application. All public registrations receive the `patient` role, including a registration using the admin email; the owner must explicitly elevate only the provisioned permanent account from the SQL Editor:

```sql
select private.provision_goshens_admin(id)
from auth.users
where lower(email) = 'admin@goshens.com';
```

The procedure rejects every other email and is not executable by `anon` or `authenticated` users.

The Flutter app uses only `SUPABASE_URL` and the publishable/anon key. Do not add `SUPABASE_SERVICE_ROLE_KEY` to `.env`, Flutter assets, or source control; privileged server actions belong in Supabase Edge Functions.

---

## 🚀 Running the Application

### 1. Navigate to the project root:
```powershell
cd c:\Official_Goshens\goshens
```

### 2. Run on Chrome (Web):
```powershell
# Standard run
flutter run -d chrome

# Run on specific port (e.g. 8080)
flutter run -d chrome --web-port 8080
```

> **Windows Space-in-Path Tip**: If your Windows user folder contains spaces (e.g., `HP ELITEBOOK 1040 G8`), use the 8.3 short path (`HPELIT~1`):
> ```powershell
> C:\Users\HPELIT~1\develop\flutter\bin\flutter.bat run -d chrome
> ```

### 3. Run on Android Device / Emulator:
```powershell
flutter run -d android
```

---

## 🧪 Running Automated Unit Tests

Run the test suite covering role routing, scheduling conflict detection, status transitions, QR security tokens, and auth controller:

```powershell
flutter test
```
