import { http } from "@kit.NetworkKit"
import { IApiProvider } from "./ApiProvider"
import { Post, Comment, User, VNotification, Message, Conversation, LikeResult, CollectResult, FollowResult, CreatePostData, Report } from "./Models"
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./Constants"
import { OfflineQueue } from "./OfflineQueue"

interface LoginBody { p_phone: string; p_password: string }
interface RegisterBody { p_phone: string; p_nickname: string; p_password: string }
interface NotificationBody { read: boolean }
interface InsertLikeBody { user_id: string; post_id: string }
interface InsertCollectBody { user_id: string; post_id: string }
interface InsertCommentBody { post_id: string; user_id: string; content: string; reply_to: string | null; like_count: number }
interface InsertCommentLikeBody { user_id: string; comment_id: string }
interface InsertFollowBody { follower_id: string; following_id: string }
interface ConversationRpcParams { p_user_id: string }
interface InsertReportBody { reporter_id: string; post_id: string; reason: string; status: string }
interface InsertBlockBody { blocker_id: string; blocked_id: string }
interface UpdateReportBody { status: string }
interface InsertMessageBody { from_user_id: string; to_user_id: string; text: string }

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
    try {
      const headers: Record<string, string> = { "Accept": "application/json", "apikey": this.key, "Authorization": "Bearer " + this.key }
      if (body) headers["Content-Type"] = "application/json"
      if (this.userId) headers["x-user-id"] = this.userId
      const resp = await req.request(this.url + "/rest/v1" + path, {
        method: body ? http.RequestMethod.POST : http.RequestMethod.GET,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        connectTimeout: 15000, readTimeout: 20000
      })
      if (resp.responseCode >= 400) throw new Error("HTTP " + resp.responseCode + ": " + (resp.result as string))
      const text: string = resp.result as string
      if (text.trim().length === 0) return {} as Record<string, Object>
      return JSON.parse(text)
    } finally { req.destroy() }
  }

  private async deleteRequest(path: string): Promise<Object> {
    const req = http.createHttp()
    try {
      const headers: Record<string, string> = { "Accept": "application/json", "apikey": this.key, "Authorization": "Bearer " + this.key }
      if (this.userId) headers["x-user-id"] = this.userId
      const resp = await req.request(this.url + "/rest/v1" + path, {
        method: http.RequestMethod.DELETE,
        header: headers,
        connectTimeout: 15000, readTimeout: 20000
      })
      if (resp.responseCode >= 400) throw new Error("HTTP " + resp.responseCode + ": " + (resp.result as string))
      const text: string = resp.result as string
      if (text.trim().length === 0) return {} as Record<string, Object>
      return JSON.parse(text)
    } finally { req.destroy() }
  }

  private async updateRequest(path: string, body: Record<string, Object>): Promise<Object> {
    const req = http.createHttp()
    try {
      const headers: Record<string, string> = { "Accept": "application/json", "apikey": this.key, "Authorization": "Bearer " + this.key }
      headers["Prefer"] = "resolution=merge-duplicates"
      headers["Content-Type"] = "application/json"
      if (this.userId) headers["x-user-id"] = this.userId
      const resp = await req.request(this.url + "/rest/v1" + path, {
        method: http.RequestMethod.PUT,
        header: headers,
        extraData: JSON.stringify(body),
        connectTimeout: 15000, readTimeout: 20000
      })
      if (resp.responseCode >= 400) throw new Error("HTTP " + resp.responseCode + ": " + (resp.result as string))
      const text: string = resp.result as string
      if (text.trim().length === 0) return {} as Record<string, Object>
      return JSON.parse(text)
    } finally { req.destroy() }
  }

  async login(phone: string, password: string): Promise<User> {
    const body: LoginBody = { p_phone: phone, p_password: password }
    return this.parseUser(await this.request("/rpc/login", body))
  }
  async register(phone: string, nickname: string, password: string): Promise<User> {
    const body: RegisterBody = { p_phone: phone, p_nickname: nickname, p_password: password }
    return this.parseUser(await this.request("/rpc/register", body))
  }

  async getCurrentUser(): Promise<User> {
    if (!this.userId) throw new Error("Not logged in")
    const rows = await this.request("/users?id=eq." + this.userId) as User[]
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }

  async updateProfile(data: Partial<User>): Promise<User> {
    const d: Record<string, string> = {}
    if (data.nickname) d["nickname"] = data.nickname
    if (data.bio) d["bio"] = data.bio
    const rows = await this.updateRequest("/users?id=eq." + this.userId, d) as User[]
    return rows[0]
  }

  async getPosts(category?: string, sort?: string, page?: number, limit?: number): Promise<Post[]> {
    let query = "/posts?select=*,users(*)&limit=" + (limit ?? 20).toString() + "&offset=" + ((page ?? 0) * 20).toString()
    if (category) query += "&category=eq." + category
    query += sort === "hot" ? "&order=like_count.desc" : "&order=created_at.desc"
    const rows = await this.request(query) as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }

  async getPostDetail(postId: string): Promise<Post> {
    const rows = await this.request("/posts?select=*,users(*)&id=eq." + postId) as Record<string, Object>[]
    if (!rows || rows.length === 0) throw new Error("Post not found")
    return this.mapPost(rows[0])
  }

  async createPost(data: CreatePostData): Promise<Post> {
    const body: Record<string, Object> = {}
    body["title"] = data.title; body["content"] = data.content; body["prompt"] = data.prompt
    body["category"] = data.category; body["model"] = data.model ?? "Claude"
    body["user_id"] = this.userId; body["tags"] = []
    body["like_count"] = 0; body["collect_count"] = 0; body["comment_count"] = 0; body["share_count"] = 0
    const rows = await this.request("/posts", body) as Record<string, Object>[]
    return this.mapPost(rows[0])
  }

  async deletePost(postId: string): Promise<void> { await this.deleteRequest("/posts?id=eq." + postId) }

  async likePost(postId: string): Promise<LikeResult> {
    if (!this.onlineFlag) { OfflineQueue.add("like", postId); return { liked: true, likeCount: 0 } }
    const existing = await this.request("/likes?user_id=eq." + this.userId + "&post_id=eq." + postId) as Record<string, Object>[]
    if (existing && existing.length > 0) {
      await this.deleteRequest("/likes?id=eq." + existing[0]["id"] as string)
    } else {
      const b: InsertLikeBody = { user_id: this.userId, post_id: postId }
      await this.request("/likes", b)
    }
    const post = await this.getPostDetail(postId)
    return { liked: post.liked, likeCount: post.likeCount }
  }

  async collectPost(postId: string): Promise<CollectResult> {
    if (!this.onlineFlag) { OfflineQueue.add("collect", postId); return { collected: true, collectCount: 0 } }
    const existing = await this.request("/collects?user_id=eq." + this.userId + "&post_id=eq." + postId) as Record<string, Object>[]
    if (existing && existing.length > 0) {
      await this.deleteRequest("/collects?id=eq." + existing[0]["id"] as string)
    } else {
      const b: InsertCollectBody = { user_id: this.userId, post_id: postId }
      await this.request("/collects", b)
    }
    const post = await this.getPostDetail(postId)
    return { collected: post.collected, collectCount: post.collectCount }
  }

  async getComments(postId: string): Promise<Comment[]> {
    const rows = await this.request("/comments?select=*,users(*)&post_id=eq." + postId + "&order=created_at.asc") as Record<string, Object>[]
    const result: Comment[] = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]
      const u = r["users"] as Record<string, Object>
      const c: Comment = {
        id: r["id"] as string, postId: r["post_id"] as string, userId: r["user_id"] as string,
        content: r["content"] as string, replyTo: (r["reply_to"] ?? "") as string,
        likeCount: r["like_count"] as number, liked: false,
        author: u ? {
          id: u["id"] as string, phone: u["phone"] as string, nickname: u["nickname"] as string,
          avatarUrl: u["avatar_url"] as string, avatarColor: u["avatar_color"] as string,
          bio: u["bio"] as string, level: u["level"] as number, exp: u["exp"] as number,
          followingCount: u["following_count"] as number, followerCount: u["follower_count"] as number,
          postCount: u["post_count"] as number, createdAt: u["created_at"] as string
        } : null,
        createdAt: r["created_at"] as string
      }
      result.push(c)
    }
    return result
  }

  async addComment(postId: string, content: string, replyTo?: string): Promise<Comment> {
    if (!this.onlineFlag) {
      OfflineQueue.add("comment", postId, "", content, replyTo ?? "")
      return { id: Date.now().toString(), postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0, liked: false, author: null, createdAt: new Date().toISOString() }
    }
    const body: InsertCommentBody = { post_id: postId, user_id: this.userId, content: content, reply_to: (replyTo ?? null), like_count: 0 }
    const rows = await this.request("/comments", body) as Record<string, Object>[]
    const r = rows[0]
    return { id: r["id"] as string, postId, userId: this.userId, content, replyTo: replyTo ?? null, likeCount: 0, liked: false, author: null, createdAt: r["created_at"] as string }
  }

  async deleteComment(commentId: string): Promise<void> { await this.deleteRequest("/comments?id=eq." + commentId) }

  async likeComment(commentId: string): Promise<LikeResult> {
    const existing = await this.request("/comment_likes?user_id=eq." + this.userId + "&comment_id=eq." + commentId) as Record<string, Object>[]
    const wasLiked = existing && existing.length > 0
    if (wasLiked) {
      await this.deleteRequest("/comment_likes?user_id=eq." + this.userId + "&comment_id=eq." + commentId)
    } else {
      const b: InsertCommentLikeBody = { user_id: this.userId, comment_id: commentId }
      await this.request("/comment_likes", b)
    }
    return { liked: !wasLiked, likeCount: 0 }
  }

  async getUserProfile(userId: string): Promise<User> {
    const rows = await this.request("/users?id=eq." + userId) as User[]
    if (!rows || rows.length === 0) throw new Error("User not found")
    return rows[0]
  }

  async followUser(userId: string): Promise<FollowResult> {
    const existing = await this.request("/follows?follower_id=eq." + this.userId + "&following_id=eq." + userId) as Record<string, Object>[]
    if (existing && existing.length > 0) {
      await this.deleteRequest("/follows?id=eq." + existing[0]["id"] as string)
      await this.syncFollowCounts(userId)
      return { following: false }
    }
    const b: InsertFollowBody = { follower_id: this.userId, following_id: userId }
    await this.request("/follows", b)
    await this.syncFollowCounts(userId)
    const n: Record<string, Object> = {}
    n["user_id"] = userId
    n["type"] = "follow"
    n["related_id"] = this.userId
    n["content"] = "关注了你"
    n["read"] = false
    await this.request("/notifications", n)
    return { following: true }
  }

  async getUserPosts(userId: string): Promise<Post[]> {
    const rows = await this.request("/posts?select=*,users(*)&user_id=eq." + userId + "&order=created_at.desc") as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }

  async getUserCollections(userId: string): Promise<Post[]> {
    const collects = await this.request("/collects?user_id=eq." + userId) as Record<string, Object>[]
    if (!collects || collects.length === 0) return []
    let ids = ""
    for (let i = 0; i < collects.length; i++) { if (i > 0) ids += ","; ids += collects[i]["post_id"] as string }
    const rows = await this.request("/posts?select=*,users(*)&id=in.(" + ids + ")") as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }
  async getUserLikes(userId: string): Promise<Post[]> {
    const likes = await this.request("/likes?user_id=eq." + userId) as Record<string, Object>[]
    if (!likes || likes.length === 0) return []
    let ids = ""
    for (let i = 0; i < likes.length; i++) { if (i > 0) ids += ","; ids += likes[i]["post_id"] as string }
    const rows = await this.request("/posts?select=*,users(*)&id=in.(" + ids + ")") as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }

    async getFollowers(userId: string): Promise<User[]> {
    const rows = await this.request("/follows?select=*&following_id=eq." + userId) as Record<string, Object>[]
    if (!rows || rows.length === 0) return []
    let ids = ""
    for (let i = 0; i < rows.length; i++) { if (i > 0) ids += ","; ids += rows[i]["follower_id"] as string }
    const users = await this.request("/users?select=*&id=in.(" + ids + ")") as User[]
    return users
  }
  async getFollowing(userId: string): Promise<User[]> {
    const rows = await this.request("/follows?select=*&follower_id=eq." + userId) as Record<string, Object>[]
    if (!rows || rows.length === 0) return []
    let ids = ""
    for (let i = 0; i < rows.length; i++) { if (i > 0) ids += ","; ids += rows[i]["following_id"] as string }
    const users = await this.request("/users?select=*&id=in.(" + ids + ")") as User[]
    return users
  }
  async isFollowingUser(userId: string): Promise<boolean> {
    const rows = await this.request("/follows?follower_id=eq." + this.userId + "&following_id=eq." + userId) as Record<string, Object>[]
    return rows && rows.length > 0
  }
  private async syncFollowCounts(targetUserId: string): Promise<void> {
    const fw = await this.request("/follows?follower_id=eq." + this.userId) as Record<string, Object>[]
    const fc = await this.request("/follows?following_id=eq." + targetUserId) as Record<string, Object>[]
    const b1: Record<string, Object> = {}; b1["following_count"] = (fw ? fw.length : 0)
    const b2: Record<string, Object> = {}; b2["follower_count"] = (fc ? fc.length : 0)
    await this.updateRequest("/users?id=eq." + this.userId, b1)
    await this.updateRequest("/users?id=eq." + targetUserId, b2)
  }

