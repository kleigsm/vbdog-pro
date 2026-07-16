import { getApi } from "../common/ApiProvider"
import { CATEGORIES, CategoryItem } from "../common/Models"
import { COLORS } from "../common/Constants"
import { promptAction, router } from "@kit.ArkUI"
import { preferences } from "@kit.ArkData"

const MODELS: string[] = ["Claude", "ChatGPT", "Copilot", "Gemini", "Other"]
const DRAFT_KEY: string = "create_draft"

interface DraftData { title: string; content: string; prompt: string; category: string; model: string }

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
      if (p["remixPrompt"]) { this.prompt = p["remixPrompt"]; this.remixLabel = "\u6539\u7f16\u81ea: " + (p["remixTitle"] ?? "") }
      if (p["remixTitle"]) this.title = p["remixTitle"]
    }
    this.loadDraft(); this.startAutoSave()
  }

  aboutToDisappear(): void { if (!this.isEditMode) this.saveDraft(); clearInterval(this.draftTimer) }

  build() {
    Column() {
      Row() {
        Text(this.isEditMode ? "\u7f16\u8f91\u5e16\u5b50" : (this.remixLabel ? this.remixLabel : "\u53d1\u5e03\u5e16\u5b50"))
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text)
        Blank()
        Text("\u4fdd\u5b58\u8349\u7a3f").fontSize(12).fontColor(COLORS.textSecondary)
          .onClick(() => { this.saveDraft(); promptAction.showToast({ message: "\u8349\u7a3f\u5df2\u4fdd\u5b58" }) })
      }.width("100%").padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Scroll() {
        Column({ space: 14 }) {
          TextInput({ placeholder: "\u8d77\u4e2a\u597d\u6807\u9898...", text: this.title })
            .width("100%").height(46).fontSize(17).fontWeight(FontWeight.Medium)
            .backgroundColor("#F0F0F5").borderRadius(12)
            .onChange((v: string) => { this.title = v })
          TextArea({ placeholder: "\u63cf\u8ff0\u4f60\u7684 Prompt \u6216\u5206\u4eab\u5fc3\u5f97...", text: this.content })
            .width("100%").height(110).fontSize(14)
            .backgroundColor("#F0F0F5").borderRadius(12)
            .onChange((v: string) => { this.content = v })
          Column() {
            Row() {
              Text("\u2726 Prompt").fontSize(11).fontColor("#FFB800")
                .backgroundColor("#FFB80015").borderRadius(4)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              Blank()
              Text(this.prompt.length + " \u5b57").fontSize(11).fontColor(COLORS.textSecondary)
            }.width("100%").margin({ bottom: 8 })
            TextArea({ placeholder: "\u7c98\u8d34 Prompt\uff08\u53ef\u9009\uff09", text: this.prompt })
              .width("100%").height(140).fontSize(13)
              .fontFamily("monospace").fontColor("#D0D0D6")
              .backgroundColor("#1A1A2E").borderRadius(12)
              .onChange((v: string) => { this.prompt = v })
          }
          Text("\u5206\u7c7b").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
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
          Text("\u76ee\u6807\u6a21\u578b").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
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
            Text("\u6807\u9898 " + this.title.length + "/50").fontSize(11).fontColor(COLORS.textSecondary)
            Blank()
            Text("\u6b63\u6587 " + this.content.length + "/1000").fontSize(11).fontColor(COLORS.textSecondary)
          }.width("100%")
        }.padding(16)
      }.layoutWeight(1)

      Button(this.submitting ? "\u4fdd\u5b58\u4e2d..." : (this.isEditMode ? "\u4fdd\u5b58\u4fee\u6539" : "\u53d1\u5e03\u5e16\u5b50"))
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

  submit(): void { if (!this.canSubmit()) return; this.submitting = true; getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model }).then(() => { promptAction.showToast({ message: "\u53d1\u5e03\u6210\u529f\uff01" }); this.title = ""; this.content = ""; this.prompt = ""; this.remixLabel = ""; this.saveDraft(); router.back(); this.submitting = false }).catch(() => { this.submitting = false; promptAction.showToast({ message: "\u53d1\u5e03\u5931\u8d25" }) }) }

  saveEdit(): void {
    if (!this.canSubmit()) return; this.submitting = true
    getApi().deletePost(this.editPostId).then(() => {
      return getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model })
    }).then(() => { promptAction.showToast({ message: "\u4fdd\u5b58\u6210\u529f\uff01" }); router.back(); this.submitting = false }).catch(() => { this.submitting = false; promptAction.showToast({ message: "\u4fdd\u5b58\u5931\u8d25" }) })
  }

  startAutoSave(): void { this.draftTimer = setInterval(() => this.saveDraft(), 10000) }
  saveDraft(): void { try { const s: preferences.Preferences = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); const d: DraftData = { title: this.title, content: this.content, prompt: this.prompt, category: this.category, model: this.model }; s.putSync(DRAFT_KEY, JSON.stringify(d)); s.flush() } catch (e) { } }
  loadDraft(): void { try { const s: preferences.Preferences = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); const raw: string = s.getSync(DRAFT_KEY, "{}") as string; const d: DraftData = JSON.parse(raw) as DraftData; if (d.title) this.title = d.title; if (d.content) this.content = d.content; if (d.prompt) this.prompt = d.prompt; if (d.category) this.category = d.category; if (d.model) this.model = d.model } catch (e) { } }
}