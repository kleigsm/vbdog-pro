/**
 * SupabaseClient — IApiProvider 的 Supabase REST 实现
 */

import { http } from "@kit.NetworkKit"
import { IApiProvider } from "./ApiProvider"
import { Post, Comment, User, VNotification, Message, Conversation } from "./Models"
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./Constants"

export class SupabaseClient implements IApiProvider {
  private url: string
  private key: string
  private userId: string = ""

  constructor() {
    this.url = SUPABASE_URL
    this.key = SUPABASE_ANON_KEY
  }

  setUserId(id: string): void { this.userId = id }
  getUserId(): string { return this.userId }

  // ==================== HTTP 封装 ====================

  private async request<T>(path: string, body?: object): Promise<T> {
    const req = http.createHttp()
    try {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
        "apikey": this.key,
        "Authorization": `Bearer ${this.key}`,
      }
      if (this.userId) headers["x-user-id"] = this.userId
      const isGet = !body
      const opts: http.HttpRequestOptions = {
        method: isGet ? http.RequestMethod.GET : http.RequestMethod.POST,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 10000,
        readTimeout: 15000,
      }
      const resp = await req.request(`${this.url}/rest/v1${path}`, opts)
      if (resp.responseCode >= 400) throw new Error(`HTTP ${resp.responseCode}: ${resp.result}`)
      return JSON.parse(resp.result as string) as T
    } finally {
      req.destroy()
    }
  }

  // ==================== 认证 ====================

  async login(phone: string, password: string): Promise<User> {
    const result = await this.request<any>("/rpc/login", { p_phone: phone, p_password: password })
    const user = this.parseUser(result)
    this.userId = user.id
    return user
  }

  async register(phone: string, nickname: string, password: string): Promise<User> {
    const result = await this.request<any>("/rpc/register", { p_phone: phone, p_nickname: nickname, p_password: password })
    const user = this.parseUser(result)
    this.userId = user.id
    return user
  }

  async getCurrentUser(): Promise<User> {
    if (!this.userId) throw new Error("Not logged in")
    const rows = await this.request<User[]>(`/users?id=eq.${this.userId}`)
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }

  async updateProfile(data: Partial<User>): Promise<User> {
    return (await this.request<User[]>(`/users?id=eq.${this.userId}`, data))[0]
  }

  // ==================== 帖子 ====================

  async getPosts(category?: string, sort?: string, page?: number): Promise<Post[]> {
    let query = "/posts?select=*&limit=20&offset=" + (page ?? 0) * 20
    if (category) query += `&category=eq.${category}`
    query += sort === "hot" ? "&order=likeCount.desc" : "&order=createdAt.desc"
    const posts = await this.request<Record<string, Object>[]>(query)
    return posts.map((p: Record<string, Object>) => this.mapPost(p))
  }

  async getPostDetail(postId: string): Promise<Post> {
    const rows = await this.request<Record<string, Object>[]>(`/posts?select=*&id=eq.${postId}`)
    if (!rows || rows.length === 0) throw new Error("Post not found")
    return this.mapPost(rows[0])
  }

  async createPost(data: { title: string; content: string; prompt: string; category: string; model?: string }): Promise<Post> {
    const rows = await this.request<Record<string, Object>[]>("/posts", {
      ...data, userId: this.userId, tags: [],
      likeCount: 0, collectCount: 0, commentCount: 0, shareCount: 0
    })
    return this.mapPost(rows[0])
  }

  async deletePost(postId: string): Promise<void> {
    await this.request<void>(`/posts?id=eq.${postId}`)
  }

  async likePost(postId: string): Promise<{ liked: boolean; likeCount: number }> {
    const existing = await this.request<Record<string, Object>[]>(`/likes?userId=eq.${this.userId}&postId=eq.${postId}`)
    if (existing && existing.length > 0) {
      const id = existing[0]["id"] as string
      await this.request<void>(`/likes?id=eq.${id}`)
    } else {
      await this.request<void>("/likes", { userId: this.userId, postId })
    }
    const post = await this.getPostDetail(postId)
    return { liked: post.liked, likeCount: post.likeCount }
  }

  async collectPost(postId: string): Promise<{ collected: boolean; collectCount: number }> {
    const existing = await this.request<Record<string, Object>[]>(`/collects?userId=eq.${this.userId}&postId=eq.${postId}`)
    if (existing && existing.length > 0) {
      const id = existing[0]["id"] as string
      await this.request<void>(`/collects?id=eq.${id}`)
    } else {
      await this.request<void>("/collects", { userId: this.userId, postId })
    }
    const post = await this.getPostDetail(postId)
    return { collected: post.collected, collectCount: post.collectCount }
  }

  // ==================== 评论 ====================
  async getComments(postId: string): Promise<Comment[]> {
    const comments = await this.request<Record<string, Object>[]>(`/comments?postId=eq.${postId}&order=createdAt.asc`)
    return comments.map((c: Record<string, Object>) => ({
      id: c["id"] as string, postId: c["postId"] as string, userId: c["userId"] as string,
      content: c["content"] as string, replyTo: (c["replyTo"] ?? null) as string | null,
      likeCount: c["likeCount"] as number, liked: false,
      author: null, createdAt: c["createdAt"] as string
    }))
  }

  async addComment(postId: string, content: string, replyTo?: string): Promise<Comment> {
    const rows = await this.request<Record<string, Object>[]>("/comments", { postId, userId: this.userId, content, replyTo: replyTo ?? null })
    return { id: rows[0]["id"] as string, postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0, liked: false, author: null, createdAt: rows[0]["createdAt"] as string }
  }

  async deleteComment(commentId: string): Promise<void> { await this.request<void>(`/comments?id=eq.${commentId}`) }
  async likeComment(commentId: string): Promise<{ liked: boolean; likeCount: number }> {
    const existing = await this.request<Record<string, Object>[]>(`/comment_likes?userId=eq.${this.userId}&commentId=eq.${commentId}`)
    const wasLiked = existing && existing.length > 0
    if (wasLiked) await this.request<void>(`/comment_likes?userId=eq.${this.userId}&commentId=eq.${commentId}`)
    else await this.request<void>("/comment_likes", { userId: this.userId, commentId })
    return { liked: !wasLiked, likeCount: (existing?.[0]?.["likeCount"] as number) ?? 0 }
  }

  // ==================== 用户 ====================
  async getUserProfile(userId: string): Promise<User> {
    const rows = await this.request<User[]>(`/users?id=eq.${userId}`)
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }
  async followUser(userId: string): Promise<{ following: boolean }> {
    const existing = await this.request<Record<string, Object>[]>(`/follows?followerId=eq.${this.userId}&followingId=eq.${userId}`)
    if (existing && existing.length > 0) {
      await this.request<void>(`/follows?id=eq.${existing[0]["id"]}`)
      return { following: false }
    }
    await this.request<void>("/follows", { followerId: this.userId, followingId: userId })
    return { following: true }
  }
  async getUserPosts(userId: string): Promise<Post[]> {
    const rows = await this.request<Record<string, Object>[]>(`/posts?select=*&userId=eq.${userId}&order=createdAt.desc`)
    return rows.map((p: Record<string, Object>) => this.mapPost(p))
  }
  async getUserCollections(userId: string): Promise<Post[]> {
    const collects = await this.request<Record<string, Object>[]>(`/collects?userId=eq.${userId}`)
    if (!collects || collects.length === 0) return []
    const ids = collects.map((c: Record<string, Object>) => c["postId"]).join(",")
    return (await this.request<Record<string, Object>[]>(`/posts?select=*&id=in.(${ids})`)).map((p: Record<string, Object>) => this.mapPost(p))
  }

  // ==================== 搜索 ====================
  async search(query: string): Promise<Post[]> {
    const rows = await this.request<Record<string, Object>[]>(`/posts?select=*&or=(title.ilike.*${query}*,content.ilike.*${query}*)&order=createdAt.desc&limit=20`)
    return rows.map((p: Record<string, Object>) => this.mapPost(p))
  }

  // ==================== 消息 ====================
  async getConversations(): Promise<Conversation[]> { return this.request<Conversation[]>("/rpc/get_conversations") }
  async getMessages(conversationId: string): Promise<Message[]> {
    return this.request<Message[]>(`/messages?or=(and(fromUserId.eq.${this.userId},toUserId.eq.${conversationId}),and(fromUserId.eq.${conversationId},toUserId.eq.${this.userId}))&order=createdAt.asc`)
  }
  async sendMessage(toUserId: string, text: string): Promise<Message> {
    const rows = await this.request<Message[]>("/messages", { fromUserId: this.userId, toUserId, text })
    return rows[0]
  }

  // ==================== 通知 ====================
  async getNotifications(): Promise<VNotification[]> {
    return this.request<VNotification[]>(`/notifications?userId=eq.${this.userId}&order=createdAt.desc&limit=50`)
  }
  async markNotificationRead(notificationId: string): Promise<void> {
    await this.request<void>(`/notifications?id=eq.${notificationId}`, { read: true })
  }

  // ==================== 文件 ====================
  async uploadFile(uri: string, bucket: string): Promise<string> {
    const fileName = `${Date.now()}_${Math.random().toString(36).slice(2)}`
    const fileResp = await http.createHttp().request(uri)
    const req = http.createHttp()
    try {
      const resp = await req.request(`${this.url}/storage/v1/object/${bucket}/${fileName}`, {
        method: http.RequestMethod.POST,
        header: { "Authorization": `Bearer ${this.key}`, "apikey": this.key },
        extraData: fileResp.result,
      })
      if (resp.responseCode >= 400) throw new Error(`Upload failed`)
      return `${this.url}/storage/v1/object/public/${bucket}/${fileName}`
    } finally { req.destroy() }
  }

  // ==================== 管理 ====================
  async isAdmin(): Promise<boolean> {
    const user = await this.getCurrentUser()
    return user.phone === "00000000000"
  }
  async adminDeletePost(postId: string): Promise<void> {
    if (!(await this.isAdmin())) throw new Error("Unauthorized")
    await this.request<void>(`/posts?id=eq.${postId}`)
  }

  // ==================== 辅助 ====================

  private parseUser(raw: any): User {
    if (Array.isArray(raw)) raw = raw[0]  // RPC 可能返回数组
    return {
      id: raw.id ?? raw["id"] as string,
      phone: raw.phone ?? raw["phone"] as string,
      nickname: raw.nickname ?? raw["nickname"] as string,
      avatarUrl: (raw.avatar_url ?? raw["avatarUrl"] ?? "") as string,
      avatarColor: (raw.avatar_color ?? raw["avatarColor"] ?? "#FF6B35") as string,
      bio: (raw.bio ?? "") as string,
      level: (raw.level ?? 1) as number,
      exp: (raw.exp ?? 0) as number,
      followingCount: (raw.following_count ?? raw["followingCount"] ?? 0) as number,
      followerCount: (raw.follower_count ?? raw["followerCount"] ?? 0) as number,
      postCount: (raw.post_count ?? raw["postCount"] ?? 0) as number,
      createdAt: (raw.created_at ?? raw["createdAt"] ?? "") as string,
    }
  }

  private mapPost(raw: Record<string, Object>): Post {
    return {
      id: raw["id"] as string,
      userId: raw["userId"] as string,
      title: raw["title"] as string,
      content: raw["content"] as string,
      prompt: raw["prompt"] as string,
      category: raw["category"] as string,
      model: raw["model"] as string,
      tags: (raw["tags"] as string[]) ?? [],
      likeCount: raw["likeCount"] as number,
      collectCount: raw["collectCount"] as number,
      commentCount: raw["commentCount"] as number,
      shareCount: raw["shareCount"] as number,
      liked: false, collected: false,
      author: null,
      createdAt: raw["createdAt"] as string,
      updatedAt: raw["updatedAt"] as string,
    }
  }
}
