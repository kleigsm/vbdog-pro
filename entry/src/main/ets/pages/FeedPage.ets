import { C_PRIMARY, C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_BORDER, C_GLASS, S_XS, S_SM, S_MD, S_LG, S_XL, R_LG, F_CAPT, F_SM, F_BODY, CATEGORIES, Category } from "../common/Constants"
import { Post } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { OfflineQueue } from "../common/OfflineQueue"
import router from "@ohos.router"

@Component
struct PostCard {
  @ObjectLink post: Post

  getCatColor(cat: string): string {
    if (cat === "Prompt") return "#E3F2FD"
    if (cat === "Skill") return "#F3E5F5"
    if (cat === "VibeCoding") return "#E8F5E9"
    if (cat === "Tutorial") return "#FFF3E0"
    return "#ECEFF1"
  }

  getCatGradient(cat: string): [string, string] {
    if (cat === "Prompt") return ["#667eea", "#764ba2"]
    if (cat === "Skill") return ["#f093fb", "#f5576c"]
    if (cat === "VibeCoding") return ["#4facfe", "#00f2fe"]
    if (cat === "Tutorial") return ["#fa709a", "#fee140"]
    return ["#a8edea", "#fed6e3"]
  }

  getCatIcon(cat: string): string {
    if (cat === "Prompt") return "💬"
    if (cat === "Skill") return "🛠"
    if (cat === "VibeCoding") return "⚡"
    if (cat === "Tutorial") return "📉"
    return "🔡"
  }

  build() {
    Column() {
      Stack() {
        if (this.post.images && this.post.images.length > 0) {
          Image(this.post.images[0]).width("100%").height(120)
            .objectFit(ImageFit.Cover)
            .borderRadius({ topLeft: R_LG, topRight: R_LG })
        } else {
        Column() {
          Text(this.getCatIcon(this.post.category)).fontSize(36)
        }
        .width("100%").height(120).borderRadius({ topLeft: R_LG, topRight: R_LG })
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [[this.getCatGradient(this.post.category)[0], 0], [this.getCatGradient(this.post.category)[1], 1]]
        })
        .justifyContent(FlexAlign.Center)
        }

        if (this.post.likeCount > 5000) {
          Text("🔥 热门").fontSize(9).fontColor("#FFFFFF").fontWeight(FontWeight.Bold)
            .padding({ left: S_SM, right: S_SM, top: 2, bottom: 2 })
            .backgroundColor("#FF4757").borderRadius(8)
            .position({ x: "60%", y: 8 })
        }
      }

      Column() {
        Text(this.post.title).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width("100%").lineHeight(20)

        if (this.post.content) {
          Text(this.post.content).fontSize(F_CAPT).fontColor(C_TEXT3)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width("100%").margin({ top: S_XS })
        }

        Row() {
          Row() {
            Text(this.post.author?.nickname?.charAt(0) ?? "用").fontSize(11).fontColor("#FFF")
              .width(18).height(18).borderRadius(9).textAlign(TextAlign.Center)
              .backgroundColor(this.getAvatarColor(this.post.author?.nickname ?? ""))
            Text(this.post.author?.nickname ?? "用户").fontSize(F_CAPT).fontColor(C_TEXT3)
              .margin({ left: S_XS }).maxLines(1)
          }.flexShrink(1)
          .onClick(() => {
            if (this.post.userId) {
              router.pushUrl({ url: "pages/UserPage", params: { userId: this.post.userId } })
            }
          })
          Blank()
          Text(this.post.likeCount > 999 ? (this.post.likeCount / 1000).toFixed(1) + "k" : this.post.likeCount.toString())
            .fontSize(F_CAPT).fontColor(this.post.liked ? "#FF4757" : C_TEXT3)
          if (this.post.commentCount > 0) {
            Text("  💬" + this.post.commentCount).fontSize(F_CAPT).fontColor(C_TEXT3)
          }
        }.width("100%").margin({ top: S_SM })
      }
      .padding({ left: S_MD, right: S_MD, top: S_MD, bottom: S_MD }).alignItems(HorizontalAlign.Start).width("100%")
    }
    .width("100%").borderRadius(R_LG).backgroundColor(C_CARD)
    .shadow({ radius: 4, color: "#00000008", offsetY: 2 })
    .onClick(() => { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: this.post.id } }) })
  }

  getAvatarColor(nickname: string): string {
    const colors: string[] = ["#FF6B35", "#FF3B30", "#FF9500", "#34C759", "#007AFF", "#5856D6", "#AF52DE", "#00C7BE"]
    return colors[(nickname.length || 0) % colors.length]
  }
}

