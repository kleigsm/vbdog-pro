import { router } from "@kit.ArkUI"
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
          Row({ space: 3 }) { Text("🔥").fontSize(12); Text("热门").fontSize(10).fontColor("#FFF") }.backgroundColor("#FF3B30").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }).position({ x: 8, y: 8 })
        }
      }.clip(true)
      Column({ space: 8 }) {
        Text(this.post.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.post.content).fontSize(12).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Row({ space: 4 }) {
            Text(this.post.author?.nickname?.charAt(0) ?? "用").fontSize(11).fontColor("#FFF").width(20).height(20).borderRadius(10).textAlign(TextAlign.Center).backgroundColor(this.getAvatarColor(this.post.author?.nickname ?? ""))
            Text(this.post.author?.nickname ?? "用户").fontSize(11).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).layoutWeight(1)
          }.layoutWeight(1)
          Row({ space: 3 }) { Text("❤️").fontSize(11); Text(this.formatCount(this.post.likeCount)).fontSize(10).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary) }
        }.width("100%")
      }.width("100%").padding({ left: 10, right: 10, top: 10, bottom: 12 })
    }.width("100%").backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).borderRadius(14).shadow({ radius: 6, color: this.isDark ? "#00000030" : COLORS.shadowCard, offsetY: 2 }).onClick(() => this.onCardClick?.())
  }

  randomHeight(): number { return 130 + ((this.post.title.length + this.post.content.length) % 6) * 18 }
  getGradientStart(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF6B35", "Skill": "#5856D6", "VibeCoding": "#34C759", "Tutorial": "#007AFF", "Tool": "#FF9500" }; return m[cat] ?? COLORS.primary }
  getGradientEnd(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF8C5A", "Skill": "#7B6CF6", "VibeCoding": "#5DDD7A", "Tutorial": "#4DA6FF", "Tool": "#FFB340" }; return m[cat] ?? COLORS.primaryLight }
  getCatBadge(cat: string): string { const m: Record<string, string> = { "Prompt": "💬 Prompt", "Skill": "🛠 Skill", "VibeCoding": "⚡ VibeCoding", "Tutorial": "📖 教程", "Tool": "🔧 工具" }; return m[cat] ?? ("📝 " + cat) }
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
        Row() { Text("离线模式 · " + this.offlineCount + " 个操作待同步").fontSize(12).fontColor("#FFF"); Blank(); Text("重试").fontSize(12).fontColor("#FFD700").fontWeight(FontWeight.Medium).onClick(() => this.retrySync()) }.width("100%").padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor("#FF9500")
      }
      Scroll() {
        Row({ space: 10 }) { ForEach(CATEGORIES, (cat: CategoryItem) => { Column() { Text(cat.icon).fontSize(20); Text(cat.label).fontSize(11).fontColor(this.activeCategory === cat.key ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)).fontWeight(this.activeCategory === cat.key ? FontWeight.Medium : FontWeight.Normal) }.padding({ left: 14, right: 14, top: 10, bottom: 10 }).borderRadius(20).backgroundColor(this.activeCategory === cat.key ? COLORS.primary + "14" : (this.isDark ? "#2A2A40" : "#F0F0F5")).border({ width: this.activeCategory === cat.key ? 1.5 : 0, color: this.activeCategory === cat.key ? COLORS.primary : Color.Transparent }).onClick(() => { this.activeCategory = cat.key; this.filter.category = cat.key; this.page = 0; this.loadPosts() }) }) }.padding({ left: 12, right: 12 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(60)
      Row({ space: 16 }) {
        Row() { Text("最新").fontSize(13).fontWeight(this.filter.sort === "latest" ? FontWeight.Medium : FontWeight.Normal).fontColor(this.filter.sort === "latest" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)) }.onClick(() => { this.filter.sort = "latest"; this.page = 0; this.loadPosts() })
        Row() { Text("最热").fontSize(13).fontWeight(this.filter.sort === "hot" ? FontWeight.Medium : FontWeight.Normal).fontColor(this.filter.sort === "hot" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)) }.onClick(() => { this.filter.sort = "hot"; this.page = 0; this.loadPosts() })
      }.width("100%").padding({ left: 16, top: 8, bottom: 8 })

      if (this.loading && this.posts.length === 0) {
        Row() { Column({ space: 12 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 8, right: 4 }); Column({ space: 12 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 4, right: 8 }) }.width("100%").layoutWeight(1)
      } else if (this.posts.length === 0) {
        Column({ space: 12 }) {
          Text("📭").fontSize(52)
          if (this.errorMsg) { Text("网络连接失败").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.error); Button("重试").fontSize(14).height(38).backgroundColor(COLORS.primary).fontColor("#FFF").borderRadius(19).margin({ top: 8 }).onClick(() => { this.errorMsg = ""; this.loadPosts() }) }
          else { Text("还没有帖子").fontSize(15).fontColor(COLORS.textSecondary); Text("快来发布第一条吧！").fontSize(13).fontColor(COLORS.textSecondary) }
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
    } catch (e) { const api = getApi() as SupabaseClient; api.setOnline(false); this.offlineCount = OfflineQueue.count; this.errorMsg = "请检查网络连接后重试" }
    finally { this.loading = false }
  }
  onPostClick(post: Post): void { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }) }
}
