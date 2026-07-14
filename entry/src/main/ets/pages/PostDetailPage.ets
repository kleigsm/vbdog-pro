/**
 * PostDetailPage — 帖子详情 + 评论区 + 互动工具栏
 */

import { getApi } from "../common/ApiProvider"
import { Post, Comment as CommentModel, LEVELS } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"

@Entry
@Component
struct PostDetailPage {
  @State post: Post | null = null
  @State comments: CommentModel[] = []
  @State newComment: string = ""
  @State loading: boolean = true
  @State liked: boolean = false
  @State collected: boolean = false
  @State likeAnimScale: number = 1
  @State collectAnimScale: number = 1

  private postId: string = ""

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params["postId"]) {
      this.postId = params["postId"]
      this.loadPost()
      this.loadComments()
    }
  }

  build() {
    if (this.loading) {
      Column() {
        LoadingProgress().width(40).height(40)
      }
      .width("100%").height("100%")
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLORS.background)
    } else if (!this.post) {
      Column({ space: 12 }) {
        Text("😕").fontSize(48)
        Text("帖子不存在").fontSize(15).fontColor(COLORS.textSecondary)
      }
      .width("100%").height("100%")
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLORS.background)
    } else {
      Column() {
        // 顶部导航
        Row() {
          Text("← 返回").fontSize(15).fontColor(COLORS.primary)
            .onClick(() => router.back())
          Blank()
        }
        .width("100%").padding(16)

        Scroll() {
          Column() {
            // 作者信息
            this.authorSection()

            // 标题
            Text(this.post!.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.text)
              .width("100%")
              .padding({ left: 16, right: 16, top: 8, bottom: 12 })

            // 正文
            Text(this.post!.content)
              .fontSize(15)
              .fontColor(COLORS.text)
              .lineHeight(24)
              .width("100%")
              .padding({ left: 16, right: 16, bottom: 16 })

            // 分类标签
            if (this.post!.category || this.post!.model) {
              Row({ space: 8 }) {
                if (this.post!.category) {
                  Text(this.post!.category)
                    .fontSize(11)
                    .fontColor(COLORS.primary)
                    .backgroundColor(COLORS.primary + "14")
                    .borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
                if (this.post!.model) {
                  Text(this.post!.model)
                    .fontSize(11)
                    .fontColor(COLORS.textSecondary)
                    .backgroundColor("#F0F0F5")
                    .borderRadius(4)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                }
              }
              .padding({ left: 16, bottom: 12 })
            }

            // Prompt 原文
            if (this.post!.prompt) {
              Column() {
                Text("Prompt 原文")
                  .fontSize(12)
                  .fontColor(COLORS.textSecondary)
                  .margin({ bottom: 8 })
                Text(this.post!.prompt)
                  .fontSize(13)
                  .fontColor(COLORS.text)
                  .fontFamily("monospace")
                  .lineHeight(20)
                  .width("100%")
                Row() {
                  Blank()
                  Button("复制 Prompt")
                    .fontSize(12)
                    .height(30)
                    .backgroundColor(COLORS.primary)
                    .borderRadius(6)
                    .onClick(() => {
                      // TODO: copy to clipboard
                    })
                }
                .width("100%")
                .margin({ top: 12 })
              }
              .width("100%")
              .padding(12)
              .margin({ left: 16, right: 16, bottom: 16 })
              .backgroundColor("#F8F8FA")
              .borderRadius(12)
            }

            // 互动操作栏
            this.actionBar()

            Divider().strokeWidth(8).color("#F0F0F5").margin({ top: 4, bottom: 4 })

            // 评论区
            this.commentSection()
          }
          .width("100%")
        }
        .layoutWeight(1)

        // 底部评论输入
        this.commentInput()
      }
      .width("100%")
      .height("100%")
      .backgroundColor(COLORS.background)
    }
  }

  @Builder authorSection() {
    Row({ space: 10 }) {
      // 头像
      Text(this.post!.author?.nickname?.charAt(0) ?? "用")
        .fontSize(20)
        .fontColor("#FFFFFF")
        .width(44)
        .height(44)
        .borderRadius(22)
        .textAlign(TextAlign.Center)
        .backgroundColor(AVATAR_COLORS[this.post!.author?.nickname?.length ?? 0 % AVATAR_COLORS.length])

      Column({ space: 2 }) {
        Row({ space: 6 }) {
          Text(this.post!.author?.nickname ?? "用户")
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLORS.text)
          Text(this.getLevelTitle(this.post!.author?.level ?? 1))
            .fontSize(11)
            .fontColor(COLORS.primary)
        }
        Text(this.formatTime(this.post!.createdAt))
          .fontSize(12)
          .fontColor(COLORS.textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width("100%")
    .padding(16)
  }

  @Builder actionBar() {
    Row({ space: 24 }) {
      // 点赞
      Row({ space: 4 }) {
        Text(this.liked ? "❤️" : "🤍")
          .fontSize(20)
          .scale({ x: this.likeAnimScale, y: this.likeAnimScale })
          .onClick(() => this.toggleLike())
        Text(this.formatCount(this.post!.likeCount))
          .fontSize(13)
          .fontColor(COLORS.textSecondary)
      }

      // 收藏
      Row({ space: 4 }) {
        Text(this.collected ? "⭐" : "☆")
          .fontSize(20)
          .scale({ x: this.collectAnimScale, y: this.collectAnimScale })
          .onClick(() => this.toggleCollect())
        Text(this.formatCount(this.post!.collectCount))
          .fontSize(13)
          .fontColor(COLORS.textSecondary)
      }

      // 评论
      Row({ space: 4 }) {
        Text("💬").fontSize(18)
        Text(this.formatCount(this.post!.commentCount))
          .fontSize(13)
          .fontColor(COLORS.textSecondary)
      }

      // 分享
      Row({ space: 4 }) {
        Text("↗").fontSize(18)
          .onClick(() => this.sharePost())
      }
    }
    .width("100%")
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding({ top: 12, bottom: 12 })
  }

  @Builder commentSection() {
    Column() {
      Row() {
        Text("评论")
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.text)
        Text(` (${this.comments.length})`)
          .fontSize(13)
          .fontColor(COLORS.textSecondary)
      }
      .width("100%")
      .padding(16)

      if (this.comments.length === 0) {
        Text("暂无评论，来说两句吧")
          .fontSize(13)
          .fontColor(COLORS.textSecondary)
          .width("100%")
          .textAlign(TextAlign.Center)
          .padding({ top: 40, bottom: 40 })
      } else {
        List({ space: 0 }) {
          ForEach(this.comments, (comment: CommentModel) => {
            ListItem() {
              Row({ space: 10 }) {
                // 头像
                Text((comment.author?.nickname ?? "用").charAt(0))
                  .fontSize(15)
                  .fontColor("#FFFFFF")
                  .width(34)
                  .height(34)
                  .borderRadius(17)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(AVATAR_COLORS[(comment.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])

                Column({ space: 4 }) {
                  Row({ space: 8 }) {
                    Text(comment.author?.nickname ?? "用户")
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(COLORS.text)
                    Text(this.formatTime(comment.createdAt))
                      .fontSize(11)
                      .fontColor(COLORS.textSecondary)
                  }
                  Text(comment.content)
                    .fontSize(14)
                    .fontColor(COLORS.text)
                    .lineHeight(20)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 评论点赞
                Column({ space: 2 }) {
                  Text(comment.liked ? "❤️" : "🤍")
                    .fontSize(14)
                    .onClick(() => this.toggleCommentLike(comment))
                  Text(this.formatCount(comment.likeCount))
                    .fontSize(10)
                    .fontColor(COLORS.textSecondary)
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width("100%")
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            }
          })
        }
        .layoutWeight(1)
      }
    }
    .width("100%")
  }

  @Builder commentInput() {
    Row({ space: 10 }) {
      TextInput({ placeholder: "说点什么...", text: this.newComment })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .backgroundColor("#F0F0F5")
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => { this.newComment = value })

      Button("发送")
        .fontSize(13)
        .height(36)
        .backgroundColor(this.newComment.trim() ? COLORS.primary : "#CCC")
        .borderRadius(18)
        .enabled(this.newComment.trim().length > 0)
        .onClick(() => this.submitComment())
    }
    .width("100%")
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(COLORS.card)
    .shadow({ radius: 4, color: "#00000008", offsetY: -2 })
  }

  // ==================== 数据加载 ====================

  async loadPost() {
    this.loading = true
    try {
      this.post = await getApi().getPostDetail(this.postId)
      this.liked = this.post.liked
      this.collected = this.post.collected
    } catch (e) {
      console.error("loadPost error: " + JSON.stringify(e))
    } finally {
      this.loading = false
    }
  }

  async loadComments() {
    try {
      this.comments = await getApi().getComments(this.postId)
    } catch (e) {
      console.error("loadComments error: " + JSON.stringify(e))
    }
  }

  // ==================== 交互 ====================

  async toggleLike() {
    try {
      const result = await getApi().likePost(this.postId)
      this.liked = result.liked
      this.likeAnimScale = 1.8
      if (this.post) this.post.likeCount = result.likeCount
      animateTo({ duration: 300 }, () => { this.likeAnimScale = 1 })
    } catch (e) { /* ignore */ }
  }

  async toggleCollect() {
    try {
      const result = await getApi().collectPost(this.postId)
      this.collected = result.collected
      this.collectAnimScale = 1.8
      if (this.post) this.post.collectCount = result.collectCount
      animateTo({ duration: 300 }, () => { this.collectAnimScale = 1 })
    } catch (e) { /* ignore */ }
  }

  async toggleCommentLike(comment: CommentModel) {
    try {
      const result = await getApi().likeComment(comment.id)
      comment.liked = result.liked
      comment.likeCount = result.likeCount
    } catch (e) { /* ignore */ }
  }

  async submitComment() {
    const text = this.newComment.trim()
    if (!text) return
    try {
      const newC = await getApi().addComment(this.postId, text)
      this.comments = [...this.comments, newC]
      this.newComment = ""
      if (this.post) this.post.commentCount++
    } catch (e) {
      console.error("submitComment error: " + JSON.stringify(e))
    }
  }

  sharePost() {
    // TODO: share functionality
  }

  // ==================== 辅助 ====================

  formatCount(n: number): string {
    if (n >= 10000) return (n / 10000).toFixed(1) + "w"
    if (n >= 1000) return (n / 1000).toFixed(1) + "k"
    return n.toString()
  }

  formatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const now = new Date()
    const diff = now.getTime() - d.getTime()
    if (diff < 60000) return "刚刚"
    if (diff < 3600000) return Math.floor(diff / 60000) + "分钟前"
    if (diff < 86400000) return Math.floor(diff / 3600000) + "小时前"
    if (diff < 604800000) return Math.floor(diff / 86400000) + "天前"
    return `${d.getMonth() + 1}-${d.getDate()}`
  }

  getLevelTitle(level: number): string {
    const l = LEVELS.find(l => l.level === level)
    return l ? l.title : ""
  }
}
