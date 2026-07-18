import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, C_RED, C_COLLECT, C_BLUE, C_DARK_BORDER, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, R_LG, F_CAPT, F_SM, F_BODY, F_LG, F_H2, TARGET_MODELS } from "../common/Constants"
import { Post, Comment } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import { OfflineQueue } from "../common/OfflineQueue"
import router from "@ohos.router"
import { pasteboard } from "@kit.BasicServicesKit"
import { promptAction } from "@kit.ArkUI"

function avatarColor(name: string): string {
  if (!name) return "#4ECDC4"
  let hash = 0
  for (let i = 0; i < name.length; i++) { hash = name.charCodeAt(i) + ((hash << 5) - hash) }
  let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"]
  return colors[Math.abs(hash) % colors.length]
}

@Entry
@Component
struct PostDetailPage {
  @StorageLink("isDark") isDark: boolean = false
  @State post: Post | null = null
  @State comments: Comment[] = []
  @State commentText: string = ""
  @State showCommentInput: boolean = false
  @State isLiked: boolean = false
  @State isCollected: boolean = false
  @State likeCount: number = 0
  @State collectCount: number = 0
  @State likeAnimScale: number = 1
  @State collectAnimScale: number = 1
  @State replyToCommentId: string = ""
  @State replyToUserName: string = ""
  @State loading: boolean = true
  @State similarPosts: Post[] = []
  @State showReportDialog: boolean = false
  private reportReasons: string[] = ["垃圾广告", "色情内容", "政治敏感", "人身攻击", "其他"]
  @State showDelete: boolean = false
  private postId: string = ""

  aboutToAppear(): void {
    const params: Object = router.getParams() as Object
    if (params) {
      const p: Record<string, string> = params as Record<string, string>
      this.postId = p["postId"] ?? ""
      this.loadAll()
    }
  }

  async loadAll(): Promise<void> {
    this.loading = true
    try {
      this.post = await getApi().getPostDetail(this.postId)
      if (this.post) {
        this.isLiked = this.post.liked
        this.isCollected = this.post.collected
        this.likeCount = this.post.likeCount
        this.collectCount = this.post.collectCount
        this.loadSimilar()
      }
    } catch (_e) {
      // post stays null on error
    } finally { this.loading = false }
    this.loadComments()
  }

  async loadComments(): Promise<void> {
    try { this.comments = await getApi().getComments(this.postId) } catch (_e) { this.comments = [] }
  }

  async loadSimilar(): Promise<void> {
    try {
      if (this.post?.category) {
        const sp = await getApi().getPosts(this.post.category, "hot", 0) as Post[]
        this.similarPosts = sp.filter((p: Post) => p.id !== this.postId).slice(0, 3)
      }
    } catch (_e) { this.similarPosts = [] }
  }

