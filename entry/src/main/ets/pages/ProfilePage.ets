import { getApi } from "../common/ApiProvider"
import { Post, LEVELS, LevelItem } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"

@Entry
@Component
export struct ProfilePage {
  @State posts: Post[] = []
  @State loading: boolean = true
  @State activeTab: number = 0
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @StorageLink("isDark") isDark: boolean = false

  aboutToAppear(): void { this.loadData() }

  build() {
    Column() {
      Column({ space: 8 }) {
        Text(UserManager.currentUser?.nickname?.charAt(0) ?? "用")
          .fontSize(36).fontColor("#FFF").width(72).height(72).borderRadius(36).textAlign(TextAlign.Center)
          .backgroundColor(AVATAR_COLORS[(UserManager.currentUser?.nickname?.length ?? 0) % AVATAR_COLORS.length])
        Text(UserManager.currentUser?.nickname ?? "用户").fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text)

        this.levelProgress()

        if (UserManager.currentUser?.bio) { Text(UserManager.currentUser.bio).fontSize(13).fontColor(COLORS.textSecondary).maxLines(2) }
        Row({ space: 24 }) {
          this.statItem(this.posts.length.toString(), "帖子")
          this.statItem((UserManager.currentUser?.followingCount ?? 0).toString(), "关注")
          this.statItem((UserManager.currentUser?.followerCount ?? 0).toString(), "粉丝")
        }.margin({ top: 8 })

        Row({ space: 8 }) {
          Text("🌙 暗黑模式").fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text)
          Toggle({ type: ToggleType.Switch, isOn: this.isDark }).onChange((value: boolean) => { AppStorage.set("isDark", value) })
        }.padding({ top: 8 })

        Row({ space: 8 }) {
          Button("编辑资料").fontSize(13).height(32).backgroundColor(this.isDark ? "#3A3A4A" : "#F0F0F5").fontColor(this.isDark ? COLORS.textDark : COLORS.text).borderRadius(16)
          if (UserManager.currentUser?.phone === "00000000000") {
            Button("管理后台").fontSize(13).height(32).backgroundColor(COLORS.error + "14").fontColor(COLORS.error).borderRadius(16).onClick(() => router.pushUrl({ url: "pages/AdminPage" }))
          }
        }
      }.width("100%").padding({ top: 20, bottom: 16 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)

      Row({ space: 0 }) {
        Button("帖子").fontSize(14).fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 0 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 0; this.loadPosts() })
        Button("收藏").fontSize(14).fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 1 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 1; this.loadCollections() })
      }.width("100%").height(44)
      Divider().strokeWidth(0.5).color("#E5E5EA")

      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else if (this.posts.length === 0) { Text(this.activeTab === 0 ? "还没有发布帖子" : "还没有收藏帖子").fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 }) }
      else {
        List({ space: 1 }) {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(post.title).fontSize(14).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(1).layoutWeight(1)
                Text("❤️ " + post.likeCount + "  💬 " + post.commentCount).fontSize(11).fontColor(COLORS.textSecondary)
              }.width("100%").padding(14).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }))
            }
          })
        }.layoutWeight(1).backgroundColor(this.isDark ? "#1A1A2E" : "#F0F0F5")
      }

      Button("退出登录").fontSize(13).fontColor(COLORS.error).type(ButtonType.Normal).backgroundColor(Color.Transparent).width("100%").padding(14).onClick(() => { UserManager.clear(); AppStorage.set("isLoggedIn", false) })
    }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
  }

  @Builder levelProgress() {
    Column({ space: 4 }) {
      Text(this.getLevelTitle(UserManager.currentUser?.level ?? 1)).fontSize(11).fontColor(COLORS.primary)
      Row() {
        Row().width(this.expPercentStr()).height(4).backgroundColor(COLORS.primary).borderRadius(2)
        Row().width(this.expRemainStr()).height(4).backgroundColor("#E5E5EA").borderRadius(2)
      }.width(120).height(4).borderRadius(2)
      Text(this.expText()).fontSize(10).fontColor(COLORS.textSecondary)
    }.alignItems(HorizontalAlign.Center).margin({ bottom: 4 })
  }

  @Builder statItem(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text)
      Text(label).fontSize(11).fontColor(COLORS.textSecondary)
    }
  }

  expPercent(): number {
    const level: number = UserManager.currentUser?.level ?? 1
    const exp: number = UserManager.currentUser?.exp ?? 0
    const current: LevelItem | undefined = LEVELS.find((l: LevelItem) => l.level === level)
    const max: number = current ? current.max : 100
    return Math.min(100, Math.floor((exp / max) * 100))
  }

  expPercentStr(): string { return this.expPercent().toString() }

  expRemainStr(): string { return (100 - this.expPercent()).toString() }

  expText(): string {
    const level: number = UserManager.currentUser?.level ?? 1
    const exp: number = UserManager.currentUser?.exp ?? 0
    const current: LevelItem | undefined = LEVELS.find((l: LevelItem) => l.level === level)
    const max: number = current ? current.max : 100
    return exp.toString() + "/" + max.toString() + " XP"
  }

  getLevelTitle(level: number): string {
    const l: LevelItem | undefined = LEVELS.find((li: LevelItem) => li.level === level)
    return l ? l.title : ""
  }

  async loadData(): Promise<void> { this.loading = true; await this.loadPosts(); this.loading = false }

  async loadPosts(): Promise<void> {
    try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserPosts(uid) }
    catch (e) { this.posts = [] }
  }

  async loadCollections(): Promise<void> {
    this.loading = true
    try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserCollections(uid) }
    catch (e) { this.posts = [] }
    finally { this.loading = false }
  }
}
