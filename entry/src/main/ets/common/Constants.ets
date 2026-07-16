export const SUPABASE_URL: string = "https://bxecdhlbnpwahwswnqzr.supabase.co"
export const SUPABASE_ANON_KEY: string = "sb_publishable_UkKBNurH0MXBStUtXjlCeg_5NxQBaJU"
// ─── App ─────────────────────────────────────────────────
export const APP_NAME = 'VBDog Pro'
export const APP_VERSION = '1.0.0'

// ─── Colors ──────────────────────────────────────────────
export const C_PRIMARY = '#FF6B35'
export const C_DARK = '#1A1A2E'
export const C_BLUE = '#00D2FF'
export const C_GREEN = '#00F5A0'
export const C_RED = '#FF4757'
export const C_YELLOW = '#FFD700'
export const C_BG = '#F8F9FA'
export const C_CARD = '#FFFFFF'
export const C_TEXT1 = '#1A1A2E'
export const C_TEXT2 = '#6B7280'
export const C_TEXT3 = '#9CA3AF'
export const C_BORDER = '#E5E7EB'
export const C_GLASS = 'rgba(255,255,255,0.9)'
export const C_LIKE = '#FF4757'
export const C_COLLECT = '#FFD700'

// ─── Spacing ─────────────────────────────────────────────
export const S_XS = 4; export const S_SM = 8; export const S_MD = 12
export const S_LG = 16; export const S_XL = 20; export const S_2XL = 24
export const R_SM = 8; export const R_MD = 12; export const R_LG = 16; export const R_XL = 20

// ─── Font ────────────────────────────────────────────────
export const F_CAPT = 10; export const F_SM = 12; export const F_BODY = 14
export const F_LG = 16; export const F_H3 = 18; export const F_H2 = 20; export const F_H1 = 24

// ─── Categories ──────────────────────────────────────────
export interface Category { id: string; name: string; icon: string; color: string }
export const CATEGORIES: Category[] = [
  { id: 'all', name: '推荐', icon: '🔥', color: C_PRIMARY },
  { id: 'Prompt', name: 'Prompt', icon: '💬', color: C_BLUE },
  { id: 'Skill', name: 'Skill', icon: '🛠', color: '#AF52DE' },
  { id: 'VibeCoding', name: 'VibeCoding', icon: '⚡', color: C_GREEN },
  { id: '教程', name: '教程', icon: '📉', color: '#FF9500' },
  { id: '工具', name: '工具', icon: '🔡', color: '#5856D6' },
]

// ─── Tags ────────────────────────────────────────────────
export interface VTag { id: string; name: string; hot: boolean }
export const HOT_TAGS: VTag[] = [
  { id: 't1', name: 'ChatGPT', hot: true }, { id: 't2', name: 'Claude', hot: true },
  { id: 't3', name: '编程', hot: true }, { id: 't4', name: '写作', hot: false },
  { id: 't5', name: '绘画', hot: true }, { id: 't6', name: 'PPT', hot: false },
  { id: 't7', name: '翻译', hot: false }, { id: 't8', name: '产品经理', hot: false },
  { id: 't9', name: 'Midjourney', hot: true }, { id: 't10', name: 'SD', hot: false },
  { id: 't11', name: '数据分析', hot: false }, { id: 't12', name: '视频', hot: true },
]

// ─── Target Models ───────────────────────────────────────
export const TARGET_MODELS = ['通用', 'GPT-4', 'GPT-4o', 'Claude Opus', 'Claude Sonnet', 'Gemini', 'Midjourney', 'Stable Diffusion', 'Sora', '其他']

// ─── Animation ───────────────────────────────────────────
export const ANIM_DURATION_NORMAL = 250

// ─── Legacy COLORS class (backward compat) ───────────────
export const AVATAR_COLORS: string[] = [
  "#FF6B35", "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#00C7BE",
]
export class COLORS {
  static readonly primary: string = "#FF6B35"
  static readonly background: string = "#F8F9FA"
  static readonly card: string = "#FFFFFF"
  static readonly text: string = "#1A1A2E"
  static readonly textSecondary: string = "#8E8E93"
  static readonly success: string = "#34C759"
  static readonly warning: string = "#FF9500"
  static readonly error: string = "#FF3B30"
}
