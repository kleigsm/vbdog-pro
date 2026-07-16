import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, S_XS, S_SM, S_MD, S_LG, S_XL, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { Post } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"

@Entry
@Component
struct CollectionPage {
  @State posts: Post[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadData() }

  async loadData(): Promise<void> {
    this.loading = true
    const uid = UserManager.currentUser?.id
    if (!uid) { this.loading = false; return }
    try {
      this.posts = await getApi().getUserCollections(uid) as Post[]
    } catch (_e) { this.posts = [] }
    finally { this.loading = false }
  }

  async remove(id: string): Promise<void> {
    try {
      await getApi().collectPost(id)
      this.posts = this.posts.filter((p: Post) => p.id !== id)
    } catch (_e) { }
  }

  build() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(C_TEXT1)
          .onClick(() => { router.back() })
        Text("我的收藏").fontSize(F_LG).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      if (this.loading) {
        LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 80 })
      } else if (this.posts.length === 0) {
        Column() {
          Text("⭐").fontSize(48).margin({ bottom: S_MD })
          Text("还没有收藏").fontSize(F_BODY).fontColor(C_TEXT2)
          Text("去发现好内容吧！").fontSize(F_CAPT).fontColor(C_TEXT3).margin({ top: S_XS })
        }.layoutWeight(1).width("100%").justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.posts, (p: Post) => {
            ListItem() {
              Row() {
                Text("⭐").fontSize(18).margin({ right: S_MD })
                Text(p.title).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Medium).maxLines(1).layoutWeight(1)
                Text(p.author?.nickname ?? "").fontSize(F_CAPT).fontColor(C_TEXT3).margin({ right: S_MD })
                Button("×").fontSize(F_LG).fontColor(C_TEXT3).backgroundColor(Color.Transparent).width(32).height(32)
                  .onClick(() => { this.remove(p.id) })
              }.width("100%").padding({ left: S_LG, right: S_MD, top: S_MD, bottom: S_MD })
              .onClick(() => { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: p.id } }) })
            }
          }, (p: Post) => p.id)
        }.layoutWeight(1).width("100%")
      }
    }.width("100%").height("100%").backgroundColor(C_BG)
  }
}
