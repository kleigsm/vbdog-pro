import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, C_RED, S_SM, S_MD, S_LG, S_XL, R_LG, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { Post, Report, Comment, User } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"
import { promptAction } from "@kit.ArkUI"

interface DialogResult { index: number }

@Entry
@Component
export struct AdminPage {
  @StorageLink("isDark") isDark: boolean = false
  @State postCount: number = 0
  @State userCount: number = 0
  @State allPosts: Post[] = []
  @State loading: boolean = true
  @State deletingId: string = ""
  @State reports: Report[] = []
  @State allComments: Comment[] = []
  @State allUsers: User[] = []
  @State commentCount: number = 0
  @State deletingCommentId: string = ""

  aboutToAppear(): void {
    if (!UserManager.isAdmin) { router.back(); return }
    this.loadData()
    this.loadReports()
    this.loadAllComments()
    this.loadAllUsers()
  }

  async loadData(): Promise<void> {
    this.loading = true
    try {
      const allPosts: Post[] = await getApi().getPosts("", "latest", 0) as Post[]
      this.allPosts = allPosts; this.postCount = allPosts.length
    } catch (_e) { this.allPosts = []; this.postCount = 0 }
    finally { this.loading = false }
  }
  async loadReports(): Promise<void> {
    try { this.reports = await getApi().getReports() } catch (_e) { this.reports = [] }
  }
  async loadAllComments(): Promise<void> {
    try { this.allComments = await getApi().getAllComments(); this.commentCount = this.allComments.length }
    catch (_e) { this.allComments = []; this.commentCount = 0 }
  }
  async loadAllUsers(): Promise<void> {
    try { this.allUsers = await getApi().getAllUsers(); this.userCount = this.allUsers.length }
    catch (_e) { this.allUsers = []; this.userCount = 0 }
  }
  async handleReport(report: Report, action: string): Promise<void> {
    try {
      await getApi().resolveReport(report.id, action, report.postId)
      this.reports = this.reports.filter((r: Report) => r.id !== report.id)
    } catch (_e) { }
  }
  async doDeleteComment(commentId: string): Promise<void> {
    this.deletingCommentId = commentId
    try {
      await getApi().deleteComment(commentId)
      this.allComments = this.allComments.filter((c: Comment) => c.id !== commentId)
      this.commentCount--
    } catch (_e) { }
    finally { this.deletingCommentId = "" }
  }

  async doDelete(post: Post): Promise<void> {
    this.deletingId = post.id
    try {
      await getApi().deletePost(post.id)
      this.allPosts = this.allPosts.filter((p: Post) => p.id !== post.id)
      this.postCount--
    } catch (_e) { }
    finally { this.deletingId = "" }
  }

  confirmDelete(post: Post): void {
    promptAction.showDialog({
      title: "确认删除",
      message: "删除帖子《" + post.title + "》？",
      buttons: [{ text: "取消", color: "#999" }, { text: "删除", color: "#FF3B30" }]
    }).then((res: DialogResult) => { if (res.index === 1) this.doDelete(post) })
  }

