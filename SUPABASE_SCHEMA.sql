-- ==============================================================================
-- S-IMPEL DIGITAL : SKEMA DATABASE LENGKAP & SUPABASE REALTIME
-- Sistem Penilaian Digital & Voting Berbayar Terpadu
-- ==============================================================================
-- Petunjuk:
-- 1. Buka dashboard proyek Supabase Anda (https://supabase.com).
-- 2. Masuk ke menu "SQL Editor" di bilah navigasi kiri.
-- 3. Tempelkan seluruh isi file ini, lalu klik tombol "Run".
-- ==============================================================================

-- 1. TABEL PENGGUNA (USERS)
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL DEFAULT '123#',
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'VOTER' CHECK (role IN ('SUPER_ADMIN', 'SHADOW_ADMIN', 'JURY', 'VOTER', 'PUBLIC')),
  phone TEXT,
  email TEXT,
  assigned_category_ids JSONB DEFAULT '[]'::jsonb,
  vote_balance NUMERIC DEFAULT 0,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 2. TABEL PENGATURAN UMUM APLIKASI (APP SETTINGS)
CREATE TABLE IF NOT EXISTS public.app_settings (
  id TEXT PRIMARY KEY DEFAULT 'current_settings',
  competition_title TEXT NOT NULL DEFAULT 'FESTIVAL & KOMPETISI KREATIF NASIONAL 2026',
  competition_subtitle TEXT NOT NULL DEFAULT 'S-IMPEL DIGITAL: Sistem Penilaian Digital & Voting Berbayar Terpadu',
  competition_description TEXT NOT NULL DEFAULT 'Ajang bergengsi tingkat nasional yang mempertemukan talenta-talenta terbaik dari seluruh nusantara dalam berbagai bidang keahlian digital, vokasi, dan orasi kebangsaan. Seluruh proses penjurian menggunakan teknologi S-IMPEL DIGITAL demi menjamin transparansi, keadilan, dan kecepatan hasil.',
  location TEXT NOT NULL DEFAULT 'Auditorium Utama Graha Teknologi & Seni Nusantara, Gedung B',
  event_date_time TEXT NOT NULL DEFAULT '14 - 16 November 2026 | 08.00 - 17.30 WIB',
  theme_color TEXT NOT NULL DEFAULT 'gold',
  background_image_url TEXT DEFAULT '',
  logo_url TEXT DEFAULT '',
  video_promo_url TEXT DEFAULT 'https://www.youtube.com/embed/dQw4w9WgXcQ',
  bgm_audio_url TEXT DEFAULT '',
  bgm_file_name TEXT DEFAULT '',
  bgm_enabled BOOLEAN DEFAULT true,
  bgm_volume NUMERIC DEFAULT 0.35,
  voting_enabled BOOLEAN DEFAULT true,
  dana_transfer_enabled BOOLEAN DEFAULT true,
  dana_target_number TEXT NOT NULL DEFAULT '081314420312',
  dana_target_name TEXT NOT NULL DEFAULT 'PANITIA S-IMPEL DIGITAL (OFFICIAL)',
  default_price_per_vote NUMERIC DEFAULT 1000,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 3. TABEL INFORMASI PUBLIK & JADWAL (PUBLIC EVENT INFO)
CREATE TABLE IF NOT EXISTS public.public_info (
  id TEXT PRIMARY KEY DEFAULT 'current_public_info',
  title TEXT NOT NULL DEFAULT 'FESTIVAL & KOMPETISI KREATIF DIGITAL NASIONAL',
  sub_title TEXT NOT NULL DEFAULT 'Menembus Batas Kreativitas dengan Semangat Sportivitas & Integritas',
  event_description TEXT NOT NULL DEFAULT 'Ajang bergengsi tingkat nasional yang mempertemukan talenta-talenta terbaik dari seluruh nusantara dalam berbagai bidang keahlian digital, vokasi, dan orasi kebangsaan. Seluruh proses penjurian menggunakan teknologi S-IMPEL DIGITAL demi menjamin transparansi, keadilan, dan kecepatan hasil.',
  location TEXT NOT NULL DEFAULT 'Auditorium Utama & Kompleks Laboratorium Terpadu Graha Sains Nusantara',
  event_date TEXT NOT NULL DEFAULT '14 s/d 16 November 2026',
  contact_person TEXT NOT NULL DEFAULT 'Helpdesk Panitia: 0813-1442-0312 (WhatsApp Resmi)',
  rules_overview JSONB DEFAULT '[]'::jsonb,
  schedule_overview JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 4. TABEL KATEGORI PERLOMBAAN (COMPETITION CATEGORIES)
CREATE TABLE IF NOT EXISTS public.competition_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  location TEXT DEFAULT '',
  schedule_time TEXT DEFAULT '',
  max_duration_minutes INTEGER DEFAULT 180,
  rules JSONB DEFAULT '[]'::jsonb,
  assigned_jury_ids JSONB DEFAULT '[]'::jsonb,
  criteria JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 5. TABEL PESERTA LOMBA (PARTICIPANTS)
CREATE TABLE IF NOT EXISTS public.participants (
  id TEXT PRIMARY KEY,
  registration_number TEXT NOT NULL,
  name TEXT NOT NULL,
  institution TEXT NOT NULL,
  category_id TEXT NOT NULL REFERENCES public.competition_categories(id) ON DELETE CASCADE,
  contact TEXT DEFAULT '',
  photo_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 6. TABEL FORMULIR PENILAIAN JURI (JURY SCORE SUBMISSIONS)
CREATE TABLE IF NOT EXISTS public.jury_submissions (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  participant_id TEXT NOT NULL REFERENCES public.participants(id) ON DELETE CASCADE,
  jury_id TEXT NOT NULL,
  jury_name TEXT NOT NULL,
  criteria_scores JSONB NOT NULL DEFAULT '{}'::jsonb,
  penalties JSONB DEFAULT '[]'::jsonb,
  total_score NUMERIC NOT NULL DEFAULT 0,
  time_completion_seconds NUMERIC NOT NULL DEFAULT 0,
  signature_data_url TEXT DEFAULT '',
  integrity_pact_accepted BOOLEAN DEFAULT true,
  notes TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  admin_notes TEXT DEFAULT '',
  submitted_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 7. TABEL KATEGORI VOTING (VOTING CATEGORIES)
CREATE TABLE IF NOT EXISTS public.voting_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  price_per_vote NUMERIC DEFAULT 1000,
  is_active BOOLEAN DEFAULT true,
  candidates JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- 8. TABEL TRANSAKSI VOTING VIA DANA (VOTE TRANSACTIONS)
CREATE TABLE IF NOT EXISTS public.vote_transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  user_phone TEXT NOT NULL,
  sender_name TEXT,
  amount_votes INTEGER NOT NULL,
  total_price_idr NUMERIC NOT NULL,
  dana_account_number TEXT NOT NULL DEFAULT '081314420312',
  transfer_proof_url TEXT NOT NULL,
  reference_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()),
  verified_at TIMESTAMPTZ
);

-- 9. TABEL HISTORI PEMBERIAN VOTE (VOTE CASTS)
CREATE TABLE IF NOT EXISTS public.vote_casts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  candidate_id TEXT NOT NULL,
  candidate_name TEXT NOT NULL,
  voting_category_id TEXT NOT NULL,
  votes_given INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW())
);

-- ==============================================================================
-- AKTIFKAN SUPABASE REALTIME SUBSCRIPTIONS
-- ==============================================================================
-- Memastikan perubahan tabel terkirim LVE TIME ke semua browser client secara otomatis:
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE
    public.users,
    public.app_settings,
    public.public_info,
    public.competition_categories,
    public.participants,
    public.jury_submissions,
    public.voting_categories,
    public.vote_transactions,
    public.vote_casts;
COMMIT;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
-- Pengaturan akses agar web app statis / multi-user dapat membaca dan memodifikasi data.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competition_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jury_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voting_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vote_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vote_casts ENABLE ROW LEVEL SECURITY;

-- Kebijakan Akses Terbuka untuk Anon/Authenticated Client:
CREATE POLICY "Public Read All Users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Public Manage Users" ON public.users FOR ALL USING (true);

CREATE POLICY "Public Read Settings" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "Public Manage Settings" ON public.app_settings FOR ALL USING (true);

CREATE POLICY "Public Read Info" ON public.public_info FOR SELECT USING (true);
CREATE POLICY "Public Manage Info" ON public.public_info FOR ALL USING (true);

CREATE POLICY "Public Read Categories" ON public.competition_categories FOR SELECT USING (true);
CREATE POLICY "Public Manage Categories" ON public.competition_categories FOR ALL USING (true);

CREATE POLICY "Public Read Participants" ON public.participants FOR SELECT USING (true);
CREATE POLICY "Public Manage Participants" ON public.participants FOR ALL USING (true);

CREATE POLICY "Public Read Submissions" ON public.jury_submissions FOR SELECT USING (true);
CREATE POLICY "Public Manage Submissions" ON public.jury_submissions FOR ALL USING (true);

CREATE POLICY "Public Read Voting Categories" ON public.voting_categories FOR SELECT USING (true);
CREATE POLICY "Public Manage Voting Categories" ON public.voting_categories FOR ALL USING (true);

CREATE POLICY "Public Read Transactions" ON public.vote_transactions FOR SELECT USING (true);
CREATE POLICY "Public Manage Transactions" ON public.vote_transactions FOR ALL USING (true);

CREATE POLICY "Public Read Vote Casts" ON public.vote_casts FOR SELECT USING (true);
CREATE POLICY "Public Manage Vote Casts" ON public.vote_casts FOR ALL USING (true);

-- ==============================================================================
-- SEED DATA AWAL (DEFAULT ADMINISTRATOR & INITIAL DATA)
-- ==============================================================================

-- Akun Super Admin Bawaan
INSERT INTO public.users (id, username, password, name, role, phone, email, vote_balance)
VALUES
  ('usr-admin-1', 'Usseradmin', '123#', 'Muhamad Hidayatullah (Super Admin)', 'SUPER_ADMIN', '081314420312', 'admin.utama@simpel-digital.id', 0),
  ('usr-shadow-1', 'coadmin1', '123#', 'Rian Pratama (Admin Operasional)', 'SHADOW_ADMIN', '081234567890', 'operasional@simpel-digital.id', 0),
  ('usr-jury-1', 'juri_ahmad', '123#', 'Dr. Ir. Ahmad Syahrul, M.Kom', 'JURY', '081211112222', NULL, 0),
  ('usr-voter-1', 'voter_andri', '123#', 'Andri Wijaya (Pendukung SMK 1)', 'VOTER', '085712345678', NULL, 25)
ON CONFLICT (id) DO NOTHING;

-- Pengaturan Awal
INSERT INTO public.app_settings (
  id, competition_title, competition_subtitle, competition_description,
  location, event_date_time, theme_color, dana_target_number, dana_target_name, default_price_per_vote
) VALUES (
  'current_settings',
  'FESTIVAL & KOMPETISI KREATIF NASIONAL 2026',
  'S-IMPEL DIGITAL: Sistem Penilaian Digital & Voting Berbayar Terpadu',
  'Ajang bergengsi tingkat nasional yang mempertemukan talenta-talenta terbaik dari seluruh nusantara dalam berbagai bidang keahlian digital, vokasi, dan orasi kebangsaan. Seluruh proses penjurian menggunakan teknologi S-IMPEL DIGITAL demi menjamin transparansi, keadilan, dan kecepatan hasil.',
  'Auditorium Utama Graha Teknologi & Seni Nusantara, Gedung B',
  '14 - 16 November 2026 | 08.00 - 17.30 WIB',
  'gold',
  '081314420312',
  'PANITIA S-IMPEL DIGITAL (OFFICIAL)',
  1000
) ON CONFLICT (id) DO NOTHING;

-- Informasi Publik
INSERT INTO public.public_info (
  id, title, sub_title, event_description, location, event_date, contact_person
) VALUES (
  'current_public_info',
  'FESTIVAL & KOMPETISI KREATIF DIGITAL NASIONAL',
  'Menembus Batas Kreativitas dengan Semangat Sportivitas & Integritas',
  'Ajang bergengsi tingkat nasional yang mempertemukan talenta-talenta terbaik dari seluruh nusantara dalam berbagai bidang keahlian digital, vokasi, dan orasi kebangsaan. Seluruh proses penjurian menggunakan teknologi S-IMPEL DIGITAL demi menjamin transparansi, keadilan, dan kecepatan hasil.',
  'Auditorium Utama & Kompleks Laboratorium Terpadu Graha Sains Nusantara',
  '14 s/d 16 November 2026',
  'Helpdesk Panitia: 0813-1442-0312 (WhatsApp Resmi)'
) ON CONFLICT (id) DO NOTHING;

-- Kategori Lomba Bawaan
INSERT INTO public.competition_categories (id, name, description, location, schedule_time, max_duration_minutes, assigned_jury_ids, criteria)
VALUES
  ('cat-web', 'Desain & Pengembangan Web Kreatif', 'Kompetisi pembuatan aplikasi web responsif bertema Digitalisasi Edukasi & Kewirausahaan Siswa.', 'Lab Komputer 1 & 2', '14 Nov 2026, 08:30 - 12:00 WIB', 180, '["usr-jury-1"]'::jsonb, '[{"id":"crit-1","name":"UI/UX & Desain Visual Responsif","type":"CHECKBOX","maxScore":10},{"id":"crit-2","name":"Kualitas Kode & Struktur Arsitektur","type":"NUMBER","maxScore":100}]'::jsonb),
  ('cat-pidato', 'Pidato Kebangsaan & Public Speaking', 'Ajang penyampaian orasi inspiratif pemuda bertema Semangat Kebhinekaan di Era Digital.', 'Panggung Utama Auditorium', '14 Nov 2026, 13:00 - 16:30 WIB', 10, '["usr-jury-1"]'::jsonb, '[{"id":"crit-p1","name":"Artikulasi & Intonasi","type":"CHECKBOX","maxScore":10},{"id":"crit-p2","name":"Struktur Konten & Kedalaman","type":"NUMBER","maxScore":100}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Peserta Bawaan
INSERT INTO public.participants (id, registration_number, name, institution, category_id, contact)
VALUES
  ('part-w1', 'WEB-001', 'Bintang Alamsyah & Tim', 'SMKN 1 Jakarta Raya', 'cat-web', '081299990001'),
  ('part-w2', 'WEB-002', 'Anisa Rahmawati', 'SMKN 2 Bandung', 'cat-web', '081299990002')
ON CONFLICT (id) DO NOTHING;

-- Kategori Voting Bawaan
INSERT INTO public.voting_categories (id, name, description, price_per_vote, is_active, candidates)
VALUES
  ('vote-cat-fav-web', 'Kandidat Web & Inovasi Terfavorit Pilihan Publik', 'Dukung karya karya terbaik siswa pilihan Anda untuk dinobatkan sebagai Juara Favorit Pemirsa!', 1000, true, '[{"id":"cand-1","name":"Bintang Alamsyah (WEB-001)","subtitle":"Proyek: E-Smart Portal Siswa Terpadu","institution":"SMKN 1 Jakarta Raya","photoUrl":"https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80","votesCount":120}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