async search(query: string): Promise<Post[]> {
    const rows = await this.request("/posts?select=*,users(*)&or=(title.ilike.*" + query + "*,content.ilike.*" + query + "*)&order=created_at.desc&limit=20") as Record<string, Object>[]
    const result: Post[] = []
    for (let i = 0; i < rows.length; i++) result.push(this.mapPost(rows[i]))
    return result
  }

  async getConversations(): Promise<Conversation[]> {
    const params: ConversationRpcParams = { p_user_id: this.userId }
    return await this.request("/rpc/get_conversations", params) as Conversation[]
  }

  async getMessages(conversationId: string): Promise<Message[]> {
    return await this.request("/messages?or=(and(from_user_id.eq." + this.userId + ",to_user_id.eq." + conversationId + "),and(from_user_id.eq." + conversationId + ",to_user_id.eq." + this.userId + "))&order=created_at.asc") as Message[]
  }

  async sendMessage(toUserId: string, text: string): Promise<Message> {
    const b: InsertMessageBody = { from_user_id: this.userId, to_user_id: toUserId, text: text }
    const rows = await this.request("/messages", b) as Message[]
    return rows[0]
  }

  async getNotifications(): Promise<VNotification[]> {
    const rows = await this.request("/notifications?select=*,from_user:users!notifications_from_user_id_fkey(*)&user_id=eq." + this.userId + "&order=created_at.desc&limit=50") as Record<string, Object>[]
    const result: VNotification[] = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]
      const fu = r["from_user"] as Record<string, Object>
      result.push({
        id: r["id"] as string, userId: r["user_id"] as string, type: r["type"] as string,
        relatedId: r["related_id"] as string, content: r["content"] as string,
        read: r["read"] as boolean,
        fromUser: fu ? {
          id: fu["id"] as string, phone: fu["phone"] as string, nickname: fu["nickname"] as string,
          avatarUrl: fu["avatar_url"] as string, avatarColor: fu["avatar_color"] as string,
          bio: fu["bio"] as string, level: fu["level"] as number, exp: fu["exp"] as number,
          followingCount: fu["following_count"] as number, followerCount: fu["follower_count"] as number,
          postCount: fu["post_count"] as number, createdAt: fu["created_at"] as string
        } : null,
        createdAt: r["created_at"] as string
      })
    }
    return result
  }

  async markNotificationRead(notificationId: string): Promise<void> {
    const body: Record<string, Object> = { "read": true }
    await this.updateRequest("/notifications?id=eq." + notificationId, body)
  }

  async uploadFile(uri: string, bucket: string): Promise<string> { return "" }

  async reportPost(postId: string, reason: string): Promise<void> {
    const body: Record<string, Object> = {}
    body["reporter_id"] = this.userId
    body["post_id"] = postId
    body["reason"] = reason
    body["status"] = "pending"
    await this.request("/reports", body)
  }
  async blockUser(userId: string): Promise<void> {
    const b: InsertBlockBody = { blocker_id: this.userId, blocked_id: userId }
    await this.request("/blocks", b)
  }
  async getReports(): Promise<Report[]> {
    const rows = await this.request("/reports?select=*&status=eq.pending&order=created_at.desc") as Record<string, Object>[]
    const result: Report[] = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]
      result.push({
        id: r["id"] as string,
        reporterId: r["reporter_id"] as string,
        postId: r["post_id"] as string,
        reason: r["reason"] as string,
        status: r["status"] as string,
        createdAt: r["created_at"] as string
      })
    }
    return result
  }
  async resolveReport(reportId: string, action: string, postId: string): Promise<void> {
    if (action === "delete") await this.deletePost(postId)
    const body: Record<string, Object> = { "status": "resolved" }
    await this.updateRequest("/reports?id=eq." + reportId, body)
  }
  async getAllComments(): Promise<Comment[]> {
    const rows = await this.request("/comments?select=*,users(*)&order=created_at.desc&limit=50") as Record<string, Object>[]
    const result: Comment[] = []
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i]; const u = r["users"] as Record<string, Object>
      result.push({ id: r["id"] as string, postId: r["post_id"] as string, userId: r["user_id"] as string, content: r["content"] as string, replyTo: (r["reply_to"] ?? "") as string, likeCount: r["like_count"] as number, liked: false, author: u ? { id: u["id"] as string, phone: u["phone"] as string, nickname: u["nickname"] as string, avatarUrl: u["avatar_url"] as string, avatarColor: u["avatar_color"] as string, bio: u["bio"] as string, level: u["level"] as number, exp: u["exp"] as number, followingCount: u["following_count"] as number, followerCount: u["follower_count"] as number, postCount: u["post_count"] as number, createdAt: u["created_at"] as string } : null, createdAt: r["created_at"] as string })
    }
    return result
  }
  async getAllUsers(): Promise<User[]> { return await this.request("/users?select=*&order=created_at.desc") as User[] }
  async adminDeleteComment(commentId: string): Promise<void> { await this.deleteRequest("/comments?id=eq." + commentId) }

  async isAdmin(): Promise<boolean> {
    const user = await this.getCurrentUser()
    return user.phone === "00000000000"
  }

  async adminDeletePost(postId: string): Promise<void> {
    if (!(await this.isAdmin())) throw new Error("Unauthorized")
    await this.deleteRequest("/posts?id=eq." + postId)
  }

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
    const u = raw["users"] as Record<string, Object>
    return {
      id: raw["id"] as string, userId: raw["user_id"] as string, title: raw["title"] as string,
      content: raw["content"] as string, prompt: raw["prompt"] as string,
      category: raw["category"] as string, model: raw["model"] as string,
      tags: [], likeCount: raw["like_count"] as number,
      collectCount: raw["collect_count"] as number, commentCount: raw["comment_count"] as number,
      shareCount: raw["share_count"] as number, liked: false, collected: false,
      images: raw["images"] as string[] ?? [],
      author: u ? {
        id: u["id"] as string, phone: u["phone"] as string, nickname: u["nickname"] as string,
        avatarUrl: u["avatar_url"] as string, avatarColor: u["avatar_color"] as string,
        bio: u["bio"] as string, level: u["level"] as number, exp: u["exp"] as number,
        followingCount: u["following_count"] as number, followerCount: u["follower_count"] as number,
        postCount: u["post_count"] as number, createdAt: u["created_at"] as string
      } : null,
      createdAt: raw["created_at"] as string, updatedAt: raw["updated_at"] as string
    }
  }
}
