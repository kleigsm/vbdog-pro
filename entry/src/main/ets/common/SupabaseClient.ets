import { http } from "@kit.NetworkKit"
import { IApiProvider } from "./ApiProvider"
import { Post, Comment, User, VNotification, Message, Conversation, LikeResult, CollectResult, FollowResult, CreatePostData } from "./Models"
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./Constants"
import { OfflineQueue } from "./OfflineQueue"

interface LoginBody { p_phone: string; p_password: string }
interface RegisterBody { p_phone: string; p_nickname: string; p_password: string }
interface IdBody { userId: string; postId: string }
interface CommentBody { postId: string; userId: string; content: string; replyTo: string | null; likeCount: number }
interface FollowBody { followerId: string; followingId: string }
interface MessageBody { fromUserId: string; toUserId: string; text: string }
interface NotificationBody { read: boolean }
interface CommentLikeBody { userId: string; commentId: string }

export class SupabaseClient implements IApiProvider {
  private url: string = SUPABASE_URL
  private key: string = SUPABASE_ANON_KEY
  private userId: string = ""
  private onlineFlag: boolean = true

  setUserId(id: string): void { this.userId = id }
  getUserId(): string { return this.userId }
  setOnline(online: boolean): void { this.onlineFlag = online }
  isOnline(): boolean { return this.onlineFlag }

  private async request(path: string, body?: Object): Promise<Object> {
    const req = http.createHttp()
    // 调试环境跳过 SSL 验证
    try {
      const headers: Record<string, string> = { "Accept": "application/json", "apikey": this.key, "Authorization": `Bearer ${this.key}` }; if (body) headers["Content-Type"] = "application/json"
      if (this.userId) headers["x-user-id"] = this.userId
      const resp = await req.request(`${this.url}/rest/v1${path}`, {
        method: body ? http.RequestMethod.POST : http.RequestMethod.GET,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 15000, readTimeout: 20000
      })
      if (resp.responseCode >= 400) throw new Error(`HTTP ${resp.responseCode}`)
      return JSON.parse(resp.result as string)
    } finally { req.destroy() }
  }

