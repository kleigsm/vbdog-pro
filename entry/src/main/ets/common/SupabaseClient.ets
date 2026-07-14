/**
 * SupabaseClient — IApiProvider 的 Supabase REST 实现
 *
 * 使用 Supabase REST API（无需 SDK），调用 postgrest 端点。
 * 更换后端时，用新的实现类替换此类并重新 setApi() 即可。
 */

import { http } from "@kit.NetworkKit"
import { IApiProvider } from "./ApiProvider"
import { Post, Comment, User, VNotification, Message, Conversation } from "./Models"
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./Constants"

export class SupabaseClient implements IApiProvider {
  private url: string
  private key: string
  private token: string = ""

  constructor(url?: string, key?: string) {
    this.url = url ?? SUPABASE_URL
    this.key = key ?? SUPABASE_ANON_KEY
  }

  setToken(token: string): void { this.token = token }

  // ==================== HTTP 封装 ====================

  private async request<T>(method: string, path: string, body?: object, auth: boolean = true): Promise<T> {
    const req = http.createHttp()
    try {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
        "apikey": this.key,
        "Authorization": auth && this.token ? `Bearer ${this.token}` : `Bearer ${this.key}`,
      }
      const opts: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
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
    const resp = await this.request<{ access_token: string; user: User }>("POST", "/rpc/login", { p_phone: phone, p_password: password }, false) as Record<string, Object>
    this.token = resp["access_token"] as string
    return resp["user"] as User
  }

  async register(phone: string, nickname: string, password: string): Promise<User> {
    const resp = await this.request<{ access_token: string; user: User }>("POST", "/rpc/register", { p_phone: phone, p_nickname: nickname, p_password: password }, false) as Record<string, Object>
    this.token = resp["access_token"] as string
    return resp["user"] as User
  }

  async getCurrentUser(): Promise<User> {
    const rows = await this.request<User[]>("GET", "/users?select=*&limit=1", undefined, true) as User[]
    if (!rows || rows.length === 0) throw new Error("Not logged in")
    return rows[0]
  }

  async updateProfile(data: Partial<User>): Promise<User> {
    const user = await this.getCurrentUser()
    return (await this.request<User[]>("PATCH", `/users?id=eq.${user.id}`, data))[0]
  }

  // ==================== 帖子 ====================

  async getPosts(category?: string, sort?: "latest" | "hot", page: number = 0): Promise<Post[]> {
    let query = "/posts?select=*,author:users(*)&limit=20&offset=" + page * 20
    if (category) query += `&category=eq.${category}`
    query += sort === "hot" ? "&order=likeCount.desc" : "&order=createdAt.desc"
    const posts = await this.request<any[]>("GET", query) as Record<string, Object>[]
    return posts.map(p => this.mapPost(p))
  }

  async getPostDetail(postId: string): Promise<Post> {
    const rows = await this.request<Record<string, Object>[]>("GET", `/posts?select=*,author:users(*)&id=eq.${postId}`)
    if (!rows || rows.length === 0) throw new Error("Post not found")
    return this.mapPost(rows[0])
  }

  async createPost(data: { title: string; content: string; prompt: string; category: string; model?: string }): Promise<Post> {
    const user = await this.getCurrentUser()
    const rows = await this.request<Record<string, Object>[]>("POST", "/posts", {
      ...data, userId: user.id, tags: [], likeCount: 0, collectCount: 0, commentCount: 0, shareCount: 0
    })
    return this.mapPost(rows[0], user)
  }

  async deletePost(postId: string): Promise<void> {
    await this.request<void>("DELETE", `/posts?id=eq.${postId}`)
  }

  async likePost(postId: string): Promise<{ liked: boolean; likeCount: number }> {
    const user = await this.getCurrentUser()
    const existing = await this.request<any[]>("GET", `/likes?userId=eq.${user.id}&postId=eq.${postId}`)
    if (existing && existing.length > 0) {
      await this.request<void>("DELETE", `/likes?userId=eq.${user.id}&postId=eq.${postId}`)
    } else {
      await this.request<void>("POST", "/likes", { userId: user.id, postId })
    }
    const post = await this.getPostDetail(postId)
    return { liked: post.liked, likeCount: post.likeCount }
  }

  async collectPost(postId: string): Promise<{ collected: boolean; collectCount: number }> {
    const user = await this.getCurrentUser()
    const existing = await this.request<any[]>("GET", `/collects?userId=eq.${user.id}&postId=eq.${postId}`)
    if (existing && existing.length > 0) {
      await this.request<void>("DELETE", `/collects?userId=eq.${user.id}&postId=eq.${postId}`)
    } else {
      await this.request<void>("POST", "/collects", { userId: user.id, postId })
    }
    const post = await this.getPostDetail(postId)
    return { collected: post.collected, collectCount: post.collectCount }
  }

  // ==================== 评论 ====================

  async getComments(postId: string): Promise<Comment[]> {
    return this.request<Comment[]>("GET", `/comments?postId=eq.${postId}&order=createdAt.asc`)
  }

  async addComment(postId: string, content: string, replyTo?: string): Promise<Comment> {
    const user = await this.getCurrentUser()
    const rows = await this.request<Record<string, Object>[]>("POST", "/comments", { postId, userId: user.id, content, replyTo: replyTo ?? null, likeCount: 0 })
    return { ...rows[0], liked: false } as unknown as Comment
  }

  async deleteComment(commentId: string): Promise<void> {
    await this.request<void>("DELETE", `/comments?id=eq.${commentId}`)
  }

