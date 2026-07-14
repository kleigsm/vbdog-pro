/**
 * Models — 数据模型定义
 * 与 Supabase PostgreSQL 表结构对齐
 */

export interface User {
  id: string
  phone: string
  nickname: string
  avatarUrl: string
  avatarColor: string
  bio: string
  level: number
  exp: number
  followingCount: number
  followerCount: number
  postCount: number
  createdAt: string
}

export interface Post {
  id: string
  userId: string
  title: string
  content: string
  prompt: string
  category: string
  model: string
  tags: string[]
  likeCount: number
  collectCount: number
  commentCount: number
  shareCount: number
  liked: boolean
  collected: boolean
  author: User | null
  createdAt: string
  updatedAt: string
}

export interface Comment {
  id: string
  postId: string
  userId: string
  content: string
  replyTo: string | null
  likeCount: number
  liked: boolean
  author: User | null
  createdAt: string
}

export interface VNotification {
  id: string
  userId: string
  type: "like" | "comment" | "follow" | "message"
  relatedId: string
  content: string
  read: boolean
  fromUser: User | null
  createdAt: string
}

export interface Message {
  id: string
  fromUserId: string
  toUserId: string
  text: string
  createdAt: string
}

export interface Conversation {
  userId: string
  nickname: string
  avatarUrl: string
  avatarColor: string
  lastMessage: string
  lastTime: string
  unreadCount: number
}

export interface FeedFilter {
  category: string
  sort: "latest" | "hot"
}

export const CATEGORIES: { key: string; label: string; icon: string }[] = [
  { key: "", label: "推荐", icon: "🔥" },
  { key: "Prompt", label: "Prompt", icon: "💬" },
  { key: "Skill", label: "Skill", icon: "🛠" },
  { key: "VibeCoding", label: "VibeCoding", icon: "⚡" },
  { key: "Tutorial", label: "教程", icon: "📖" },
  { key: "Tool", label: "工具", icon: "🔧" },
]

export const LEVELS = [
  { level: 1, title: "🌱 新手", max: 100 },
  { level: 2, title: "🌿 学徒", max: 300 },
  { level: 3, title: "🌳 探索者", max: 600 },
  { level: 4, title: "⭐ 进阶", max: 1000 },
  { level: 5, title: "🌟 专家", max: 2000 },
  { level: 6, title: "💎 大师", max: 5000 },
  { level: 7, title: "👑 宗师", max: 10000 },
  { level: 8, title: "🏆 传奇", max: 20000 },
  { level: 9, title: "🌌 创世", max: Number.MAX_SAFE_INTEGER },
]
