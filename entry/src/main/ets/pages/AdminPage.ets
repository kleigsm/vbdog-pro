import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, C_RED, S_SM, S_MD, S_LG, S_XL, R_LG, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { Post, Report } from "../common/Models"
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
  @State userCount: number = 5
  @State allPosts: Post[] = []
  @State loading: boolean = true
  @State deletingId: string = ""
  @State reports: Report[] = []

  aboutToAppear(): void {
    if (!UserManager.isAdmin) { router.back(); return }
    this.loadData()
    this.loadReports()
  }

  async loadData(): Promise<void> {
    this.loading = true
    try {
      const allPosts: Post[] = await getApi().getPosts("", "latest", 0) as Post[]
      this.allPosts = allPosts; this.postCount = allPosts.length
    } catch (_e) { this.allPosts = [] }
    finally { this.loading = false }
  }
  async loadReports(): Promise<void> {
    try { this.reports = await getApi().getReports() } catch (_e) { this.reports = [] }
  }
  async handleReport(report: Report, action: string): Promise<void> {
    try {
      await getApi().resolveReport(report.id, action, report.postId)
      this.reports = this.reports.filter((r: Report) => r.id !== report.id)
    } catch (_e) { }
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