  build() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1)
          .onClick(() => { router.back() })
        Text("🔰 管理后台").fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

      Scroll() {
        Column() {
          // Stats cards
          Row() {
            Column() {
              Text(this.postCount.toString()).fontSize(28).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("总帖子").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.width("48%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_LG)

            Column() {
              Text(this.userCount.toString()).fontSize(28).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("总用户").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.width("48%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_LG).margin({ left: "4%" })
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD })

          // Stats cards - Row 2
          Row() {
            Column() {
              Text(this.commentCount.toString()).fontSize(28).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("总评论").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.width("48%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_LG)

            Column() {
              Text(this.reports.length.toString()).fontSize(28).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("待处理举报").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.width("48%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_LG).margin({ left: "4%" })
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD })

          // Reports section
          Text("📋 举报管理 (" + this.reports.length + ")")
            .fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            .width("100%").padding({ left: S_LG, top: S_LG })
          if (this.reports.length === 0) {
            Text("暂无待处理举报").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
              .width("100%").textAlign(TextAlign.Center).padding({ top: 20, bottom: 20 })
          } else {
            ForEach(this.reports, (r: Report) => {
              Column() {
                Row() {
                  Text("🔔 " + r.reason).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium).layoutWeight(1)
                  Text(this.formatTime(r.createdAt)).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.width("100%")
                Row() {
                  Text("帖子: " + r.postId.substring(0, 12) + "...").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).layoutWeight(1).maxLines(1)
                  Button("忽略").fontSize(11).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2)
                    .backgroundColor(C_BG).borderRadius(12).height(28).padding({ left: S_MD, right: S_MD })
                    .onClick(() => { this.handleReport(r, "ignore") })
                  Button("删除帖子").fontSize(11).fontColor("#FFFFFF").backgroundColor(C_RED)
                    .borderRadius(12).height(28).padding({ left: S_MD, right: S_MD }).margin({ left: S_SM })
                    .onClick(() => { this.handleReport(r, "delete") })
                }.width("100%").margin({ top: S_SM })
              }
              .width("100%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_LG)
              .margin({ left: S_LG, right: S_LG, bottom: S_SM })
            }, (r: Report) => r.id)
          }

          // Post list
          Text("帖子管理").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            .width("100%").padding({ left: S_LG, top: S_LG })

          if (this.loading) {
            LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 60 })
          } else {
            ForEach(this.allPosts, (p: Post) => {
              Row() {
                Column() {
                  Text(p.title).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium).maxLines(1)
                  Text((p.author?.nickname ?? "用户") + " · " + p.likeCount + "赞 · " + this.formatTime(p.createdAt))
                    .fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if (this.deletingId === p.id) {
                  LoadingProgress().width(20).height(20)
                } else {
                  Button("删除").fontSize(11).fontColor("#FFFFFF").backgroundColor(C_RED)
                    .borderRadius(12).height(28).padding({ left: S_MD, right: S_MD })
                    .onClick(() => this.confirmDelete(p))
                }
              }.width("100%").padding(S_LG)
            }, (p: Post) => p.id)
          }

          // Comments section
          Text("💬 评论管理 (" + this.commentCount + ")")
            .fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            .width("100%").padding({ left: S_LG, top: S_LG })
          if (this.allComments.length === 0) {
            Text("暂无评论").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
              .width("100%").textAlign(TextAlign.Center).padding({ top: 20, bottom: 20 })
          } else {
            ForEach(this.allComments, (c: Comment) => {
              Row() {
                Column() {
                  Text((c.content.length > 40 ? c.content.substring(0, 40) + "..." : c.content))
                    .fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium).maxLines(1)
                  Text((c.author?.nickname ?? "用户") + " · " + this.formatTime(c.createdAt))
                    .fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if (this.deletingCommentId === c.id) {
                  LoadingProgress().width(20).height(20)
                } else {
                  Button("删除").fontSize(11).fontColor("#FFFFFF").backgroundColor(C_RED)
                    .borderRadius(12).height(28).padding({ left: S_MD, right: S_MD })
                    .onClick(() => this.doDeleteComment(c.id))
                }
              }.width("100%").padding(S_LG)
            }, (c: Comment) => c.id)
          }

          // Users section
          Text("👤 用户管理 (" + this.userCount + ")")
            .fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            .width("100%").padding({ left: S_LG, top: S_LG })
          if (this.allUsers.length === 0) {
            Text("暂无用户").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
              .width("100%").textAlign(TextAlign.Center).padding({ top: 20, bottom: 20 })
          } else {
            ForEach(this.allUsers, (u: User) => {
              Row() {
                Text(u.nickname).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
                  .layoutWeight(1).maxLines(1)
                Text("Lv." + u.level).fontSize(F_CAPT).fontColor(C_PRIMARY).width(50)
                Text(u.postCount + "帖").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).width(50)
              }.width("100%").padding(S_LG)
            }, (u: User) => u.id)
          }

          // Reports section
          if (this.reports.length > 0) {
            Text("举报处理 (" + this.reports.length + ")").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
              .width("100%").padding({ left: S_LG, top: S_LG })
            ForEach(this.reports, (r: Report) => {
              Row() {
                Column() {
                  Text(r.reason ?? "举报").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
                  Text(r.postId).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button("忽略").fontSize(11).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)
                  .borderRadius(12).height(28).padding({ left: S_MD, right: S_MD })
                  .onClick(() => this.handleReport(r, "dismiss"))
                Button("删帖").fontSize(11).fontColor("#FFFFFF").backgroundColor(C_RED)
                  .borderRadius(12).height(28).margin({ left: S_SM }).padding({ left: S_MD, right: S_MD })
                  .onClick(() => this.handleReport(r, "delete"))
              }.width("100%").padding(S_LG)
            }, (r: Report) => r.id)
          }

          Column().height(40)
        }.width("100%")
      }.layoutWeight(1).width("100%")
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }

  formatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    return (d.getMonth() + 1) + "-" + d.getDate()
  }
}
