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
        Text(UserManager.currentUser?.nickname?.charAt(0) ?? "用").fontSize(40).fontColor("#FFF").width(80).height(80).borderRadius(40).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(UserManager.currentUser?.nickname?.length ?? 0) % AVATAR_COLORS.length]).shadow({ radius: 12, color: COLORS.primary + "30", offsetY: 4 })
        Text(UserManager.currentUser?.nickname ?? "用户").fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text)
        Row({ space: 8 }) {
          Text(this.getLevelShortTitle(UserManager.currentUser?.level ?? 1)).fontSize(10).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "14").borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })
          Stack() { Row().width("100%").height(6).backgroundColor("#E5E5EA").borderRadius(3); Row().width(this.expPercent().toString() + "%").height(6).backgroundColor(COLORS.primary).borderRadius(3) }.layoutWeight(1)
          Text(UserManager.currentUser?.exp.toString() ?? "0").fontSize(10).fontColor(COLORS.textSecondary)
        }.width("70%")
        if (UserManager.currentUser?.bio) { Text(UserManager.currentUser.bio).fontSize(13).fontColor(COLORS.textSecondary).maxLines(2) }
        Row({ space: 0 }) { this.statItem(this.posts.length.toString(), "帖子", COLORS.primary); this.statItem((UserManager.currentUser?.followingCount ?? 0).toString(), "关注", COLORS.accentPurple); this.statItem((UserManager.currentUser?.followerCount ?? 0).toString(), "粉丝", COLORS.accentTeal) }.width("100%").margin({ top: 12 })
        Row({ space: 4 }) { Text(this.isDark ? "\u263e" : "\u2600").fontSize(14); Text("暗黑模式").fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text) }.padding({ top: 10 })
        Toggle({ type: ToggleType.Switch, isOn: this.isDark }).onChange((value: boolean) => { AppStorage.set("isDark", value) })
        Row({ space: 8 }) { Button("编辑资料").fontSize(13).height(34).backgroundColor(this.isDark ? "#2A2A40" : "#F0F0F5").fontColor(this.isDark ? COLORS.textDark : COLORS.text).borderRadius(17); if (UserManager.currentUser?.phone === "00000000000") { Button("管理后台").fontSize(13).height(34).backgroundColor(COLORS.error + "14").fontColor(COLORS.error).borderRadius(17).onClick(() => router.pushUrl({ url: "pages/AdminPage" })) } }
      }.width("100%").padding({ top: 24, bottom: 18 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)

      Row({ space: 0 }) { Button("帖子").fontSize(14).fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 0 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 0; this.loadPosts() }); Button("收藏").fontSize(14).fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 1 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 1; this.loadCollections() }) }.width("100%").height(42)
      Divider().strokeWidth(0.5).color("#E5E5EA")

      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else if (this.posts.length === 0) { Text(this.activeTab === 0 ? "还没有发布帖子" : "还没有收藏帖子").fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 }) }
      else { List({ space: 1 }) { ForEach(this.posts, (post: Post) => { ListItem() { Row({ space: 12 }) { Text(post.title).fontSize(14).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(1).layoutWeight(1); Row({ space: 6 }) { Row({ space: 2 }) { Text("❤️").fontSize(10); Text(post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) }; Row({ space: 2 }) { Text("💬").fontSize(10); Text(post.commentCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } }; if (post.userId === UserManager.currentUser?.id) { Text("\U0001F5D1").fontSize(14).fontColor(COLORS.error).onClick(() => this.deleteMyPost(post)) } }.width("100%").padding(14).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } })) } }) }.layoutWeight(1).backgroundColor(this.isDark ? "#16162A" : "#F0F0F5") }

      Button("退出登录").fontSize(13).fontColor(COLORS.error).type(ButtonType.Normal).backgroundColor(Color.Transparent).width("100%").padding(14).onClick(() => { UserManager.clear(); AppStorage.set("isLoggedIn", false) })
    }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
  }

  @Builder statItem(value: string, label: string, color: string) { Column({ space: 2 }) { Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor(color); Text(label).fontSize(11).fontColor(COLORS.textSecondary) }.layoutWeight(1).alignItems(HorizontalAlign.Center) }
  async deleteMyPost(post: Post): Promise<void> { try { await getApi().deletePost(post.id); this.posts = this.posts.filter(p => p.id !== post.id) } catch (e) { /* ignore */ } }
  expPercent(): number { const lv: number = UserManager.currentUser?.level ?? 1; const xp: number = UserManager.currentUser?.exp ?? 0; const lvl: LevelItem | undefined = LEVELS.find((l: LevelItem) => l.level === lv); const m: number = lvl ? lvl.max : 100; return Math.min(100, Math.floor((xp / m) * 100)) }
  getLevelShortTitle(level: number): string { const l: LevelItem | undefined = LEVELS.find((li: LevelItem) => li.level === level); return l ? l.title : "" }
  async loadData(): Promise<void> { this.loading = true; await this.loadPosts(); this.loading = false }
  async loadPosts(): Promise<void> { try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserPosts(uid) } catch (e) { this.posts = [] } }
  async loadCollections(): Promise<void> { this.loading = true; try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserCollections(uid) } catch (e) { this.posts = [] } finally { this.loading = false } }
}