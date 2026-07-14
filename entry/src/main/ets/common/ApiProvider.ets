/**
 * ApiProvider — 后端抽象层接口
 *
 * 所有页面通过此接口访问后端，不直接依赖 Supabase/AGC 等具体实现。
 * 更换后端只需替换实现类，页面代码零改动。
 */

import { Post, Comment, User, VNotification, Message, Conversation } from "./Models"

export interface IApiProvider {
  // ========== 认证 ==========
  login(phone: string, password: string): Promise<User>
  register(phone: string, nickname: string, password: string): Promise<User>
  getCurrentUser(): Promise<User>
  updateProfile(data: Partial<User>): Promise<User>

  // ========== 帖子 ==========
  getPosts(category?: string, sort?: "latest" | "hot", page?: number): Promise<Post[]>
  getPostDetail(postId: string): Promise<Post>
  createPost(data: { title: string; content: string; prompt: string; category: string; model?: string }): Promise<Post>
  deletePost(postId: string): Promise<void>
  likePost(postId: string): Promise<{ liked: boolean; likeCount: number }>
  collectPost(postId: string): Promise<{ collected: boolean; collectCount: number }>

  // ========== 评论 ==========
  getComments(postId: string): Promise<Comment[]>
  addComment(postId: string, content: string, replyTo?: string): Promise<Comment>
  deleteComment(commentId: string): Promise<void>
  likeComment(commentId: string): Promise<{ liked: boolean; likeCount: number }>

  // ========== 用户 ==========
  getUserProfile(userId: string): Promise<User>
  followUser(userId: string): Promise<{ following: boolean }>
  getUserPosts(userId: string): Promise<Post[]>
  getUserCollections(userId: string): Promise<Post[]>

  // ========== 搜索 ==========
  search(query: string): Promise<Post[]>

  // ========== 消息 ==========
  getConversations(): Promise<Conversation[]>
  getMessages(conversationId: string): Promise<Message[]>
  sendMessage(toUserId: string, text: string): Promise<Message>

  // ========== 通知 ==========
  getNotifications(): Promise<VNotification[]>
  markNotificationRead(notificationId: string): Promise<void>

  // ========== 文件 ==========
  uploadFile(uri: string, bucket: string): Promise<string>

  // ========== 管理 ==========
  isAdmin(): Promise<boolean>
  adminDeletePost(postId: string): Promise<void>
}

// ========== 全局单例 ==========
let _provider: IApiProvider | null = null

export function getApi(): IApiProvider {
  if (!_provider) throw new Error("ApiProvider not initialized. Call setApi() first.")
  return _provider
}

export function setApi(provider: IApiProvider): void {
  _provider = provider
}
