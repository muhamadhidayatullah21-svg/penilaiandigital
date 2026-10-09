import { createClient, SupabaseClient } from '@supabase/supabase-js';
import {
  AppSettings,
  CompetitionCategory,
  JuryScoreSubmission,
  Participant,
  PublicEventInfo,
  User,
  VoteCast,
  VoteTransaction,
  VotingCategory
} from '../types';

export interface SupabaseConfig {
  url: string;
  anonKey: string;
}

const DEFAULT_SUPABASE_URL = 'https://bmanpqbgoxiqvhbmejyp.supabase.co';
const DEFAULT_SUPABASE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtYW5wcWJnb3hpcXZoYm1lanlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NjM1MTAsImV4cCI6MjEwNzEzOTUxMH0.xhvYz9YmxFWmJSi-foR5FNxXwbVrI2h6J-dhoGTVNfk';

export function cleanSupabaseUrl(rawUrl: string): string {
  if (!rawUrl) return '';
  return rawUrl.trim().replace(/\/rest\/v1\/?$/i, '').replace(/\/+$/, '');
}

const STORAGE_KEY_URL = 'simpel_supabase_url';
const STORAGE_KEY_KEY = 'simpel_supabase_anon_key';

let cachedClient: SupabaseClient | null = null;
let activeChannel: any = null;

