import { router } from "@kit.ArkUI"
import { getApi } from "../common/ApiProvider"
import { Post, CATEGORIES, CategoryItem, FeedFilter } from "../common/Models"
import { COLORS } from "../common/Constants"

@Component
struct PostCard {
  @Prop post: Post
  onCardClick?: () => void

  build() {
    Column() {
      Stack() {
        Column().width("100%").height(120).linearGradient({ angle: 135, colors: [[this.getColor(this.post.category), 0.0], [this.getColor(this.post.category) + "88", 1.0]] })
        if (this.post.likeCount > 50) { Text("🔥 热门").fontSize(11).fontColor("#FFF").backgroundColor("#FF3B30").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }).position({ x: 8, y: 8 }) }
      }.height(120).clip(true)

      Column({ space: 6 }) {
        Text(this.post.title).fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.text).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.post.content).fontSize(12).fontColor(COLORS.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() { Text(this.post.author?.nickname ?? "用户").fontSize(11).fontColor(COLORS.textSecondary).maxLines(1).layoutWeight(1); Text("❤️ " + this.formatCount(this.post.likeCount)).fontSize(10).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 4 })
      }.width("100%").padding(10)
    }.width("100%").backgroundColor(COLORS.card).borderRadius(12).shadow({ radius: 4, color: "#00000010", offsetY: 2 }).onClick(() => this.onCardClick?.())
  }

  getColor(cat: string): string { const m: Record<string, string> = { "Prompt": "#FF6B35", "Skill": "#5856D6", "VibeCoding": "#34C759", "Tutorial": "#007AFF", "Tool": "#FF9500" }; return m[cat] ?? COLORS.primary }

  formatCount(n: number): string { if (n >= 10000) return (n / 10000).toFixed(1) + "w"; if (n >= 1000) return (n / 1000).toFixed(1) + "k"; return n.toString() }
}

@Component
export struct FeedPage {
  @State posts: Post[] = []
  @State filter: FeedFilter = { category: "", sort: "latest" }
  @State loading: boolean = false
  @State activeCategory: string = ""
  @State page: number = 0

  aboutToAppear(): void { this.loadPosts() }

  build() {
    Column() {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(CATEGORIES, (cat: CategoryItem) => {
            Column({ space: 2 }) {
              Text(cat.icon).fontSize(18)
              Text(cat.label).fontSize(11).fontColor(this.activeCategory === cat.key ? COLORS.primary : COLORS.textSecondary)
            }.padding({ left: 12, right: 12, top: 8, bottom: 8 }).borderRadius(16).backgroundColor(this.activeCategory === cat.key ? COLORS.primary + "18" : "#F0F0F5").onClick(() => { this.activeCategory = cat.key; this.filter.category = cat.key; this.page = 0; this.loadPosts() })
          })
        }.padding({ left: 16, right: 16 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(60)

      Row({ space: 12 }) {
        Text("最新").fontSize(13).fontColor(this.filter.sort === "latest" ? COLORS.primary : COLORS.textSecondary).onClick(() => { this.filter.sort = "latest"; this.page = 0; this.loadPosts() })
        Text("最热").fontSize(13).fontColor(this.filter.sort === "hot" ? COLORS.primary : COLORS.textSecondary).onClick(() => { this.filter.sort = "hot"; this.page = 0; this.loadPosts() })
      }.width("100%").padding({ left: 16, top: 8, bottom: 8 })

      if (this.loading && this.posts.length === 0) { LoadingProgress().width(40).height(40).margin({ top: 100 }) }
      else if (this.posts.length === 0) {
        Column({ space: 12 }) { Text("📝").fontSize(48); Text("还没有帖子，快来发布第一条吧！").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 100 })
      } else {
        Row() {
          List({ space: 10 }) {
            ForEach(this.filteredPosts(0), (post: Post) => { ListItem() { PostCard({ post: post, onCardClick: () => this.onPostClick(post) }) } })
          }.width("50%").padding({ left: 8, right: 4 }).layoutWeight(1)
          List({ space: 10 }) {
            ForEach(this.filteredPosts(1), (post: Post) => { ListItem() { PostCard({ post: post, onCardClick: () => this.onPostClick(post) }) } })
          }.width("50%").padding({ left: 4, right: 8 }).layoutWeight(1)
        }.width("100%").layoutWeight(1)
      }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  filteredPosts(column: number): Post[] { const result: Post[] = []; for (let i = 0; i < this.posts.length; i++) { if (i % 2 === column) result.push(this.posts[i]) }; return result }

  async loadPosts(append: boolean = false): Promise<void> {
    this.loading = true
    try {
      const newPosts = await getApi().getPosts(this.filter.category || undefined, this.filter.sort, append ? this.page : 0)
      if (append) { const ids: Set<string> = new Set(); for (let i = 0; i < this.posts.length; i++) ids.add(this.posts[i].id); const toAdd: Post[] = []; for (let i = 0; i < newPosts.length; i++) { if (!ids.has(newPosts[i].id)) toAdd.push(newPosts[i]) }; this.posts = this.posts.concat(toAdd) }
      else { this.posts = newPosts }
    } catch (e) { /* ignore */ }
    finally { this.loading = false }
  }

  onPostClick(post: Post): void { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }) }
}