  async login(phone: string, password: string): Promise<User> { return this.parseUser(await this.request("/rpc/login", { p_phone: phone, p_password: password } as LoginBody)) }
  async register(phone: string, nickname: string, password: string): Promise<User> { return this.parseUser(await this.request("/rpc/register", { p_phone: phone, p_nickname: nickname, p_password: password } as RegisterBody)) }
  async getCurrentUser(): Promise<User> {
    if (!this.userId) throw new Error("Not logged in")
    const rows = await this.request(`/users?id=eq.${this.userId}`) as User[]
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }
  async updateProfile(data: Partial<User>): Promise<User> {
    const d: Record<string, Object> = {}
    if (data.nickname) d["nickname"] = data.nickname
    if (data.bio) d["bio"] = data.bio
    const rows = await this.request(`/users?id=eq.${this.userId}`, d) as User[]
    return rows[0]
  }
  async getPosts(category?: string, sort?: string, page?: number): Promise<Post[]> {
    let query = `/posts?select=*&limit=20&offset=${(page ?? 0) * 20}`
    if (category) query += `&category=eq.${category}`
    query += sort === "hot" ? "&order=likeCount.desc" : "&order=createdAt.desc"
    const rows = await this.request(query) as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }
  async getPostDetail(postId: string): Promise<Post> {
    const rows = await this.request(`/posts?select=*&id=eq.${postId}`) as Record<string, Object>[]
    if (!rows || rows.length === 0) throw new Error("Post not found")
    return this.mapPost(rows[0])
  }
  async createPost(data: CreatePostData): Promise<Post> {
    const body: Record<string, Object> = {}
    body["title"] = data.title; body["content"] = data.content; body["prompt"] = data.prompt
    body["category"] = data.category; body["model"] = data.model ?? "Claude"
    body["userId"] = this.userId; body["tags"] = []
    body["likeCount"] = 0; body["collectCount"] = 0; body["commentCount"] = 0; body["shareCount"] = 0
    const rows = await this.request(`/posts`, body) as Record<string, Object>[]
    return this.mapPost(rows[0])
  }
  async deletePost(postId: string): Promise<void> { await this.request(`/posts?id=eq.${postId}`) }
  async likePost(postId: string): Promise<LikeResult> {
    if (!this.onlineFlag) { OfflineQueue.add("like", postId); return { liked: true, likeCount: 0 } }
    const existing = await this.request(`/likes?userId=eq.${this.userId}&postId=eq.${postId}`) as Record<string, Object>[]
    if (existing && existing.length > 0) { await this.request(`/likes?id=eq.${existing[0]["id"]}`) }
    else { const b: IdBody = { userId: this.userId, postId }; await this.request("/likes", b) }
    const post = await this.getPostDetail(postId)
    return { liked: post.liked, likeCount: post.likeCount }
  }
  async collectPost(postId: string): Promise<CollectResult> {
    if (!this.onlineFlag) { OfflineQueue.add("collect", postId); return { collected: true, collectCount: 0 } }
    const existing = await this.request(`/collects?userId=eq.${this.userId}&postId=eq.${postId}`) as Record<string, Object>[]
    if (existing && existing.length > 0) { await this.request(`/collects?id=eq.${existing[0]["id"]}`) }
    else { const b: IdBody = { userId: this.userId, postId }; await this.request("/collects", b) }
    const post = await this.getPostDetail(postId)
    return { collected: post.collected, collectCount: post.collectCount }
  }
  async getComments(postId: string): Promise<Comment[]> {
    const rows = await this.request(`/comments?postId=eq.${postId}&order=createdAt.asc`) as Record<string, Object>[]
    const result: Comment[] = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]
      result.push({ id: r["id"] as string, postId: r["postId"] as string, userId: r["userId"] as string, content: r["content"] as string, replyTo: (r["replyTo"] ?? null) as string | null, likeCount: r["likeCount"] as number, liked: false, author: null, createdAt: r["createdAt"] as string })
    }
    return result
  }
  async addComment(postId: string, content: string, replyTo?: string): Promise<Comment> {
    if (!this.onlineFlag) {
      OfflineQueue.add("comment", postId, "", content, replyTo ?? "")
      return { id: Date.now().toString(), postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0, liked: false, author: null, createdAt: new Date().toISOString() }
    }
    const body: CommentBody = { postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0 }
    const rows = await this.request("/comments", body) as Record<string, Object>[]
    const r = rows[0]
    return { id: r["id"] as string, postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0, liked: false, author: null, createdAt: r["createdAt"] as string }
  }
  async deleteComment(commentId: string): Promise<void> { await this.request(`/comments?id=eq.${commentId}`) }
  async likeComment(commentId: string): Promise<LikeResult> {
    const existing = await this.request(`/comment_likes?userId=eq.${this.userId}&commentId=eq.${commentId}`) as Record<string, Object>[]
    const wasLiked = existing && existing.length > 0
    if (wasLiked) { await this.request(`/comment_likes?userId=eq.${this.userId}&commentId=eq.${commentId}`) }
    else { const b: CommentLikeBody = { userId: this.userId, commentId }; await this.request("/comment_likes", b) }
    return { liked: !wasLiked, likeCount: 0 }
  }
  async getUserProfile(userId: string): Promise<User> { const rows = await this.request(`/users?id=eq.${userId}`) as User[]; if (!rows || rows.length === 0) throw new Error("User not found"); return rows[0] }
  async followUser(userId: string): Promise<FollowResult> {
    const existing = await this.request(`/follows?followerId=eq.${this.userId}&followingId=eq.${userId}`) as Record<string, Object>[]
    if (existing && existing.length > 0) { await this.request(`/follows?id=eq.${existing[0]["id"]}`); return { following: false } }
    const b: FollowBody = { followerId: this.userId, followingId: userId }; await this.request("/follows", b)
    return { following: true }
  }
  async getUserPosts(userId: string): Promise<Post[]> {
    const rows = await this.request(`/posts?select=*&userId=eq.${userId}&order=createdAt.desc`) as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }
  async getUserCollections(userId: string): Promise<Post[]> {
    const collects = await this.request(`/collects?userId=eq.${userId}`) as Record<string, Object>[]
    if (!collects || collects.length === 0) return []
    let ids = ""
    for (let i = 0; i < collects.length; i++) { if (i > 0) ids += ","; ids += collects[i]["postId"] as string }
    const rows = await this.request(`/posts?select=*&id=in.(${ids})`) as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }
  async search(query: string): Promise<Post[]> {
    const rows = await this.request(`/posts?select=*&or=(title.ilike.*${query}*,content.ilike.*${query}*)&order=createdAt.desc&limit=20`) as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }
  async getConversations(): Promise<Conversation[]> { return await this.request("/rpc/get_conversations") as Conversation[] }
  async getMessages(conversationId: string): Promise<Message[]> { return await this.request(`/messages?or=(and(fromUserId.eq.${this.userId},toUserId.eq.${conversationId}),and(fromUserId.eq.${conversationId},toUserId.eq.${this.userId}))&order=createdAt.asc`) as Message[] }
  async sendMessage(toUserId: string, text: string): Promise<Message> { const b: MessageBody = { fromUserId: this.userId, toUserId, text }; const rows = await this.request("/messages", b) as Message[]; return rows[0] }
  async getNotifications(): Promise<VNotification[]> { return await this.request(`/notifications?userId=eq.${this.userId}&order=createdAt.desc&limit=50`) as VNotification[] }
  async markNotificationRead(notificationId: string): Promise<void> { const b: NotificationBody = { read: true }; await this.request(`/notifications?id=eq.${notificationId}`, b) }
  async uploadFile(uri: string, bucket: string): Promise<string> { return "" }
  async isAdmin(): Promise<boolean> { const user = await this.getCurrentUser(); return user.phone === "00000000000" }
  async adminDeletePost(postId: string): Promise<void> { if (!(await this.isAdmin())) throw new Error("Unauthorized"); await this.request(`/posts?id=eq.${postId}`) }

  private parseUser(raw: Object): User {
    const r = raw as Record<string, Object>
    return {
      id: r["id"] as string, phone: r["phone"] as string, nickname: r["nickname"] as string,
      avatarUrl: (r["avatar_url"] ?? r["avatarUrl"] ?? "") as string,
      avatarColor: (r["avatar_color"] ?? r["avatarColor"] ?? "#FF6B35") as string,
      bio: (r["bio"] ?? "") as string, level: (r["level"] ?? 1) as number, exp: (r["exp"] ?? 0) as number,
      followingCount: 0, followerCount: 0, postCount: 0, createdAt: (r["created_at"] ?? r["createdAt"] ?? "") as string
    }
  }
  private mapPost(raw: Record<string, Object>): Post {
    return {
      id: raw["id"] as string, userId: raw["userId"] as string, title: raw["title"] as string,
      content: raw["content"] as string, prompt: raw["prompt"] as string,
      category: raw["category"] as string, model: raw["model"] as string,
      tags: [], likeCount: raw["likeCount"] as number,
      collectCount: raw["collectCount"] as number, commentCount: raw["commentCount"] as number,
      shareCount: raw["shareCount"] as number, liked: false, collected: false,
      author: null, createdAt: raw["createdAt"] as string, updatedAt: raw["updatedAt"] as string
    }
  }
}
