/**
 * FeedPage — 发现页（瀑布流双列 + 分类筛选 + 排序）
 */

import { getApi } from "../common/ApiProvider"
import { Post, CATEGORIES, FeedFilter } from "../common/Models"
import { COLORS } from "../common/Constants"

@Component
struct PostCard {
  @Prop post: Post
  @ObjectLink filter: FeedFilter
  onCardClick: (post: Post) => void = () => {}

  build() {
    Column() {
      // 分类图标区
      Stack() {
        Column()
          .width("100%")
          .height(120)
          .linearGradient({
            angle: 135,
            colors: [[this.getCategoryColor(this.post.category), 0.0], [this.getCategoryColor(this.post.category) + "88", 1.0]]
          })

        if (this.post.likeCount > 50) {
          Text("🔥 热门")
            .fontSize(11)
            .fontColor("#FFFFFF")
            .backgroundColor("#FF3B30")
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 8 })
        }
      }
      .height(120)
      .clip(true)

      // 内容区
      Column({ space: 6 }) {
        Text(this.post.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.text)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.post.content)
          .fontSize(12)
          .fontColor(COLORS.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Row({ space: 4 }) {
            Text(this.post.author?.nickname ?? "用户")
              .fontSize(11)
              .fontColor(COLORS.textSecondary)
              .maxLines(1)
          }
          .layoutWeight(1)

          Row({ space: 3 }) {
            Text("❤️ " + this.formatCount(this.post.likeCount))
              .fontSize(10)
              .fontColor(COLORS.textSecondary)
          }
        }
        .width("100%")
        .margin({ top: 4 })
      }
      .width("100%")
      .padding(10)
    }
    .width("100%")
    .backgroundColor(COLORS.card)
    .borderRadius(12)
    .shadow({ radius: 4, color: "#00000010", offsetY: 2 })
    .onClick(() => this.onCardClick(this.post))
  }

  getCategoryColor(cat: string): string {
    const colors: Record<string, string> = {
      "Prompt": "#FF6B35", "Skill": "#5856D6", "VibeCoding": "#34C759",
      "Tutorial": "#007AFF", "Tool": "#FF9500"
    }
    return colors[cat] ?? COLORS.primary
  }

  formatCount(n: number): string {
    if (n >= 10000) return (n / 10000).toFixed(1) + "w"
    if (n >= 1000) return (n / 1000).toFixed(1) + "k"
    return n.toString()
  }
}

@Component
export struct FeedPage {
  @State posts: Post[] = []
  @State @Watch("onFilterChange") filter: FeedFilter = { category: "", sort: "latest" }
  @State loading: boolean = false
  @State refreshing: boolean = false
  @State activeCategory: string = ""
  @State page: number = 0

  @Link isLoggedIn: boolean

  aboutToAppear(): void {
    this.loadPosts()
  }

  build() {
    Column() {
      // 分类筛选栏
      Scroll() {
        Row({ space: 8 }) {
          ForEach(CATEGORIES, (cat: { key: string; label: string; icon: string }) => {
            Column({ space: 2 }) {
              Text(cat.icon)
                .fontSize(18)
              Text(cat.label)
                .fontSize(11)
                .fontColor(this.activeCategory === cat.key ? COLORS.primary : COLORS.textSecondary)
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(16)
            .backgroundColor(this.activeCategory === cat.key ? COLORS.primary + "18" : "#F0F0F5")
            .onClick(() => {
              this.activeCategory = cat.key
              this.filter.category = cat.key
              this.page = 0
              this.loadPosts()
            })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(60)

      // 排序切换
      Row({ space: 12 }) {
        Text("最新").fontSize(13).fontColor(this.filter.sort === "latest" ? COLORS.primary : COLORS.textSecondary).fontWeight(this.filter.sort === "latest" ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.filter.sort = "latest" })
        Text("最热").fontSize(13).fontColor(this.filter.sort === "hot" ? COLORS.primary : COLORS.textSecondary).fontWeight(this.filter.sort === "hot" ? FontWeight.Bold : FontWeight.Normal)
          .onClick(() => { this.filter.sort = "hot" })
      }
      .width("100%")
      .padding({ left: 16, top: 8, bottom: 8 })

      // 帖子列表
      if (this.loading && this.posts.length === 0) {
        LoadingProgress()
          .width(40).height(40)
          .margin({ top: 100 })
      } else if (this.posts.length === 0) {
        Column({ space: 12 }) {
          Text("📝").fontSize(48)
          Text("还没有帖子，快来发布第一条吧！").fontSize(14).fontColor(COLORS.textSecondary)
        }
        .width("100%")
        .margin({ top: 100 })
      } else {
        Row() {
          // 左列
          List({ space: 10 }) {
            ForEach(this.posts.filter((_: Post, i: number) => i % 2 === 0), (post: Post) => {
              ListItem() {
                PostCard({ post: post, filter: $filter, onCardClick: (p: Post) => this.onPostClick(p) })
              }
            })
          }
          .width("50%")
          .padding({ left: 8, right: 4 })
          .layoutWeight(1)

          // 右列
          List({ space: 10 }) {
            ForEach(this.posts.filter((_: Post, i: number) => i % 2 === 1), (post: Post) => {
              ListItem() {
                PostCard({ post: post, filter: $filter, onCardClick: (p: Post) => this.onPostClick(p) })
              }
            })
          }
          .width("50%")
          .padding({ left: 4, right: 8 })
          .layoutWeight(1)
        }
        .width("100%")
        .layoutWeight(1)
        .onScrollIndex((start: number) => {
          if (start > this.posts.length - 10 && !this.loading) {
            this.page++
            this.loadPosts(true)
          }
        })
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor(COLORS.background)
    .onRefresh(() => {
      this.page = 0
      this.loadPosts()
    })
  }

  async loadPosts(append: boolean = false) {
    this.loading = true
    try {
      const api = getApi()
      const newPosts = await api.getPosts(this.filter.category || undefined, this.filter.sort, append ? this.page : 0)
      if (append) {
        const existingIds = new Set(this.posts.map(p => p.id))
        const unique = newPosts.filter(p => !existingIds.has(p.id))
        this.posts = this.posts.concat(unique)
      } else {
        this.posts = newPosts
      }
    } catch (e) {
      console.error("Failed to load posts: " + JSON.stringify(e))
    } finally {
      this.loading = false
    }
  }

  onFilterChange(): void {
    this.page = 0
    this.loadPosts()
  }

  onPostClick(post: Post): void {
    // TODO: 跳转到帖子详情页
    console.info("Post clicked: " + post.id)
  }
}
