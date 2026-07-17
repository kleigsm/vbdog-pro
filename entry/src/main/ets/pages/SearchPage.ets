import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, C_DARK_BORDER, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, R_LG, F_SM, F_BODY, HOT_TAGS, VTag } from "../common/Constants"
import { Post } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import router from "@ohos.router"
import { preferences } from "@kit.ArkData"

@Entry
@Component
export struct SearchPage {
  @StorageLink("isDark") isDark: boolean = false
  @State query: string = ""
  @State results: Post[] = []
  @State history: string[] = []
  @State showResults: boolean = false
  @State searching: boolean = false
  private prefs: preferences.Preferences | null = null

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params["query"]) {
      const q = params["query"] as string
      if (q) { this.query = q; this.doSearch(q) }
    }
    const ctx = this.getUIContext().getHostContext()
    if (ctx) {
      preferences.getPreferences(ctx, "vbdog_search").then((p: preferences.Preferences) => {
        this.prefs = p
        p.get("history", "").then((v: preferences.ValueType) => {
          const s = v as string; if (s) { try { this.history = JSON.parse(s) as string[] } catch (_e) { } }
        })
      })
    }
  }

  doSearch(q: string): void {
    if (!q.trim()) return
    this.query = q; this.showResults = true; this.searching = true
    getApi().search(q).then((posts: Post[]) => {
      this.results = posts as Post[]
    }).catch(() => {
      this.results = []
    }).finally(() => { this.searching = false })
    if (!this.history.includes(q)) {
      this.history = [q, ...this.history].slice(0, 10); this.saveHistory()
    }
  }

  clearHistory(): void { this.history = []; this.saveHistory() }

  saveHistory(): void {
    if (this.prefs) this.prefs.put("history", JSON.stringify(this.history))
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text("🔍").fontSize(16).margin({ right: S_SM })
          TextInput({ placeholder: "搜索 prompt、skill、标题...", text: this.query })
            .placeholderColor(C_TEXT3).fontColor(C_TEXT1).fontSize(F_BODY)
            .backgroundColor(Color.Transparent).layoutWeight(1).height(40)
            .onChange((v: string) => { this.query = v }).onSubmit(() => { this.doSearch(this.query) })
        }
        .layoutWeight(1).backgroundColor(C_CARD).borderRadius(22).borderWidth(1).borderColor(C_BORDER)
        .padding({ left: S_LG }).height(42)

        if (this.showResults) {
          Text("取消").fontSize(F_SM).fontColor(C_PRIMARY).margin({ left: S_MD })
            .onClick(() => { this.showResults = false; this.query = ""; this.results = [] })
        }
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM }).backgroundColor(C_CARD)

      if (this.showResults) {
        if (this.searching) {
          LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 80 })
        } else if (this.results.length === 0) {
          Column() {
            Text("🔍").fontSize(48).margin({ bottom: S_MD })
            Text("没有找到相关内容").fontSize(F_BODY).fontColor(C_TEXT2)
          }.width("100%").margin({ top: 80 })
        } else {
          List() {
            ForEach(this.results, (post: Post) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(post.title).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Medium).maxLines(1).width("100%")
                    Row() {
                      Text(post.author?.nickname ?? "用户").fontSize(F_SM).fontColor(C_TEXT3)
                      Text(" · " + post.likeCount + "赞").fontSize(F_SM).fontColor(C_TEXT3)
                    }.margin({ top: 2 })
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Text(this.getCatIcon(post.category)).fontSize(20)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }) })
              }
            }, (post: Post) => post.id)
          }.layoutWeight(1).width("100%")
        }
      } else {
        Column() {
          if (this.history.length > 0) {
            Row() {
              Text("搜索历史").fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Bold).layoutWeight(1)
              Text("清除").fontSize(F_SM).fontColor(C_TEXT3).onClick(() => { this.clearHistory() })
            }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
            Row() {
              ForEach(this.history.slice(0, 6), (h: string) => {
                Text(h).fontSize(F_SM).fontColor(C_TEXT2)
                  .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM })
                  .backgroundColor(C_CARD).borderRadius(16).margin({ right: S_SM, bottom: S_SM })
                  .onClick(() => { this.doSearch(h) })
              }, (h: string) => h)
            }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM })
          }

          Text("热门标签").fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
            .width("100%").padding({ left: S_LG, top: S_LG })
          Row() {
            ForEach(HOT_TAGS, (t: VTag) => {
              Text((t.hot ? "🔥 " : "") + t.name).fontSize(F_SM).fontColor(C_TEXT2)
                .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM })
                .backgroundColor(C_CARD).borderRadius(16).margin({ right: S_SM, bottom: S_SM })
                .onClick(() => { this.doSearch(t.name) })
            }, (t: VTag) => t.id)
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM })
        }.width("100%")
      }
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }

  getCatIcon(cat: string): string {
    if (cat === "Prompt") return "💬"
    if (cat === "Skill") return "🛠"
    if (cat === "VibeCoding") return "⚡"
    if (cat === "Tutorial") return "📉"
    return "📑"
  }
}