  toggleLike(): void {
    if (!this.post) return
    this.isLiked = !this.isLiked
    this.likeCount += this.isLiked ? 1 : -1
    getApi().likePost(this.postId)
    this.likeAnimScale = 1.8
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.likeAnimScale = 1 })
  }

  toggleCollect(): void {
    if (!this.post) return
    this.isCollected = !this.isCollected
    this.collectCount += this.isCollected ? 1 : -1
    getApi().collectPost(this.postId)
    this.collectAnimScale = 1.8
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.collectAnimScale = 1 })
  }

  copyPrompt(): void {
    if (!this.post?.prompt) return
    pasteboard.getSystemPasteboard().setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post.prompt))
    promptAction.showToast({ message: "已复制 Prompt 到剪贴板", duration: 1500 })
  }

  async submitComment(): Promise<void> {
    const text = this.commentText.trim()
    if (!text || !this.post) return
    try {
      const nc = await getApi().addComment(this.postId, text, this.replyToCommentId || undefined)
      this.comments = [nc, ...this.comments]
      if (this.post) this.post.commentCount++
    } catch (_e) { }
    this.commentText = ""; this.showCommentInput = false
    this.replyToCommentId = ""; this.replyToUserName = ""
  }

  isOwnPost(): boolean { return UserManager.currentUser?.id === this.post?.userId }

  async doDelete(): Promise<void> {
    try { await getApi().deletePost(this.postId); router.back() } catch (_e) { }
  }

  async toggleCommentLike(comment: Comment): Promise<void> {
    try {
      const r = await getApi().likeComment(comment.id)
      comment.liked = r.liked; comment.likeCount = r.likeCount
    } catch (_e) { }
  }

  formatCount(n: number): string {
    if (n >= 10000) return (n / 10000).toFixed(1) + "w"
    if (n >= 1000) return (n / 1000).toFixed(1) + "k"
    return n.toString()
  }

  formatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const diff = Date.now() - d.getTime()
    if (diff < 60000) return "刚刚"
    if (diff < 3600000) return Math.floor(diff / 60000) + "分钟前"
    if (diff < 86400000) return Math.floor(diff / 3600000) + "小时前"
    if (diff < 604800000) return Math.floor(diff / 86400000) + "天前"
    return (d.getMonth() + 1) + "-" + d.getDate()
  }

  build() {
    if (this.loading) {
      Column() { LoadingProgress().width(40).height(40).color(C_PRIMARY) }
        .width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? C_DARK_BG : C_BG)
    } else if (!this.post) {
      Column({ space: 12 }) {
        Text("😕").fontSize(48)
        Text("帖子不存在").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2)
        Button("返回").fontSize(F_SM).backgroundColor(C_PRIMARY).fontColor("#FFF").borderRadius(18).height(36)
          .onClick(() => router.back())
      }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? C_DARK_BG : C_BG)
    } else {
      Column() {
        Row() {
          Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1)
            .onClick(() => { router.back() })
          Text("帖子详情").fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            .layoutWeight(1).textAlign(TextAlign.Center)
          Text("").width(24)
        }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

        Scroll() {
          Column() {
            // Author section
            Row() {
              Text(this.post!.author?.nickname?.charAt(0) ?? "用").fontSize(22).fontColor("#FFF")
                .width(40).height(40).borderRadius(20).textAlign(TextAlign.Center)
                .backgroundColor(avatarColor(this.post!.author?.nickname ?? ""))
              Column() {
                Text(this.post!.author?.nickname ?? "用户").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
                Text("Lv." + (this.post!.author?.level ?? 1) + " · " + this.formatTime(this.post!.createdAt ?? ""))
                  .fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
              }.margin({ left: S_MD }).alignItems(HorizontalAlign.Start)
              .onClick(() => {
                if (this.post?.userId) {
                  router.pushUrl({ url: "pages/UserPage", params: { userId: this.post?.userId ?? "" } })
                }
              })
              if (!this.isOwnPost()) {
                Button("+ 关注").fontSize(F_SM).fontColor("#FFFFFF")
                  .backgroundColor(C_PRIMARY).borderRadius(16).height(30)
                  .padding({ left: S_MD, right: S_MD })
                  .onClick(() => {
                    if (this.post?.userId) {
                      getApi().followUser(this.post.userId)
                      promptAction.showToast({ message: "已关注", duration: 1000 })
                    }
                  })
                Text("").width(8)
              } else {
                Text("").width(80).height(30)
              }
              Text("举报").fontSize(F_SM).fontColor(C_TEXT3)
                .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM })
                .borderRadius(16).borderWidth(1).borderColor(C_BORDER)
                .onClick(() => this.showReportDialog = true)
              if (this.isOwnPost()) {
                Text("删除").fontSize(F_SM).fontColor(C_RED)
                  .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM })
                  .borderRadius(16).borderWidth(1).borderColor(C_RED)
                  .onClick(() => this.showDelete = true)
              }
            }.width("100%").padding(S_LG).backgroundColor(C_CARD)

            // Title
            Text(this.post!.title).fontSize(F_H2).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
              .width("100%").padding({ left: S_LG, right: S_LG, top: S_LG }).lineHeight(28)

            // Content
            if (this.post!.content) {
              Text(this.post!.content).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).width("100%")
                .padding({ left: S_LG, right: S_LG, top: S_SM }).lineHeight(22)
            }
            if (this.post!.images && this.post!.images.length > 0) {
              Text("📷 图片").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2)
                .width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
              Grid() {
                ForEach(this.post!.images, (img: string) => {
                  GridItem() {
                    Image(img).width("100%").aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(R_MD)
                  }
                }, (img: string) => img)
              }
              .columnsTemplate("1fr 1fr 1fr")
              .columnsGap(4).rowsGap(4)
              .width("100%").padding({ left: S_LG, right: S_LG, top: S_SM })
            }

            // Category + model
            Row() {
              Text(this.post!.category === "Prompt" ? "💬 Prompt" : this.post!.category === "Skill" ? "🛠 Skill" : this.post!.category === "VibeCoding" ? "⚡ VibeCoding" : this.post!.category === "教程" ? "📚 教程" : this.post!.category === "工具" ? "🔧 工具" : this.post!.category === "" || !this.post!.category ? "🔥 推荐" : this.post!.category)
                .fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).fontWeight(FontWeight.Medium)
              if (this.post!.model) {
                Text(this.post!.model).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT2 : C_BLUE)
                  .padding({ left: S_SM, right: S_SM, top: 2, bottom: 2 }).backgroundColor(this.isDark ? "#444" : "#E3F2FD").borderRadius(8)
              }
            }.padding({ left: S_LG, right: S_LG, top: S_MD }).width("100%")

            // Tags
            if (this.post!.tags && this.post!.tags.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.post!.tags.slice(0, 5), (t: string) => {
                  Text("#" + t).fontSize(F_CAPT).fontColor(C_PRIMARY).margin({ right: S_SM, bottom: S_XS })
                    .onClick(() => { router.pushUrl({ url: "pages/SearchPage", params: { query: t } }) })
                })
              }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM })
            }

            // Prompt block
            if (this.post!.prompt) {
              Column() {
                Row() {
                  Text("📋 Prompt 原文").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold).layoutWeight(1)
                  Text("📋 复制").fontSize(F_SM).fontColor(C_BLUE).backgroundColor(Color.Transparent)
                    .onClick(() => { this.copyPrompt() })
                  Text("🎨 改编").fontSize(F_SM).fontColor(C_PRIMARY).backgroundColor(Color.Transparent)
                    .margin({ left: S_MD })
                    .onClick(() => {
                      router.pushUrl({ url: "pages/CreatePage", params: { remixPrompt: this.post!.prompt, remixTitle: "改编自: " + this.post!.title, remixAuthor: this.post!.author?.nickname } })
                    })
                }.width("100%").padding({ left: S_MD, right: S_MD, top: S_MD })
                Text(this.post!.prompt).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontFamily("monospace")
                  .padding(S_MD).width("100%").textAlign(TextAlign.Start).lineHeight(20)
              }
              .width("100%").backgroundColor("#F8F9FA").borderRadius(R_LG).borderWidth(1).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER)
              .margin({ left: S_LG, right: S_LG, top: S_LG })
            }

            // Action bar
            Row() {
              Row() {
                Text(this.isLiked ? "❤️" : "🤍").fontSize(22).scale({ x: this.likeAnimScale, y: this.likeAnimScale })
                Text(this.formatCount(this.likeCount)).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ left: S_XS })
              }.onClick(() => { this.toggleLike() })

              Row() {
                Text(this.isCollected ? "⭐" : "☆").fontSize(22).scale({ x: this.collectAnimScale, y: this.collectAnimScale })
                Text(this.formatCount(this.collectCount)).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ left: S_XS })
              }.margin({ left: 24 }).onClick(() => { this.toggleCollect() })

              Row() {
                Text("💬").fontSize(22)
                Text(this.comments.length.toString()).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ left: S_XS })
              }.margin({ left: 24 }).onClick(() => { this.showCommentInput = true })

              Blank()
            }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })

            Divider().color(this.isDark ? C_DARK_BORDER : C_BORDER).margin({ left: S_LG, right: S_LG, top: S_LG })

            // Comments section
            Text("评论 (" + this.comments.length + ")").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
              .width("100%").padding({ left: S_LG, top: S_LG })

            if (this.comments.length === 0) {
              Text("暂无评论，来说两句吧").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                .width("100%").textAlign(TextAlign.Center).padding({ top: 40, bottom: 40 })
            } else {
              ForEach(this.comments, (cmt: Comment) => {
                Column() {
                  Row() {
                    Text((cmt.author?.nickname ?? "用").charAt(0)).fontSize(15).fontColor("#FFF")
                      .width(32).height(32).borderRadius(16).textAlign(TextAlign.Center)
                      .backgroundColor(avatarColor(cmt.author?.nickname ?? ""))
                    Column() {
                      Row() {
                        Text(cmt.author?.nickname ?? "用户").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
                        Text(" · " + this.formatTime(cmt.createdAt)).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ left: S_XS })
                      }
                      if (cmt.replyTo) {
                        Text("↳ 回复").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                      }
                      Text(cmt.content).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).margin({ top: 2 }).width("100%")
                      Row() {
                        Text(cmt.liked ? "❤️" : "🤍").fontSize(14)
                          .onClick(() => this.toggleCommentLike(cmt))
                        Text(cmt.likeCount.toString()).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ left: S_XS, right: S_LG })
                        Text("回复").fontSize(F_CAPT).fontColor(C_PRIMARY)
                          .onClick(() => { this.replyToCommentId = cmt.id; this.replyToUserName = cmt.author?.nickname ?? "用户"; this.showCommentInput = true })
                      }.margin({ top: S_XS })
                    }.layoutWeight(1).margin({ left: S_SM }).alignItems(HorizontalAlign.Start)
                  }.width("100%")
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD })
              }, (cmt: Comment) => cmt.id)
            }

            // Similar posts
            if (this.similarPosts.length > 0) {
              Divider().color(this.isDark ? C_DARK_BORDER : C_BORDER).margin({ left: S_LG, right: S_LG, top: S_LG })
              Text("推荐帖子").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
                .width("100%").padding({ left: S_LG, top: S_LG })
              ForEach(this.similarPosts, (sp: Post) => {
                Row({ space: 10 }) {
                  Text(sp.title).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).maxLines(1).layoutWeight(1)
                  Text(this.formatCount(sp.likeCount)).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                  Text("›").fontSize(16).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: sp.id } }))
              }, (sp: Post) => sp.id)
            }

            Column().height(60)
          }.width("100%")
        }.layoutWeight(1).width("100%")

        // Bottom comment input
        if (this.showCommentInput) {
          Column() {
            if (this.replyToUserName) {
              Row() {
                Text("回复 @" + this.replyToUserName).fontSize(F_CAPT).fontColor(C_PRIMARY)
                Text(" ✕").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                  .onClick(() => { this.replyToCommentId = ""; this.replyToUserName = "" })
              }.padding({ left: S_LG, top: S_XS, bottom: S_XS }).width("100%")
            }
            Row() {
              TextInput({ placeholder: this.replyToUserName ? "回复 @" + this.replyToUserName + "..." : "写下你的评论...", text: this.commentText })
                .fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontSize(F_BODY).backgroundColor(C_CARD).borderRadius(20)
                .borderWidth(1).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER).layoutWeight(1).height(40).padding({ left: S_LG })
                .onChange((v: string) => { this.commentText = v })
                .onSubmit(() => { this.submitComment() })
              Text("发送").fontSize(F_BODY).fontColor(this.commentText.trim() ? C_PRIMARY : C_TEXT3)
                .margin({ left: S_MD }).fontWeight(FontWeight.Bold)
                .onClick(() => { this.submitComment() })
            }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM })
            .backgroundColor(C_CARD).borderWidth({ top: 0.5 }).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER)
          }.width("100%")
        }
      }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)

      // Report dialog
      if (this.showReportDialog) {
        Column() {
          Column({ space: 12 }) {
            Text("举报原因").fontSize(F_LG).fontWeight(FontWeight.Bold).fontColor(C_TEXT1)
            ForEach(this.reportReasons, (r: string) => {
              Text(r).fontSize(F_BODY).fontColor(C_PRIMARY).width("100%").textAlign(TextAlign.Center).padding({ top: S_MD, bottom: S_MD })
              .onClick(() => {
                getApi().reportPost(this.postId, r)
                promptAction.showToast({ message: "已举报", duration: 1000 })
                this.showReportDialog = false
              })
            }, (r: string) => r)
            Button("取消").fontSize(F_SM).backgroundColor(C_BG).fontColor(C_TEXT2).borderRadius(10).height(38).width("100%")
            .onClick(() => this.showReportDialog = false)
          }.width("80%").padding(20).backgroundColor(C_CARD).borderRadius(16)
        }.width("100%").height("100%").backgroundColor("#00000030").justifyContent(FlexAlign.Center)
        .onClick(() => this.showReportDialog = false)
      }

      // Delete confirm modal
      if (this.showDelete) {
        Column() {
          Column({ space: 14 }) {
            Text("确认删除").fontSize(F_LG).fontWeight(FontWeight.Bold).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1)
            Text("删除后无法恢复，确定要删除吗？").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).textAlign(TextAlign.Center)
            Row({ space: 12 }) {
              Button("取消").width("45%").height(42).backgroundColor(this.isDark ? C_DARK_BG : C_BG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).borderRadius(10)
                .onClick(() => this.showDelete = false)
              Button("确认删除").width("45%").height(42).backgroundColor(C_RED).fontColor("#FFF").borderRadius(10)
                .onClick(() => this.doDelete())
            }.width("100%").justifyContent(FlexAlign.Center)
          }.width("80%").padding(24).backgroundColor(C_CARD).borderRadius(16)
        }.width("100%").height("100%").backgroundColor("#00000030").justifyContent(FlexAlign.Center)
        .onClick(() => this.showDelete = false)
      }
    }
  }
}
