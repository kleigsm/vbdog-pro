import os
base = r"D:\Projects\vbdog-pro\entry\src\main\ets\pages"

def w(rel, content):
    path = os.path.join(base, rel)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("OK " + rel)

# FeedPage
w("FeedPage.ets", '''import { router } from "@kit.ArkUI"
import { getApi } from "../common/ApiProvider"
import { SupabaseClient } from "../common/SupabaseClient"
import { OfflineQueue } from "../common/OfflineQueue"
import { Post, CATEGORIES, CategoryItem, FeedFilter } from "../common/Models"
import { COLORS } from "../common/Constants"

@Component
struct PostCard {
  @Prop post: Post
  @StorageLink("isDark") isDark: boolean = false
  onCardClick?: () => void

  build() {
    Column() {
      Stack() {
        Column().width("100%").height(this.randomHeight()).linearGradient({ angle: 150, colors: [[this.getGradientStart(this.post.category), 0], [this.getGradientEnd(this.post.category), 1]] })
        Column() {
          Text(this.getCatBadge(this.post.category)).fontSize(10).fontColor("#FFF").backgroundColor("rgba(0,0,0,0.25)").borderRadius(6).padding({ left: 8, right: 8, top: 3, bottom: 3 })
          Blank()
          Text(this.post.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor("#FFF").maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.width("100%").height("100%").alignItems(HorizontalAlign.Start).padding(12)
        if (this.post.likeCount > 50) {
          Row({ space: 3 }) { Text("\U0001F525").fontSize(12); Text("\u70ed\u95e8").fontSize(10).fontColor("#FFF") }.backgroundColor("#FF3B30").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }).position({ x: 8, y: 8 })
        }
      }.clip(true)
      Column({ space: 8 }) {
        Text(this.post.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.post.content).fontSize(12).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Row({ space: 4 }) {
            Text(this.post.author?.nickname?.charAt(0) ?? "\u7528").fontSize(11).fontColor("#FFF").width(20).height(20).borderRadius(10).textAlign(TextAlign.Center).backgroundColor(this.getAvatarColor(this.post.author?.nickname ?? ""))
            Text(this.post.author?.nickname ?? "\u7528\u6237").fontSize(11).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).layoutWeight(1)
          }.layoutWeight(1)
          Row({ space: 3 }) { Text("\u2764\ufe0f").fontSize(11); Text(this.formatCount(this.post.likeCount)).fontSize(10).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary) }
        }.width("100%")
      }.width("100%").padding({ left: 10, right: 10, top: 10, bottom: 12 })
    }.width("100%").backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).borderRadius(14).shadow({ radius: 6, color: this.isDark ? "#00000030" : COLORS.shadowCard, offsetY: 2 }).onClick(() => this.onCardClick?.())
  }

  randomHeight(): number { return 130 + ((this.post.title.length + this.post.content.length) % 6) * 18 }
  getGradientStart(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF6B35", "Skill": "#5856D6", "VibeCoding": "#34C759", "Tutorial": "#007AFF", "Tool": "#FF9500" }; return m[cat] ?? COLORS.primary }
  getGradientEnd(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF8C5A", "Skill": "#7B6CF6", "VibeCoding": "#5DDD7A", "Tutorial": "#4DA6FF", "Tool": "#FFB340" }; return m[cat] ?? COLORS.primaryLight }
  getCatBadge(cat: string): string { const m: Record<string, string> = { "Prompt": "\U0001F4AC Prompt", "Skill": "\U0001F6E0 Skill", "VibeCoding": "\u26a1 VibeCoding", "Tutorial": "\U0001F4D6 \u6559\u7a0b", "Tool": "\U0001F527 \u5de5\u5177" }; return m[cat] ?? ("\U0001F4DD " + cat) }
  getAvatarColor(nickname: string): string { const colors: string[] = ["#FF6B35", "#FF3B30", "#FF9500", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#00C7BE"]; return colors[nickname.length % colors.length] }
  formatCount(n: number): string { if (n >= 10000) return (n / 10000).toFixed(1) + "w"; if (n >= 1000) return (n / 1000).toFixed(1) + "k"; return n.toString() }
}

@Component
struct SkeletonCard {
  @StorageLink("isDark") isDark: boolean = false
  build() {
    Column() {
      Column().width("100%").height(140).backgroundColor(this.isDark ? "#2A2A40" : "#E8E8ED").borderRadius({ topLeft: 14, topRight: 14 })
      Column({ space: 10 }) { Column().width("60%").height(14).borderRadius(7).backgroundColor(this.isDark ? "#2A2A40" : "#E8E8ED"); Column().width("85%").height(12).borderRadius(6).backgroundColor(this.isDark ? "#2A2A40" : "#E8E8ED"); Column().width("35%").height(10).borderRadius(5).backgroundColor(this.isDark ? "#2A2A40" : "#E8E8ED") }.width("100%").padding({ left: 10, right: 10, top: 10, bottom: 12 })
    }.width("100%").backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).borderRadius(14).opacity(0.7)
  }
}

@Entry
@Component
export struct FeedPage {
  @State posts: Post[] = []
  @State filter: FeedFilter = { category: "", sort: "latest" }
  @State loading: boolean = false
  @State activeCategory: string = ""
  @State page: number = 0
  @State offlineCount: number = 0
  @State errorMsg: string = ""
  @StorageLink("isDark") isDark: boolean = false

  aboutToAppear(): void { OfflineQueue.init(); this.loadPosts(); this.checkOffline() }

  build() {
    Column() {
      if (this.offlineCount > 0) {
        Row() { Text("\u79bb\u7ebf\u6a21\u5f0f \u00b7 " + this.offlineCount + " \u4e2a\u64cd\u4f5c\u5f85\u540c\u6b65").fontSize(12).fontColor("#FFF"); Blank(); Text("\u91cd\u8bd5").fontSize(12).fontColor("#FFD700").fontWeight(FontWeight.Medium).onClick(() => this.retrySync()) }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor("#FF9500")
      }
      Scroll() {
        Row({ space: 10 }) { ForEach(CATEGORIES, (cat: CategoryItem) => { Column() { Text(cat.icon).fontSize(20); Text(cat.label).fontSize(11).fontColor(this.activeCategory === cat.key ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)).fontWeight(this.activeCategory === cat.key ? FontWeight.Medium : FontWeight.Normal) }.padding({ left: 14, right: 14, top: 10, bottom: 10 }).borderRadius(20).backgroundColor(this.activeCategory === cat.key ? COLORS.primary + "14" : (this.isDark ? "#2A2A40" : "#F0F0F5")).border({ width: this.activeCategory === cat.key ? 1.5 : 0, color: this.activeCategory === cat.key ? COLORS.primary : Color.Transparent }).onClick(() => { this.activeCategory = cat.key; this.filter.category = cat.key; this.page = 0; this.loadPosts() }) }) }.padding({ left: 12, right: 12 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(60)
      Row({ space: 16 }) {
        Row() { Text("\u6700\u65b0").fontSize(13).fontWeight(this.filter.sort === "latest" ? FontWeight.Medium : FontWeight.Normal).fontColor(this.filter.sort === "latest" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)) }.onClick(() => { this.filter.sort = "latest"; this.page = 0; this.loadPosts() })
        Row() { Text("\u6700\u70ed").fontSize(13).fontWeight(this.filter.sort === "hot" ? FontWeight.Medium : FontWeight.Normal).fontColor(this.filter.sort === "hot" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)) }.onClick(() => { this.filter.sort = "hot"; this.page = 0; this.loadPosts() })
      }.width("100%").padding({ left: 16, top: 8, bottom: 8 })

      if (this.loading && this.posts.length === 0) {
        Row() { Column({ space: 12 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 8, right: 4 }); Column({ space: 12 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 4, right: 8 }) }.width("100%").layoutWeight(1)
      } else if (this.posts.length === 0) {
        Column({ space: 12 }) {
          Text("\U0001F4ED").fontSize(52)
          if (this.errorMsg) { Text("\u7f51\u7edc\u8fde\u63a5\u5931\u8d25").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.error); Button("\u91cd\u8bd5").fontSize(14).height(38).backgroundColor(COLORS.primary).fontColor("#FFF").borderRadius(19).margin({ top: 8 }).onClick(() => { this.errorMsg = ""; this.loadPosts() }) }
          else { Text("\u8fd8\u6ca1\u6709\u5e16\u5b50").fontSize(15).fontColor(COLORS.textSecondary); Text("\u5feb\u6765\u53d1\u5e03\u7b2c\u4e00\u6761\u5427\uff01").fontSize(13).fontColor(COLORS.textSecondary) }
        }.width("100%").margin({ top: 80 })
      } else {
        WaterFlow() { ForEach(this.posts, (post: Post) => { FlowItem() { PostCard({ post: post, onCardClick: () => this.onPostClick(post) }) } }) }.columnsTemplate("1fr 1fr").columnsGap(10).rowsGap(10).layoutWeight(1).padding({ left: 8, right: 8 })
      }
    }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
  }

  checkOffline(): void { this.offlineCount = OfflineQueue.count }
  async retrySync(): Promise<void> { try { await OfflineQueue.flush() } finally { this.offlineCount = OfflineQueue.count } }
  async loadPosts(append: boolean = false): Promise<void> {
    this.loading = true; this.errorMsg = ""
    try {
      const newPosts: Post[] = await getApi().getPosts(this.filter.category || undefined, this.filter.sort, append ? this.page : 0) as Post[]
      if (append) { const ids: Set<string> = new Set(); for (let i = 0; i < this.posts.length; i++) ids.add(this.posts[i].id); const toAdd: Post[] = []; for (let i = 0; i < newPosts.length; i++) { if (!ids.has(newPosts[i].id)) toAdd.push(newPosts[i]) }; this.posts = this.posts.concat(toAdd) }
      else { this.posts = newPosts; this.checkOffline() }
    } catch (e) { const api = getApi() as SupabaseClient; api.setOnline(false); this.offlineCount = OfflineQueue.count; this.errorMsg = "\u8bf7\u68c0\u67e5\u7f51\u7edc\u8fde\u63a5\u540e\u91cd\u8bd5" }
    finally { this.loading = false }
  }
  onPostClick(post: Post): void { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }) }
}
''')

