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
        Column() {
          Text(this.getCatIcon(this.post.category)).fontSize(36)
        }
        .width("100%").height(120).borderRadius({ topLeft: R_LG, topRight: R_LG })
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [[this.getCatGradient(this.post.category)[0], 0], [this.getCatGradient(this.post.category)[1], 1]]
        })
        .justifyContent(FlexAlign.Center)

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
      if (this.post.images && this.post.images.length > 0) {
        Image(this.post.images[0]).width("100%").height(120).objectFit(ImageFit.Cover).borderRadius({ topLeft: R_LG, topRight: R_LG })
      }
      if (this.post.images && this.post.images.length > 0) {
        Image(this.post.images[0]).width("100%").height(120).objectFit(ImageFit.Cover).borderRadius({ topLeft: R_LG, topRight: R_LG })
      }
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
  @State leftPosts: Post[] = []
  @State rightPosts: Post[] = []
  @State errorMsg: string = ""

  aboutToAppear(): void {
    this.loadFeed()
  }

  filterPosts(catId: string): void {
    this.activeCat = catId
    this.loadFeed()
  }

  loadFeed(): void {
    this.loading = true; this.errorMsg = ""
    const sort = this.sortNew ? "latest" : "hot"
    const cat = this.activeCat === "all" ? undefined : this.activeCat
    getApi().getPosts(cat, sort, 0).then((newPosts: Post[]) => {
      this.posts = newPosts as Post[]
      this.distributePosts(this.posts)
    }).catch((_e: Error) => {
      this.errorMsg = "加载失败，请检查网络后重试"
      this.posts = []
    }).finally(() => {
      this.loading = false
    })
  }

  distributePosts(list: Post[]): void {
    this.leftPosts = []; this.rightPosts = []
    for (let i = 0; i < list.length; i++) {
      if (i % 2 === 0) this.leftPosts.push(list[i])
      else this.rightPosts.push(list[i])
    }
  }

  toggleSort(): void {
    this.sortNew = !this.sortNew; this.filterPosts(this.activeCat)
  }

  build() {
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
          Row() {
            List() {
              ForEach(this.leftPosts, (post: Post) => {
                ListItem() { PostCard({ post: post }) }.margin({ bottom: S_SM })
              }, (post: Post) => post.id)
            }.layoutWeight(1).padding({ left: S_MD, right: S_XS })

            List() {
              ForEach(this.rightPosts, (post: Post) => {
                ListItem() { PostCard({ post: post }) }.margin({ bottom: S_SM })
              }, (post: Post) => post.id)
            }.layoutWeight(1).padding({ left: S_XS, right: S_MD })
          }.layoutWeight(1).width("100%").padding({ top: S_SM })
        }
      }
      .onRefreshing(() => {
        this.isRefreshing = true
        this.loadFeed()
        setTimeout(() => { this.isRefreshing = false }, 1200)
      })
    }
    .width("100%").height("100%").backgroundColor(C_BG)
  }
}