export const SupabaseService = {
  getConfig(): SupabaseConfig {
    if (typeof window === 'undefined') {
      return { url: DEFAULT_SUPABASE_URL, anonKey: DEFAULT_SUPABASE_KEY };
    }
    const envUrl = (import.meta as any).env?.VITE_SUPABASE_URL || '';
    const envKey = (import.meta as any).env?.VITE_SUPABASE_ANON_KEY || '';

    const storedUrl = localStorage.getItem(STORAGE_KEY_URL) || '';
    const storedKey = localStorage.getItem(STORAGE_KEY_KEY) || '';

    const finalUrl = cleanSupabaseUrl(storedUrl || envUrl || DEFAULT_SUPABASE_URL);
    const finalKey = (storedKey || envKey || DEFAULT_SUPABASE_KEY).trim();

    return {
      url: finalUrl,
      anonKey: finalKey
    };
  },

  isConfigured(): boolean {
    const config = this.getConfig();
    return Boolean(config.url && config.anonKey && config.url.startsWith('http'));
  },

  setConfig(url: string, anonKey: string): void {
    if (typeof window !== 'undefined') {
      const sanitized = cleanSupabaseUrl(url);
      localStorage.setItem(STORAGE_KEY_URL, sanitized);
      localStorage.setItem(STORAGE_KEY_KEY, anonKey.trim());
    }
    cachedClient = null; // Reset client
    if (activeChannel) {
      activeChannel.unsubscribe();
      activeChannel = null;
    }
  },

  clearConfig(): void {
    if (typeof window !== 'undefined') {
      localStorage.removeItem(STORAGE_KEY_URL);
      localStorage.removeItem(STORAGE_KEY_KEY);
    }
    cachedClient = null;
    if (activeChannel) {
      activeChannel.unsubscribe();
      activeChannel = null;
    }
  },

  getClient(): SupabaseClient | null {
    if (cachedClient) return cachedClient;
    const config = this.getConfig();
    if (!config.url || !config.anonKey) return null;

    try {
      cachedClient = createClient(config.url, config.anonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true
        },
        realtime: {
          params: {
            eventsPerSecond: 10
          }
        }
      });
      return cachedClient;
    } catch (e) {
      console.error('Gagal inisialisasi Supabase client:', e);
      return null;
    }
  },

  async testConnection(): Promise<{ success: boolean; message: string }> {
    const client = this.getClient();
    if (!client) {
      return {
        success: false,
        message: 'Kredensial URL & Anon Key Supabase belum diisi atau tidak valid.'
      };
    }

    try {
      // Test querying app_settings or users
      const { data, error } = await client.from('app_settings').select('id').limit(1);
      if (error) {
        // Check if table not found
        if (error.code === '42P01') {
          return {
            success: false,
            message: `Tabel belum ada di Supabase. Silakan jalankan script SQL Schema di SQL Editor Supabase terlebih dahulu. (Error: ${error.message})`
          };
        }
        return {
          success: false,
          message: `Gagal terhubung: ${error.message}`
        };
      }
      return {
        success: true,
        message: 'Koneksi ke Supabase PostgreSQL berhasil! Realtime subscriptions siap digunakan.'
      };
    } catch (err: any) {
      return {
        success: false,
        message: `Terjadi kendala jaringan: ${err.message || 'Gagal menghubungi server'}`
      };
    }
  },

  // Sinkronisasi data dari lokal ke Supabase
  async pushLocalDataToSupabase(payload: {
    settings: AppSettings;
    publicInfo: PublicEventInfo;
    categories: CompetitionCategory[];
    participants: Participant[];
    submissions: JuryScoreSubmission[];
    votingCategories: VotingCategory[];
    transactions: VoteTransaction[];
    users: User[];
  }): Promise<{ success: boolean; message: string }> {
    const client = this.getClient();
    if (!client) {
      return { success: false, message: 'Supabase belum dikonfigurasi.' };
    }

    try {
      // 1. Settings
      await client.from('app_settings').upsert({
        id: 'current_settings',
        competition_title: payload.settings.competitionTitle,
        competition_subtitle: payload.settings.competitionSubtitle,
        competition_description: payload.settings.competitionDescription,
        location: payload.settings.location,
        event_date_time: payload.settings.eventDateTime,
        theme_color: payload.settings.themeColor,
        background_image_url: payload.settings.backgroundImageUrl,
        logo_url: payload.settings.logoUrl,
        video_promo_url: payload.settings.videoPromoUrl,
        bgm_audio_url: payload.settings.bgmAudioUrl,
        bgm_file_name: payload.settings.bgmFileName || '',
        bgm_enabled: payload.settings.bgmEnabled,
        bgm_volume: payload.settings.bgmVolume,
        voting_enabled: payload.settings.votingEnabled,
        dana_transfer_enabled: payload.settings.danaTransferEnabled,
        dana_target_number: payload.settings.danaTargetNumber,
        dana_target_name: payload.settings.danaTargetName,
        default_price_per_vote: payload.settings.defaultPricePerVote || 1000,
        updated_at: new Date().toISOString()
      });

      // 2. Public Info
      await client.from('public_info').upsert({
        id: 'current_public_info',
        title: payload.publicInfo.title,
        sub_title: payload.publicInfo.subTitle,
        event_description: payload.publicInfo.eventDescription,
        location: payload.publicInfo.location,
        event_date: payload.publicInfo.eventDate,
        contact_person: payload.publicInfo.contactPerson,
        rules_overview: payload.publicInfo.rulesOverview,
        schedule_overview: payload.publicInfo.scheduleOverview,
        updated_at: new Date().toISOString()
      });

      // 3. Categories
      if (payload.categories.length > 0) {
        const catRows = payload.categories.map(c => ({
          id: c.id,
          name: c.name,
          description: c.description,
          location: c.location,
          schedule_time: c.scheduleTime,
          max_duration_minutes: c.maxDurationMinutes || 180,
          rules: c.rules,
          assigned_jury_ids: c.assignedJuryIds,
          criteria: c.criteria
        }));
        await client.from('competition_categories').upsert(catRows);
      }

      // 4. Participants
      if (payload.participants.length > 0) {
        const partRows = payload.participants.map(p => ({
          id: p.id,
          registration_number: p.registrationNumber,
          name: p.name,
          institution: p.institution,
          category_id: p.categoryId,
          contact: p.contact || '',
          photo_url: p.photoUrl || ''
        }));
        await client.from('participants').upsert(partRows);
      }

      // 5. Voting Categories
      if (payload.votingCategories.length > 0) {
        const voteCatRows = payload.votingCategories.map(v => ({
          id: v.id,
          name: v.name,
          description: v.description,
          price_per_vote: v.pricePerVote,
          is_active: v.isActive,
          candidates: v.candidates
        }));
        await client.from('voting_categories').upsert(voteCatRows);
      }

      // 6. Submissions
      if (payload.submissions.length > 0) {
        const subRows = payload.submissions.map(s => ({
          id: s.id,
          category_id: s.categoryId,
          participant_id: s.participantId,
          jury_id: s.juryId,
          jury_name: s.juryName,
          criteria_scores: s.criteriaScores,
          penalties: s.penalties,
          total_score: s.totalScore,
          time_completion_seconds: s.timeCompletionSeconds,
          signature_data_url: s.signatureDataUrl,
          integrity_pact_accepted: s.integrityPactAccepted,
          notes: s.notes || '',
          status: s.status,
          admin_notes: s.adminNotes || '',
          submitted_at: s.submittedAt
        }));
        await client.from('jury_submissions').upsert(subRows);
      }

      // 7. Users
      if (payload.users.length > 0) {
        const userRows = payload.users.map(u => ({
          id: u.id,
          username: u.username,
          password: u.password || '123#',
          name: u.name,
          role: u.role,
          phone: u.phone || null,
          email: u.email || null,
          assigned_category_ids: u.assignedCategoryIds || [],
          vote_balance: u.voteBalance || 0
        }));
        await client.from('users').upsert(userRows);
      }

      return {
        success: true,
        message: 'Seluruh data master & pengaturan berhasil diunggah ke database Supabase!'
      };
    } catch (err: any) {
      console.error('Error push data to Supabase:', err);
      return {
        success: false,
        message: `Gagal sinkronisasi ke Supabase: ${err.message || 'Kesalahan tidak terduga'}`
      };
    }
  },

  // Setup Realtime Subscription
  subscribeRealtime(onDataChanged: (table: string, payload: any) => void): (() => void) {
    const client = this.getClient();
    if (!client) {
      return () => {};
    }

    if (activeChannel) {
      activeChannel.unsubscribe();
      activeChannel = null;
    }

    try {
      const channel = client
        .channel('simpel_digital_global_realtime')
        .on(
          'postgres_changes',
          { event: '*', schema: 'public' },
          (payload) => {
            onDataChanged(payload.table, payload);
          }
        )
        .subscribe((status) => {
          if (status === 'SUBSCRIBED') {
            console.log('⚡ Supabase Realtime Subscription aktif!');
          }
        });

      activeChannel = channel;

      return () => {
        channel.unsubscribe();
        if (activeChannel === channel) {
          activeChannel = null;
        }
      };
    } catch (e) {
      console.warn('Gagal mendaftarkan Supabase realtime:', e);
      return () => {};
    }
  }
};