# AdminPage
w("AdminPage.ets", '''import { getApi } from "../common/ApiProvider"
import { Post } from "../common/Models"
import { COLORS } from "../common/Constants"
import { router } from "@kit.ArkUI"
import { promptAction } from "@kit.ArkUI"

interface DialogResult { index: number }

@Entry
@Component
export struct AdminPage {
  @State posts: Post[] = []
  @State loading: boolean = true
  @State userCount: number = 0
  @State postCount: number = 0
  @State deletingId: string = ""

  aboutToAppear(): void { this.loadData() }

  build() {
    Column() {
      Row() { Text("\u7ba1\u7406\u540e\u53f0").fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.text); Blank(); Text("Admin").fontSize(11).fontColor(COLORS.textSecondary).backgroundColor("#F0F0F5").borderRadius(4).padding({ left: 8, right: 8, top: 3, bottom: 3 }) }.width("100%").padding(16)
      Row({ space: 12 }) { this.statCard("\u7528\u6237\u6570", this.userCount.toString(), COLORS.primary); this.statCard("\u5e16\u5b50\u6570", this.postCount.toString(), COLORS.success) }.width("100%").padding({ left: 16, right: 16, bottom: 12 })
      Divider().strokeWidth(8).color("#F0F0F5")
      Row() { Text("\u6240\u6709\u5e16\u5b50").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank(); Text(this.postCount.toString() + " \u7bc7").fontSize(12).fontColor(COLORS.textSecondary) }.width("100%").padding(16)
      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else { List({ space: 1 }) { ForEach(this.posts, (post: Post) => { ListItem() { Row({ space: 12 }) { Column({ space: 2 }) { Text(post.title).fontSize(14).fontColor(COLORS.text).maxLines(1); Row({ space: 6 }) { Text("\u4f5c\u8005: " + (post.author?.nickname ?? "\u7528\u6237")).fontSize(11).fontColor(COLORS.textSecondary); Row({ space: 2 }) { Text("\u2764\ufe0f").fontSize(9); Text(post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } } }.alignItems(HorizontalAlign.Start).layoutWeight(1); if (this.deletingId === post.id) { LoadingProgress().width(20).height(20) } else { Text("\u5220\u9664").fontSize(12).fontColor(COLORS.error).backgroundColor(COLORS.error + "10").borderRadius(6).padding({ left: 10, right: 10, top: 4, bottom: 4 }).onClick(() => this.confirmDelete(post)) } }.width("100%").padding(14).backgroundColor(COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } })) } }) }.layoutWeight(1).backgroundColor("#F0F0F5") }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  @Builder statCard(label: string, value: string, color: string) { Column({ space: 6 }) { Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor(color); Text(label).fontSize(12).fontColor(COLORS.textSecondary) }.width("47%").padding(20).backgroundColor(COLORS.card).borderRadius(14).border({ width: { left: 3 }, color: color }) }

  async loadData(): Promise<void> { this.loading = true; try { const allPosts: Post[] = await getApi().getPosts("", "latest", 0); this.posts = allPosts; this.postCount = allPosts.length; this.userCount = 5 } catch (e) { } finally { this.loading = false } }
  confirmDelete(post: Post): void { promptAction.showDialog({ title: "\u786e\u8ba4\u5220\u9664", message: "\u5220\u9664\u5e16\u5b50\u300c" + post.title + "\u300d\uff1f", buttons: [{ text: "\u53d6\u6d88", color: "#999" }, { text: "\u5220\u9664", color: "#FF3B30" }] }).then((res: DialogResult) => { if (res.index === 1) this.doDelete(post) }) }
  async doDelete(post: Post): Promise<void> { this.deletingId = post.id; try { await getApi().deletePost(post.id); this.posts = this.posts.filter(p => p.id !== post.id); this.postCount-- } catch (e) { } finally { this.deletingId = "" } }
}
''')

