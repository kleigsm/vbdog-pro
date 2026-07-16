import { getApi } from "../common/ApiProvider"
import { CATEGORIES, CategoryItem } from "../common/Models"
import { COLORS } from "../common/Constants"
import { promptAction, router } from "@kit.ArkUI"
import { preferences } from "@kit.ArkData"

const MODELS: string[] = ["Claude", "ChatGPT", "Copilot", "Gemini", "Other"]
const DRAFT_KEY: string = "create_draft"

@Entry
@Component
export struct CreatePage {
  @State title: string = ""
  @State content: string = ""
  @State prompt: string = ""
  @State category: string = "Prompt"
  @State model: string = "Claude"
  @State submitting: boolean = false
  @State remixLabel: string = ""
  @State isEditMode: boolean = false
  private editPostId: string = ""
  private draftTimer: number = -1

  aboutToAppear(): void {
    const params: Object = router.getParams() as Object
    if (params) {
      const p: Record<string, string> = params as Record<string, string>
      if (p["editPostId"]) {
        this.editPostId = p["editPostId"]; this.isEditMode = true
        if (p["editTitle"]) this.title = p["editTitle"]
        if (p["editContent"]) this.content = p["editContent"]
        if (p["editPrompt"]) this.prompt = p["editPrompt"]
        if (p["editCategory"]) this.category = p["editCategory"]
        if (p["editModel"]) this.model = p["editModel"]
        return
      }
      if (p["remixPrompt"]) { this.prompt = p["remixPrompt"]; this.remixLabel = "鏀圭紪鑷? " + (p["remixTitle"] ?? "") }
      if (p["remixTitle"]) this.title = p["remixTitle"]
    }
    this.loadDraft(); this.startAutoSave()
  }

  aboutToDisappear(): void { if (!this.isEditMode) this.saveDraft(); clearInterval(this.draftTimer) }

  build() {
    Column() {
      Row() {
        Text(this.isEditMode ? "缂栬緫甯栧瓙" : (this.remixLabel ? this.remixLabel : "鍙戝竷甯栧瓙"))
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text)
        Blank()
        Text("淇濆瓨鑽夌").fontSize(12).fontColor(COLORS.textSecondary)
          .onClick(() => { this.saveDraft(); promptAction.showToast({ message: "鑽夌宸蹭繚瀛? }) })
      }.width("100%").padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          TextInput({ placeholder: "璧蜂釜濂芥爣棰?..", text: this.title })
            .width("100%").height(46).fontSize(17).fontWeight(FontWeight.Medium)
            .backgroundColor("#F0F0F5").borderRadius(12)
            .onChange((v: string) => { this.title = v })
          TextArea({ placeholder: "鎻忚堪浣犵殑 Prompt 鎴栧垎浜績寰?..", text: this.content })
            .width("100%").height(110).fontSize(14)
            .backgroundColor("#F0F0F5").borderRadius(12)
            .onChange((v: string) => { this.content = v })
          Column() {
            Row() {
              Text("\u2726" + " Prompt").fontSize(11).fontColor("#FFB800")
                .backgroundColor("#FFB80015").borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              Blank()
              Text(this.prompt.length + " 瀛?).fontSize(11).fontColor(COLORS.textSecondary)
            }.width("100%").margin({ bottom: 8 })
            TextArea({ placeholder: "绮樿创 Prompt锛堝彲閫夛級", text: this.prompt })
              .width("100%").height(140).fontSize(13)
              .fontFamily("monospace").fontColor("#D0D0D6")
              .backgroundColor("#1A1A2E").borderRadius(12)
              .onChange((v: string) => { this.prompt = v })
          }
          Text("鍒嗙被").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
          Row({ space: 8 }) {
            ForEach(CATEGORIES.filter((cat: CategoryItem) => cat.key !== ""), (cat: CategoryItem) => {
              Text(cat.icon + " " + cat.label)
                .fontSize(12)
                .fontColor(this.category === cat.key ? COLORS.primary : COLORS.textSecondary)
                .backgroundColor(this.category === cat.key ? COLORS.primary + "14" : "#F0F0F5")
                .borderRadius(8).padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => { this.category = cat.key })
            })
          }
          Text("鐩爣妯″瀷").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
          Row({ space: 8 }) {
            ForEach(MODELS, (m: string) => {
              Text(m).fontSize(12)
                .fontColor(this.model === m ? COLORS.primary : COLORS.textSecondary)
                .backgroundColor(this.model === m ? COLORS.primary + "14" : "#F0F0F5")
                .borderRadius(8).padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => { this.model = m })
            })
          }
          Row() {
            Text("鏍囬 " + this.title.length + "/50").fontSize(11).fontColor(COLORS.textSecondary)
            Blank()
            Text("姝ｆ枃 " + this.content.length + "/1000").fontSize(11).fontColor(COLORS.textSecondary)
          }.width("100%")
        }.padding(16)
      }.layoutWeight(1)

      Button(this.submitting ? "淇濆瓨涓?.." : (this.isEditMode ? "淇濆瓨淇敼" : "鍙戝竷甯栧瓙"))
        .width("90%").height(52).fontSize(17).fontWeight(FontWeight.Medium)
        .fontColor("#FFF")
        .backgroundColor(this.canSubmit() ? COLORS.primary : "#CCC")
        .borderRadius(26)
        .shadow({ radius: 8, color: this.canSubmit() ? COLORS.primary + "33" : "#00000000", offsetY: 4 })
        .enabled(this.canSubmit() && !this.submitting)
        .margin({ bottom: 12 })
        .onClick(() => this.isEditMode ? this.saveEdit() : this.submit())
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  canSubmit(): boolean { return this.title.trim().length > 0 && this.content.trim().length > 0 && !this.submitting }

  async submit() { if (!this.canSubmit()) return; this.submitting = true; try { await getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model }); promptAction.showToast({ message: "鍙戝竷鎴愬姛锛? }); this.title = ""; this.content = ""; this.prompt = ""; this.remixLabel = ""; this.saveDraft(); router.back() } catch (e) { promptAction.showToast({ message: "鍙戝竷澶辫触" }) } finally { this.submitting = false } }

  async saveEdit(): Promise<void> {
    if (!this.canSubmit()) return; this.submitting = true
    try { await getApi().deletePost(this.editPostId); await getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model }); promptAction.showToast({ message: "淇濆瓨鎴愬姛锛? }); router.back() } catch (e) { promptAction.showToast({ message: "淇濆瓨澶辫触" }) } finally { this.submitting = false }
  }

  startAutoSave(): void { this.draftTimer = setInterval(() => this.saveDraft(), 10000) }
  saveDraft(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); s.putSync(DRAFT_KEY, JSON.stringify({ title: this.title, content: this.content, prompt: this.prompt, category: this.category, model: this.model })); s.flush() } catch (e) { /* ignore */ } }
  loadDraft(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); const raw: string = s.getSync(DRAFT_KEY, "{}") as string; const d: Record<string, string> = JSON.parse(raw) as Record<string, string>; if (d["title"]) this.title = d["title"]; if (d["content"]) this.content = d["content"]; if (d["prompt"]) this.prompt = d["prompt"]; if (d["category"]) this.category = d["category"]; if (d["model"]) this.model = d["model"] } catch (e) { /* ignore */ } }
}