@Component
struct SkeletonCard {
  build() {
    Column() {
      Column().width("100%").height(120).backgroundColor("#E8E8ED").borderRadius({ topLeft: R_LG, topRight: R_LG })
      Column({ space: 10 }) {
        Column().width("60%").height(14).borderRadius(7).backgroundColor("#E8E8ED")
        Column().width("85%").height(12).borderRadius(6).backgroundColor("#E8E8ED")
        Column().width("35%").height(10).borderRadius(5).backgroundColor("#E8E8ED")
      }.width("100%").padding({ left: S_MD, right: S_MD, top: S_MD, bottom: S_MD })
    }.width("100%").backgroundColor(C_CARD).borderRadius(R_LG).opacity(0.7)
  }
}

@Entry
@Component
export struct FeedPage {
  @State posts: Post[] = []
  @State activeCat: string = "all"
  @State sortNew: boolean = true
  @State loading: boolean = false
  @State isRefreshing: boolean = false
  @State page: number = 1
  @State hasMore: boolean = true
  @State loadingMore: boolean = false
  @State leftPosts: Post[] = []
  @State rightPosts: Post[] = []
  @State errorMsg: string = ""
  @State showBackTop: boolean = false
  private feedScroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.loadFeed()
  }

  filterPosts(catId: string): void {
    this.activeCat = catId
    this.loadFeed(true)
  }

  loadFeed(reset: boolean = false): void {
    if (reset) { this.page = 1; this.hasMore = true }
    if (!this.hasMore) return
    this.loading = true; this.loadingMore = this.page > 1; this.errorMsg = ""
    const cat: string | undefined = this.activeCat === "all" ? undefined : this.activeCat
    const sort = this.sortNew ? "latest" : "hot"
    getApi().getPosts(cat, sort, this.page - 1).then((newPosts: Post[]) => {
      let list = newPosts as Post[]
      if (list.length < 20) this.hasMore = false
      if (this.page === 1) {
        this.posts = list
      } else {
        this.posts = this.posts.concat(list)
      }
      this.distributePosts(this.posts)
      this.page++
    }).catch((_e: Error) => {
      if (this.page === 1) { this.errorMsg = "load failed"; this.posts = [] }
    }).finally(() => {
      this.loading = false; this.loadingMore = false
    })
  }

  loadMore(): void {
    if (this.loadingMore) return
    this.loadFeed()
  }

  distributePosts(list: Post[]): void {
    this.leftPosts = []; this.rightPosts = []
    for (let i = 0; i < list.length; i++) {
      if (i % 2 === 0) this.leftPosts.push(list[i])
      else this.rightPosts.push(list[i])
    }
  }

  toggleSort(): void {
    this.sortNew = !this.sortNew; this.page = 1; this.hasMore = true; this.filterPosts(this.activeCat)
  }

  build() {
    Stack() {
    Column() {
      Row() {
        Scroll() {
          Row() {
            ForEach(CATEGORIES, (cat: Category) => {
              Text(cat.icon + " " + cat.name).fontSize(F_SM)
                .fontColor(this.activeCat === cat.id ? "#FFFFFF" : C_TEXT2)
                .fontWeight(this.activeCat === cat.id ? FontWeight.Bold : FontWeight.Normal)
                .padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM })
                .borderRadius(20).margin({ right: S_SM })
                .backgroundColor(this.activeCat === cat.id ? C_PRIMARY : C_GLASS)
                .onClick(() => { this.filterPosts(cat.id) })
            }, (cat: Category) => cat.id)
          }.padding({ left: S_LG })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1)
        Text(this.sortNew ? "最新" : "最热").fontSize(F_SM).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
          .padding({ left: S_MD, right: S_LG, top: S_SM, bottom: S_SM })
          .onClick(() => { this.toggleSort() })
      }.width("100%").padding({ top: S_SM, bottom: S_SM }).backgroundColor(C_CARD)

      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.loading && this.posts.length === 0) {
          Row() {
            List() {
              ForEach([0, 1, 2, 3], (_: number) => { ListItem() { SkeletonCard() }.margin({ bottom: S_SM }) })
            }.layoutWeight(1).padding({ left: S_MD, right: S_XS })
            List() {
              ForEach([0, 1, 2, 3], (_: number) => { ListItem() { SkeletonCard() }.margin({ bottom: S_SM }) })
            }.layoutWeight(1).padding({ left: S_XS, right: S_MD })
          }.layoutWeight(1).width("100%").padding({ top: S_SM })
        } else if (this.posts.length === 0 && !this.loading) {
          Column() {
            Text("📑").fontSize(48).margin({ bottom: S_MD })
            Text(this.errorMsg ? this.errorMsg : "还没有帖子").fontSize(F_BODY).fontColor(C_TEXT2)
            if (!this.errorMsg) {
              Text("快来发布第一条吧！").fontSize(F_CAPT).fontColor(C_TEXT3).margin({ top: S_XS })
            } else {
              Button("重试").fontSize(F_SM).height(36).backgroundColor(C_PRIMARY).fontColor("#FFF")
                .borderRadius(18).margin({ top: S_MD })
                .onClick(() => this.loadFeed())
            }
          }.layoutWeight(1).width("100%").justifyContent(FlexAlign.Center)
        } else {
          Column() {
            Row() {
              List({ scroller: this.feedScroller }) {
                ForEach(this.leftPosts, (post: Post) => {
                  ListItem() { PostCard({ post: post }) }.margin({ bottom: S_SM })
                }, (post: Post) => post.id)
              }.layoutWeight(1).padding({ left: S_MD, right: S_XS }).onReachEnd(() => { this.loadMore() }).onScroll((offset: number, state: ScrollState) => { this.showBackTop = offset > 300 })

              List({ scroller: this.feedScroller }) {
                ForEach(this.rightPosts, (post: Post) => {
                  ListItem() { PostCard({ post: post }) }.margin({ bottom: S_SM })
                }, (post: Post) => post.id)
              }.layoutWeight(1).padding({ left: S_XS, right: S_MD }).onReachEnd(() => { this.loadMore() })
            }.layoutWeight(1).width("100%").padding({ top: S_SM })
            if (this.loadingMore) {
              LoadingProgress().width(24).height(24).color(C_PRIMARY).margin({ top: S_MD, bottom: S_XS })
            }
            if (!this.hasMore && this.posts.length > 0) {
              Text("- END -").fontSize(F_CAPT).fontColor(C_TEXT3).width("100%").textAlign(TextAlign.Center).padding({ top: S_MD, bottom: S_LG })
            }
          }.layoutWeight(1).width("100%")
        }
      }
      .onRefreshing(() => {
        this.isRefreshing = true
        this.loadFeed(true)
        setTimeout(() => { this.isRefreshing = false }, 1200)
      })
    }
    .width("100%").height("100%").backgroundColor(C_BG)

    if (this.showBackTop) {
      Button() {
        Text("⬆").fontSize(20).fontColor("#FFFFFF")
      }
      .width(44).height(44).borderRadius(22)
      .backgroundColor(C_PRIMARY).shadow({ radius: 8, color: "#00000020", offsetY: 2 })
      .position({ x: "85%", y: "78%" })
      .onClick(() => {
        this.feedScroller.scrollToIndex(0)
        this.showBackTop = false
      })
    }
    }.width("100%").height("100%")
  }
}