# ProfilePage
w("ProfilePage.ets", '''import { getApi } from "../common/ApiProvider"
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
        Text(UserManager.currentUser?.nickname?.charAt(0) ?? "\u7528").fontSize(40).fontColor("#FFF").width(80).height(80).borderRadius(40).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(UserManager.currentUser?.nickname?.length ?? 0) % AVATAR_COLORS.length]).shadow({ radius: 12, color: COLORS.primary + "30", offsetY: 4 })
        Text(UserManager.currentUser?.nickname ?? "\u7528\u6237").fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text)
        Row({ space: 8 }) { Text(this.getLevelShortTitle(UserManager.currentUser?.level ?? 1)).fontSize(10).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "14").borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 }); Stack() { Row().width("100%").height(6).backgroundColor("#E5E5EA").borderRadius(3); Row().width(this.expPercent().toString() + "%").height(6).backgroundColor(COLORS.primary).borderRadius(3) }.layoutWeight(1); Text(UserManager.currentUser?.exp.toString() ?? "0").fontSize(10).fontColor(COLORS.textSecondary) }.width("70%")
        if (UserManager.currentUser?.bio) { Text(UserManager.currentUser.bio).fontSize(13).fontColor(COLORS.textSecondary).maxLines(2) }
        Row({ space: 0 }) { this.statItem(this.posts.length.toString(), "\u5e16\u5b50", COLORS.primary); this.statItem((UserManager.currentUser?.followingCount ?? 0).toString(), "\u5173\u6ce8", COLORS.accentPurple); this.statItem((UserManager.currentUser?.followerCount ?? 0).toString(), "\u7c89\u4e1d", COLORS.accentTeal) }.width("100%").margin({ top: 12 })
        Row({ space: 4 }) { Text(this.isDark ? "\u263e" : "\u2600").fontSize(14); Text("\u6697\u9ed1\u6a21\u5f0f").fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text) }.padding({ top: 10 })
        Toggle({ type: ToggleType.Switch, isOn: this.isDark }).onChange((value: boolean) => { AppStorage.set("isDark", value) })
        Row({ space: 8 }) { Button("\u7f16\u8f91\u8d44\u6599").fontSize(13).height(34).backgroundColor(this.isDark ? "#2A2A40" : "#F0F0F5").fontColor(this.isDark ? COLORS.textDark : COLORS.text).borderRadius(17); if (UserManager.currentUser?.phone === "00000000000") { Button("\u7ba1\u7406\u540e\u53f0").fontSize(13).height(34).backgroundColor(COLORS.error + "14").fontColor(COLORS.error).borderRadius(17).onClick(() => router.pushUrl({ url: "pages/AdminPage" })) } }
      }.width("100%").padding({ top: 24, bottom: 18 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)

      Row({ space: 0 }) { Button("\u5e16\u5b50").fontSize(14).fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 0 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 0; this.loadPosts() }); Button("\u6536\u85cf").fontSize(14).fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal).fontColor(this.activeTab === 1 ? COLORS.primary : COLORS.textSecondary).type(ButtonType.Normal).backgroundColor(Color.Transparent).layoutWeight(1).onClick(() => { this.activeTab = 1; this.loadCollections() }) }.width("100%").height(42)
      Divider().strokeWidth(0.5).color("#E5E5EA")

      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else if (this.posts.length === 0) { Text(this.activeTab === 0 ? "\u8fd8\u6ca1\u6709\u53d1\u5e03\u5e16\u5b50" : "\u8fd8\u6ca1\u6709\u6536\u85cf\u5e16\u5b50").fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 }) }
      else { List({ space: 1 }) { ForEach(this.posts, (post: Post) => { ListItem() { Row({ space: 12 }) { Text(post.title).fontSize(14).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(1).layoutWeight(1); Row({ space: 6 }) { Row({ space: 2 }) { Text("\u2764\ufe0f").fontSize(10); Text(post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) }; Row({ space: 2 }) { Text("\U0001F4AC").fontSize(10); Text(post.commentCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } }; if (post.userId === UserManager.currentUser?.id) { Text("\U0001F5D1").fontSize(14).fontColor(COLORS.error).onClick(() => this.deleteMyPost(post)) } }.width("100%").padding(14).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } })) } }) }.layoutWeight(1).backgroundColor(this.isDark ? "#16162A" : "#F0F0F5") }
      Button("\u9000\u51fa\u767b\u5f55").fontSize(13).fontColor(COLORS.error).type(ButtonType.Normal).backgroundColor(Color.Transparent).width("100%").padding(14).onClick(() => { UserManager.clear(); AppStorage.set("isLoggedIn", false) })
    }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
  }

  @Builder statItem(value: string, label: string, color: string) { Column({ space: 2 }) { Text(value).fontSize(22).fontWeight(FontWeight.Bold).fontColor(color); Text(label).fontSize(11).fontColor(COLORS.textSecondary) }.layoutWeight(1).alignItems(HorizontalAlign.Center) }
  async deleteMyPost(post: Post): Promise<void> { try { await getApi().deletePost(post.id); this.posts = this.posts.filter(p => p.id !== post.id) } catch (e) { } }
  expPercent(): number { const lv: number = UserManager.currentUser?.level ?? 1; const xp: number = UserManager.currentUser?.exp ?? 0; const lvl: LevelItem | undefined = LEVELS.find((l: LevelItem) => l.level === lv); const m: number = lvl ? lvl.max : 100; return Math.min(100, Math.floor((xp / m) * 100)) }
  getLevelShortTitle(level: number): string { const l: LevelItem | undefined = LEVELS.find((li: LevelItem) => li.level === level); return l ? l.title : "" }
  async loadData(): Promise<void> { this.loading = true; await this.loadPosts(); this.loading = false }
  async loadPosts(): Promise<void> { try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserPosts(uid) } catch (e) { this.posts = [] } }
  async loadCollections(): Promise<void> { this.loading = true; try { const uid = UserManager.currentUser?.id; if (uid) this.posts = await getApi().getUserCollections(uid) } catch (e) { this.posts = [] } finally { this.loading = false } }
}
''')