  async likeComment(commentId: string): Promise<{ liked: boolean; likeCount: number }> {
    const user = await this.getCurrentUser()
    const existing = await this.request<any[]>("GET", `/comment_likes?userId=eq.${user.id}&commentId=eq.${commentId}`)
    if (existing && existing.length > 0) {
      await this.request<void>("DELETE", `/comment_likes?userId=eq.${user.id}&commentId=eq.${commentId}`)
    } else {
      await this.request<void>("POST", "/comment_likes", { userId: user.id, commentId })
    }
    const comments = await this.request<any[]>("GET", `/comments?id=eq.${commentId}`)
    return { liked: existing.length === 0, likeCount: comments?.[0]?.likeCount ?? 0 }
  }

  // ==================== 用户 ====================

  async getUserProfile(userId: string): Promise<User> {
    const rows = await this.request<User[]>("GET", `/users?id=eq.${userId}`)
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }

  async followUser(userId: string): Promise<{ following: boolean }> {
    const user = await this.getCurrentUser()
    const existing = await this.request<any[]>("GET", `/follows?followerId=eq.${user.id}&followingId=eq.${userId}`)
    if (existing && existing.length > 0) {
      await this.request<void>("DELETE", `/follows?followerId=eq.${user.id}&followingId=eq.${userId}`)
      return { following: false }
    } else {
      await this.request<void>("POST", "/follows", { followerId: user.id, followingId: userId })
      return { following: true }
    }
  }

  async getUserPosts(userId: string): Promise<Post[]> {
    const rows = await this.request<Record<string, Object>[]>("GET", `/posts?select=*,author:users(*)&userId=eq.${userId}&order=createdAt.desc`)
    return rows.map(p => this.mapPost(p))
  }

  async getUserCollections(userId: string): Promise<Post[]> {
    const collects = await this.request<any[]>("GET", `/collects?userId=eq.${userId}`)
    if (!collects || collects.length === 0) return []
    const ids = collects.map(c => c.postId).join(",")
    const rows = await this.request<Record<string, Object>[]>("GET", `/posts?select=*,author:users(*)&id=in.(${ids})`)
    return rows.map(p => this.mapPost(p))
  }

  // ==================== 搜索 ====================

  async search(query: string): Promise<Post[]> {
    const rows = await this.request<Record<string, Object>[]>("GET", `/posts?select=*,author:users(*)&or=(title.ilike.*${query}*,content.ilike.*${query}*,prompt.ilike.*${query}*)&order=createdAt.desc&limit=20`)
    return rows.map(p => this.mapPost(p))
  }

  // ==================== 消息 ====================

  async getConversations(): Promise<Conversation[]> {
    return this.request<Conversation[]>("GET", "/rpc/get_conversations")
  }

  async getMessages(conversationId: string): Promise<Message[]> {
    const user = await this.getCurrentUser()
    return this.request<Message[]>("GET", `/messages?or=(and(fromUserId.eq.${user.id},toUserId.eq.${conversationId}),and(fromUserId.eq.${conversationId},toUserId.eq.${user.id}))&order=createdAt.asc`)
  }

  async sendMessage(toUserId: string, text: string): Promise<Message> {
    const user = await this.getCurrentUser()
    const rows = await this.request<Message[]>("POST", "/messages", { fromUserId: user.id, toUserId, text })
    return rows[0]
  }

  // ==================== 通知 ====================

  async getNotifications(): Promise<VNotification[]> {
    const user = await this.getCurrentUser()
    return this.request<VNotification[]>("GET", `/notifications?userId=eq.${user.id}&order=createdAt.desc&limit=50`)
  }

  async markNotificationRead(notificationId: string): Promise<void> {
    await this.request<void>("PATCH", `/notifications?id=eq.${notificationId}`, { read: true })
  }

  // ==================== 文件 ====================

  async uploadFile(uri: string, bucket: string): Promise<string> {
    // Supabase Storage 上传，返回公开 URL
    const fileName = `${Date.now()}_${Math.random().toString(36).slice(2)}`
    const fileResp = await http.createHttp().request(uri)
    if (!fileResp) throw new Error("Failed to read file")

    const req = http.createHttp()
    try {
      const resp = await req.request(`${this.url}/storage/v1/object/${bucket}/${fileName}`, {
        method: http.RequestMethod.POST,
        header: { "Authorization": `Bearer ${this.token}`, "apikey": this.key },
        extraData: fileResp.result,
      })
      if (resp.responseCode >= 400) throw new Error(`Upload failed: ${resp.responseCode}`)
      return `${this.url}/storage/v1/object/public/${bucket}/${fileName}`
    } finally {
      req.destroy()
    }
  }

  // ==================== 管理 ====================

  async isAdmin(): Promise<boolean> {
    const user = await this.getCurrentUser()
    return user.phone === "00000000000"
  }

  async adminDeletePost(postId: string): Promise<void> {
    if (!(await this.isAdmin())) throw new Error("Unauthorized")
    await this.request<void>("DELETE", `/posts?id=eq.${postId}`)
  }

  // ==================== 辅助 ====================

  private mapPost(raw: Record<string, Object>, overrideAuthor?: User): Post {
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
      liked: (raw["liked"] as boolean) ?? false,
      collected: (raw["collected"] as boolean) ?? false,
      author: overrideAuthor ?? (raw["author"] as User | null) ?? null,
      createdAt: raw["createdAt"] as string,
      updatedAt: raw["updatedAt"] as string,
    }
  }
}
