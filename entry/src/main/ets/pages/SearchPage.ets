import { getApi } from "../common/ApiProvider"
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
        Row({ space: 8 }) { Text(this.post.author?.nickname ?? "").fontSize(11).fontColor(COLORS.textSecondary); Row({ space: 2 }) { Text("❤️").fontSize(10); Text(this.post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) }; Row({ space: 2 }) { Text("💬").fontSize(10); Text(this.post.commentCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text("›").fontSize(16).fontColor(COLORS.textSecondary)
    }.width("100%").padding({ left: 14, right: 14, top: 12, bottom: 12 }).backgroundColor(COLORS.card).borderRadius(14).margin({ left: 12, right: 12, top: 4, bottom: 4 }).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: this.post.id } }))
  }
  getCatIcon(cat: string): string { const m: Record<string, string> = { "Prompt": "💬", "Skill": "🛠", "VibeCoding": "⚡", "Tutorial": "📖", "Tool": "🔧" }; return m[cat] ?? "📝" }
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
      Row({ space: 8 }) { TextInput({ placeholder: "搜索 Prompt、标题...", text: this.query }).layoutWeight(1).height(44).fontSize(15).backgroundColor("#F0F0F5").borderRadius(22).padding({ left: 18, right: 18 }).onChange((v: string) => { this.query = v }).onSubmit(() => this.doSearch()); Button("搜索").fontSize(14).height(40).backgroundColor(this.query.trim() ? COLORS.primary : "#CCC").borderRadius(20).fontColor("#FFF").padding({ left: 16, right: 16 }).enabled(this.query.trim().length > 0).onClick(() => this.doSearch()) }.width("100%").padding({ left: 12, right: 12, top: 12, bottom: 8 })
      if (this.searching) { LoadingProgress().width(32).height(32).margin({ top: 80 }) }
      else if (this.hasSearched && this.results.length === 0) { Column({ space: 12 }) { Text("🔍").fontSize(48); Text("没有找到相关帖子").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 80 }) }
      else if (this.hasSearched) { List() { ForEach(this.results, (post: Post) => { ListItem() { SearchResultCard({ post: post }) } }) }.layoutWeight(1) }
      else {
        Column() {
          if (this.history.length > 0) {
            Row() { Text("搜索历史").fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank(); Text("清空").fontSize(12).fontColor(COLORS.textSecondary).onClick(() => { this.history = []; this.saveHistory() }) }.width("100%").padding({ left: 16, right: 16, top: 16, bottom: 10 })
            Column({ space: 8 }) { ForEach(this.history, (h: string) => { Row() { Text(h).fontSize(13).fontColor(COLORS.textSecondary).layoutWeight(1).onClick(() => { this.query = h; this.doSearch() }); Text("✕").fontSize(12).fontColor(COLORS.textSecondary).onClick(() => { this.history = this.history.filter((i: string) => i !== h); this.saveHistory() }) }.width("100%").padding({ left: 16, right: 16, top: 10, bottom: 10 }).backgroundColor("#F0F0F5").borderRadius(12).margin({ left: 16, right: 16 }) }) }
          } else { Text("输入关键词搜索 Prompt 和帖子").fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 }) }
        }.width("100%")
      }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async doSearch(): Promise<void> { const q = this.query.trim(); if (!q) return; this.searching = true; this.hasSearched = true; try { this.results = await getApi().search(q); this.history = [q]; for (let i = 0; i < this.history.length; i++) { if (this.history[i] !== q) this.history.push(this.history[i]) }; this.history = this.history.slice(0, MAX_HISTORY); this.saveHistory() } catch (e) { this.results = [] } finally { this.searching = false } }
  loadHistory(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_search" }); this.history = JSON.parse(s.getSync(SEARCH_HISTORY_KEY, "[]") as string) as string[] } catch (e) { this.history = [] } }
  saveHistory(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_search" }); s.putSync(SEARCH_HISTORY_KEY, JSON.stringify(this.history)); s.flush() } catch (e) { } }
}