# SearchPage
w("SearchPage.ets", '''import { getApi } from "../common/ApiProvider"
import { Post } from "../common/Models"
import { COLORS } from "../common/Constants"
import { router } from "@kit.ArkUI"
import { preferences } from "@kit.ArkData"

const SEARCH_HISTORY_KEY: string = "search_history"
const MAX_HISTORY: number = 10

@Component
struct SearchResultCard {
  @Prop post: Post
  build() {
    Row({ space: 12 }) {
      Text(this.getCatIcon(this.post.category)).fontSize(32)
      Column({ space: 4 }) {
        Text(this.post.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.text).maxLines(1)
        Text(this.post.content).fontSize(12).fontColor(COLORS.textSecondary).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) { Text(this.post.author?.nickname ?? "").fontSize(11).fontColor(COLORS.textSecondary); Row({ space: 2 }) { Text("\u2764\ufe0f").fontSize(10); Text(this.post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) }; Row({ space: 2 }) { Text("\U0001F4AC").fontSize(10); Text(this.post.commentCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text("\u203a").fontSize(16).fontColor(COLORS.textSecondary)
    }.width("100%").padding({ left: 14, right: 14, top: 12, bottom: 12 }).backgroundColor(COLORS.card).borderRadius(14).margin({ left: 12, right: 12, top: 4, bottom: 4 }).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: this.post.id } }))
  }
  getCatIcon(cat: string): string { const m: Record<string, string> = { "Prompt": "\U0001F4AC", "Skill": "\U0001F6E0", "VibeCoding": "\u26a1", "Tutorial": "\U0001F4D6", "Tool": "\U0001F527" }; return m[cat] ?? "\U0001F4DD" }
}

@Entry
@Component
export struct SearchPage {
  @State query: string = ""
  @State results: Post[] = []
  @State history: string[] = []
  @State searching: boolean = false
  @State hasSearched: boolean = false

  aboutToAppear(): void { this.loadHistory() }

  build() {
    Column() {
      Row({ space: 8 }) { TextInput({ placeholder: "\u641c\u7d22 Prompt\u3001\u6807\u9898...", text: this.query }).layoutWeight(1).height(44).fontSize(15).backgroundColor("#F0F0F5").borderRadius(22).padding({ left: 18, right: 18 }).onChange((v: string) => { this.query = v }).onSubmit(() => this.doSearch()); Button("\u641c\u7d22").fontSize(14).height(40).backgroundColor(this.query.trim() ? COLORS.primary : "#CCC").borderRadius(20).fontColor("#FFF").padding({ left: 16, right: 16 }).enabled(this.query.trim().length > 0).onClick(() => this.doSearch()) }.width("100%").padding({ left: 12, right: 12, top: 12, bottom: 8 })
      if (this.searching) { LoadingProgress().width(32).height(32).margin({ top: 80 }) }
      else if (this.hasSearched && this.results.length === 0) { Column({ space: 12 }) { Text("\U0001F50D").fontSize(48); Text("\u6ca1\u6709\u627e\u5230\u76f8\u5173\u5e16\u5b50").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 80 }) }
      else if (this.hasSearched) { List() { ForEach(this.results, (post: Post) => { ListItem() { SearchResultCard({ post: post }) } }) }.layoutWeight(1) }
      else {
        Column() {
          if (this.history.length > 0) {
            Row() { Text("\u641c\u7d22\u5386\u53f2").fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank(); Text("\u6e05\u7a7a").fontSize(12).fontColor(COLORS.textSecondary).onClick(() => { this.history = []; this.saveHistory() }) }.width("100%").padding({ left: 16, right: 16, top: 16, bottom: 10 })
            Column({ space: 8 }) { ForEach(this.history, (h: string) => { Row() { Text(h).fontSize(13).fontColor(COLORS.textSecondary).layoutWeight(1).onClick(() => { this.query = h; this.doSearch() }); Text("\u2715").fontSize(12).fontColor(COLORS.textSecondary).onClick(() => { this.history = this.history.filter((i: string) => i !== h); this.saveHistory() }) }.width("100%").padding({ left: 16, right: 16, top: 10, bottom: 10 }).backgroundColor("#F0F0F5").borderRadius(12).margin({ left: 16, right: 16 }) }) }
          } else { Text("\u8f93\u5165\u5173\u952e\u8bcd\u641c\u7d22 Prompt \u548c\u5e16\u5b50").fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 }) }
        }.width("100%")
      }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async doSearch(): Promise<void> { const q = this.query.trim(); if (!q) return; this.searching = true; this.hasSearched = true; try { this.results = await getApi().search(q); this.history = [q]; for (let i = 0; i < this.history.length; i++) { if (this.history[i] !== q) this.history.push(this.history[i]) }; this.history = this.history.slice(0, MAX_HISTORY); this.saveHistory() } catch (e) { this.results = [] } finally { this.searching = false } }
  loadHistory(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_search" }); this.history = JSON.parse(s.getSync(SEARCH_HISTORY_KEY, "[]") as string) as string[] } catch (e) { this.history = [] } }
  saveHistory(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_search" }); s.putSync(SEARCH_HISTORY_KEY, JSON.stringify(this.history)); s.flush() } catch (e) { } }
}
''')

