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
        Column().width("100%").height(this.randomHeight()).linearGradient({ angle: 135, colors: [[this.getColor(this.post.category), 0.0], [this.getColor(this.post.category) + "88", 1.0]] })
        if (this.post.likeCount > 50) { Text("🔥 热门").fontSize(11).fontColor("#FFF").backgroundColor("#FF3B30").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }).position({ x: 8, y: 8 }) }
      }.clip(true)
      Column({ space: 6 }) {
        Text(this.post.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.post.content).fontSize(12).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() { Text(this.post.author?.nickname ?? "用户").fontSize(11).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary).maxLines(1).layoutWeight(1); Text("❤️ " + this.formatCount(this.post.likeCount)).fontSize(10).fontColor(this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary) }.width("100%").margin({ top: 4 })
      }.width("100%").padding(10)
    }.width("100%").backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).borderRadius(12).shadow({ radius: 4, color: "#00000010", offsetY: 2 }).onClick(() => this.onCardClick?.())
  }

  randomHeight(): number { const h: number = 120 + ((this.post.title.length + this.post.content.length) % 5) * 15; return h }
  getColor(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF6B35", "Skill": "#5856D6", "VibeCoding": "#34C759", "Tutorial": "#007AFF", "Tool": "#FF9500" }; return m[cat] ?? COLORS.primary }
  formatCount(n: number): string { if (n >= 10000) return (n / 10000).toFixed(1) + "w"; if (n >= 1000) return (n / 1000).toFixed(1) + "k"; return n.toString() }
}

@Component
struct SkeletonCard {
  @StorageLink("isDark") isDark: boolean = false
  build() {
    Column() {
      Column().width("100%").height(130).backgroundColor(this.isDark ? "#3A3A4A" : "#E5E5EA").borderRadius({ topLeft: 12, topRight: 12 })
      Column({ space: 8 }) { Column().width("70%").height(14).borderRadius(4).backgroundColor(this.isDark ? "#3A3A4A" : "#E5E5EA"); Column().width("90%").height(14).borderRadius(4).backgroundColor(this.isDark ? "#3A3A4A" : "#E5E5EA"); Column().width("40%").height(12).borderRadius(4).backgroundColor(this.isDark ? "#3A3A4A" : "#E5E5EA") }.width("100%").padding(10)
    }.width("100%").backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).borderRadius(12).opacity(0.6)
  }
}

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
        Row() { Text("离线模式 · " + this.offlineCount + " 个操作待同步").fontSize(12).fontColor("#FFF"); Blank(); Text("重试").fontSize(12).fontColor("#FFD700").onClick(() => this.retrySync()) }
        .width("100%").padding({ left: 16, right: 16, top: 6, bottom: 6 }).backgroundColor("#FF9500")
      }

      Scroll() {
        Row({ space: 8 }) {
          ForEach(CATEGORIES, (cat: CategoryItem) => {
            Column({ space: 2 }) { Text(cat.icon).fontSize(18); Text(cat.label).fontSize(11).fontColor(this.activeCategory === cat.key ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)) }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 }).borderRadius(16).backgroundColor(this.activeCategory === cat.key ? COLORS.primary + "18" : (this.isDark ? "#3A3A4A" : "#F0F0F5")).onClick(() => { this.activeCategory = cat.key; this.filter.category = cat.key; this.page = 0; this.loadPosts() })
          })
        }.padding({ left: 16, right: 16 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(60)

      Row({ space: 12 }) {
        Text("最新").fontSize(13).fontColor(this.filter.sort === "latest" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)).onClick(() => { this.filter.sort = "latest"; this.page = 0; this.loadPosts() })
        Text("最热").fontSize(13).fontColor(this.filter.sort === "hot" ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)).onClick(() => { this.filter.sort = "hot"; this.page = 0; this.loadPosts() })
      }.width("100%").padding({ left: 16, top: 8, bottom: 8 })

      if (this.loading && this.posts.length === 0) {
        Row() {
          Column({ space: 10 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 8, right: 4 })
          Column({ space: 10 }) { ForEach([0, 1, 2, 3], (_: number) => { SkeletonCard() }) }.width("50%").padding({ left: 4, right: 8 })
        }.width("100%").layoutWeight(1)
      } else if (this.posts.length === 0) {
        Column({ space: 12 }) {
          Text("📝").fontSize(48)
          if (this.errorMsg) {
            Text("网络连接失败").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.error)
            Text(this.errorMsg).fontSize(12).fontColor(COLORS.textSecondary).maxLines(3).textAlign(TextAlign.Center).padding({ left: 30, right: 30 })
            Button("重试").fontSize(14).height(36).backgroundColor(COLORS.primary).fontColor("#FFF").borderRadius(18).margin({ top: 8 }).onClick(() => { this.errorMsg = ""; this.loadPosts() })
          } else {
            Text("还没有帖子，快来发布第一条吧！").fontSize(14).fontColor(COLORS.textSecondary)
          }
        }.width("100%").margin({ top: 80 })
      } else {
        WaterFlow() { ForEach(this.posts, (post: Post) => { FlowItem() { PostCard({ post: post, onCardClick: () => this.onPostClick(post) }) } }) }.columnsTemplate("1fr 1fr").columnsGap(8).rowsGap(8).layoutWeight(1).padding({ left: 8, right: 8 })
      }
    }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
  }

  checkOffline(): void { this.offlineCount = OfflineQueue.count }

  async retrySync(): Promise<void> { try { await OfflineQueue.flush() } finally { this.offlineCount = OfflineQueue.count } }

  async loadPosts(append: boolean = false): Promise<void> {
    this.loading = true
    this.errorMsg = ""
    try {
      const newPosts: Post[] = await getApi().getPosts(this.filter.category || undefined, this.filter.sort, append ? this.page : 0) as Post[]
      if (append) { const ids: Set<string> = new Set(); for (let i = 0; i < this.posts.length; i++) ids.add(this.posts[i].id); const toAdd: Post[] = []; for (let i = 0; i < newPosts.length; i++) { if (!ids.has(newPosts[i].id)) toAdd.push(newPosts[i]) }; this.posts = this.posts.concat(toAdd) }
      else { this.posts = newPosts; this.checkOffline() }
    } catch (e) {
      const api = getApi() as SupabaseClient; api.setOnline(false); this.offlineCount = OfflineQueue.count
      const errObj: Object = e as Object
      this.errorMsg = JSON.stringify(e)
    }
    finally { this.loading = false }
  }

  onPostClick(post: Post): void { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }) }
}
