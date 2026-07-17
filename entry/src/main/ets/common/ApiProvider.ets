import { Post, Comment, User, VNotification, Message, Conversation, LikeResult, CollectResult, FollowResult, CreatePostData } from "./Models"

export interface IApiProvider {
  login(phone: string, password: string): Promise<User>
  register(phone: string, nickname: string, password: string): Promise<User>
  getCurrentUser(): Promise<User>
  updateProfile(data: Partial<User>): Promise<User>
  getPosts(category?: string, sort?: string, page?: number): Promise<Post[]>
  getPostDetail(postId: string): Promise<Post>
  createPost(data: CreatePostData): Promise<Post>
  deletePost(postId: string): Promise<void>
  likePost(postId: string): Promise<LikeResult>
  collectPost(postId: string): Promise<CollectResult>
  getComments(postId: string): Promise<Comment[]>
  addComment(postId: string, content: string, replyTo?: string): Promise<Comment>
  deleteComment(commentId: string): Promise<void>
  likeComment(commentId: string): Promise<LikeResult>
  getUserProfile(userId: string): Promise<User>
  followUser(userId: string): Promise<FollowResult>
  getUserPosts(userId: string): Promise<Post[]>
  getUserCollections(userId: string): Promise<Post[]>
  getUserLikes(userId: string): Promise<Post[]>
  search(query: string): Promise<Post[]>
  getConversations(): Promise<Conversation[]>
  getMessages(conversationId: string): Promise<Message[]>
  sendMessage(toUserId: string, text: string): Promise<Message>
  getNotifications(): Promise<VNotification[]>
  markNotificationRead(notificationId: string): Promise<void>
  uploadFile(uri: string, bucket: string): Promise<string>
  isAdmin(): Promise<boolean>
  adminDeletePost(postId: string): Promise<void>
  reportPost(postId: string, reason: string): Promise<void>
  blockUser(userId: string): Promise<void>
}

let _provider: IApiProvider | null = null

export function getApi(): IApiProvider {
  if (!_provider) throw new Error("ApiProvider not initialized")
  return _provider
}

export function setApi(provider: IApiProvider): void { _provider = provider }