# NotificationsPage
w("NotificationsPage.ets", '''import { getApi } from "../common/ApiProvider"
import { VNotification } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { router } from "@kit.ArkUI"

@Entry
@Component
export struct NotificationsPage {
  @State notifications: VNotification[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadNotifications() }

  build() {
    Column() {
      Row() { Text("\u901a\u77e5").fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text); Blank(); if (this.notifications.some(n => !n.read)) { Text("\u5168\u90e8\u5df2\u8bfb").fontSize(13).fontColor(COLORS.primary).onClick(() => this.markAllRead()) } }.width("100%").padding(16)
      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 80 }) }
      else if (this.notifications.length === 0) { Column({ space: 12 }) { Text("\U0001F514").fontSize(48); Text("\u6682\u65e0\u901a\u77e5").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 80 }) }
      else { List({ space: 0 }) { ForEach(this.notifications, (n: VNotification) => { ListItem() { Row({ space: 10 }) { Text((n.fromUser?.nickname ?? "\u7528").charAt(0)).fontSize(16).fontColor("#FFF").width(42).height(42).borderRadius(21).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(n.fromUser?.nickname?.length ?? 0) % AVATAR_COLORS.length]).opacity(n.read ? 0.5 : 1); Column({ space: 3 }) { Row({ space: 6 }) { Text(this.getTypeIcon(n.type)).fontSize(14); Text(n.fromUser?.nickname ?? "").fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Text(this.getTypeLabel(n.type)).fontSize(11).fontColor(COLORS.textSecondary) }; Text(n.content).fontSize(13).fontColor(COLORS.textSecondary).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }); Text(this.formatTime(n.createdAt)).fontSize(11).fontColor(COLORS.textSecondary) }.alignItems(HorizontalAlign.Start).layoutWeight(1); if (!n.read) { Circle({ width: 8, height: 8 }).fill(COLORS.primary) } }.width("100%").padding(14).backgroundColor(n.read ? COLORS.card : (COLORS.primary + "08")).borderRadius(12).onClick(() => this.onNotificationTap(n)) } }) }.layoutWeight(1).padding({ left: 8, right: 8 }) }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async loadNotifications(): Promise<void> { this.loading = true; try { this.notifications = await getApi().getNotifications() } catch (e) { this.notifications = [] } finally { this.loading = false } }
  async markAllRead(): Promise<void> { for (const n of this.notifications) { if (!n.read) { try { await getApi().markNotificationRead(n.id); n.read = true } catch (e) { } } } }
  async onNotificationTap(n: VNotification): Promise<void> { if (!n.read) { try { await getApi().markNotificationRead(n.id); n.read = true } catch (e) { } }; if (n.relatedId && (n.type === "like" || n.type === "comment")) { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: n.relatedId } }) } }
  getTypeIcon(type: string): string { const m: Record<string, string> = { "like": "\u2764\ufe0f", "comment": "\U0001F4AC", "follow": "\U0001F441", "message": "\u2709\ufe0f" }; return m[type] ?? "\U0001F514" }
  getTypeLabel(type: string): string { const m: Record<string, string> = { "like": "\u8d5e\u4e86\u4f60", "comment": "\u8bc4\u8bba\u4e86\u4f60", "follow": "\u5173\u6ce8\u4e86\u4f60", "message": "\u53d1\u4e86\u6d88\u606f" }; return m[type] ?? "" }
  formatTime(t: string): string { if (!t) return ""; const d = new Date(t); const now = new Date(); const diff = now.getTime() - d.getTime(); if (diff < 60000) return "\u521a\u521a"; if (diff < 3600000) return Math.floor(diff / 60000) + "\u5206\u949f\u524d"; if (diff < 86400000) return Math.floor(diff / 3600000) + "\u5c0f\u65f6\u524d"; return (d.getMonth() + 1) + "-" + d.getDate() }
}
''')

print("ALL 5 PAGES DONE")