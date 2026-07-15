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
        this.editPostId = p["editPostId"]
        this.isEditMode = true
        if (p["editTitle"]) this.title = p["editTitle"]
        if (p["editContent"]) this.content = p["editContent"]
        if (p["editPrompt"]) this.prompt = p["editPrompt"]
        if (p["editCategory"]) this.category = p["editCategory"]
        if (p["editModel"]) this.model = p["editModel"]
        return
      }
      if (p["remixPrompt"]) { this.prompt = p["remixPrompt"]; this.remixLabel = "改编自: " + (p["remixTitle"] ?? "") }
      if (p["remixTitle"]) this.title = p["remixTitle"]
    }
    this.loadDraft(); this.startAutoSave()
  }

  aboutToDisappear(): void { if (!this.isEditMode) this.saveDraft(); clearInterval(this.draftTimer) }

  build() {
    Column() {
      Text(this.isEditMode ? "编辑帖子" : (this.remixLabel ? this.remixLabel : "发布帖子")).fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text).width("100%").padding({ left: 16, top: 16, bottom: 8 })
      Scroll() {
        Column({ space: 14 }) {
          TextInput({ placeholder: "标题", text: this.title }).width("100%").height(44).fontSize(16).backgroundColor("#F0F0F5").borderRadius(10).onChange((v: string) => { this.title = v })
          TextArea({ placeholder: "描述你的 Prompt 或分享心得...", text: this.content }).width("100%").height(100).fontSize(14).backgroundColor("#F0F0F5").borderRadius(10).onChange((v: string) => { this.content = v })
          TextArea({ placeholder: "Prompt 原文（可选）", text: this.prompt }).width("100%").height(120).fontSize(13).fontFamily("monospace").backgroundColor("#F0F0F5").borderRadius(10).onChange((v: string) => { this.prompt = v })
          Text("分类").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
          Row({ space: 6 }) {
            ForEach(CATEGORIES.filter((cat: CategoryItem) => cat.key !== ""), (cat: CategoryItem) => {
              Text(cat.icon + " " + cat.label).fontSize(12).fontColor(this.category === cat.key ? COLORS.primary : COLORS.textSecondary).backgroundColor(this.category === cat.key ? COLORS.primary + "14" : "#F0F0F5").borderRadius(8).padding({ left: 10, right: 10, top: 6, bottom: 6 }).onClick(() => { this.category = cat.key })
            })
          }
          Text("目标模型").fontSize(13).fontWeight(FontWeight.Medium).fontColor(COLORS.text).width("100%")
          Row({ space: 6 }) { ForEach(MODELS, (m: string) => { Text(m).fontSize(12).fontColor(this.model === m ? COLORS.primary : COLORS.textSecondary).backgroundColor(this.model === m ? COLORS.primary + "14" : "#F0F0F5").borderRadius(8).padding({ left: 10, right: 10, top: 6, bottom: 6 }).onClick(() => { this.model = m }) }) }
          Text("标题 " + this.title.length + "/50  |  正文 " + this.content.length + "/1000").fontSize(11).fontColor(COLORS.textSecondary).width("100%")
        }.padding(16)
      }.layoutWeight(1)

      Button(this.submitting ? "保存中..." : (this.isEditMode ? "保存修改" : "发布"))
        .width("88%").height(48).fontSize(16).fontWeight(FontWeight.Medium)
        .backgroundColor(this.canSubmit() ? COLORS.primary : "#CCC").borderRadius(12)
        .enabled(this.canSubmit() && !this.submitting).margin({ bottom: 16 })
        .onClick(() => this.isEditMode ? this.saveEdit() : this.submit())
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  canSubmit(): boolean { return this.title.trim().length > 0 && this.content.trim().length > 0 && !this.submitting }

  async submit() { if (!this.canSubmit()) return; this.submitting = true; try { await getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model }); promptAction.showToast({ message: "发布成功！" }); this.title = ""; this.content = ""; this.prompt = ""; this.remixLabel = ""; this.saveDraft(); router.back() } catch (e) { promptAction.showToast({ message: "发布失败" }) } finally { this.submitting = false } }

  async saveEdit(): Promise<void> {
    if (!this.canSubmit()) return
    this.submitting = true
    try {
      // First delete the old post, then create a new one
      await getApi().deletePost(this.editPostId)
      await getApi().createPost({ title: this.title.trim(), content: this.content.trim(), prompt: this.prompt.trim(), category: this.category, model: this.model })
      promptAction.showToast({ message: "保存成功！" }); router.back()
    } catch (e) { promptAction.showToast({ message: "保存失败" }) }
    finally { this.submitting = false }
  }

  startAutoSave(): void { this.draftTimer = setInterval(() => this.saveDraft(), 10000) }
  saveDraft(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); s.putSync(DRAFT_KEY, JSON.stringify({ title: this.title, content: this.content, prompt: this.prompt, category: this.category, model: this.model })); s.flush() } catch (e) { /* ignore */ } }
  loadDraft(): void { try { const s = preferences.getPreferencesSync(getContext(), { name: "vbdog_draft" }); const raw: string = s.getSync(DRAFT_KEY, "{}") as string; const d: Record<string, string> = JSON.parse(raw) as Record<string, string>; if (d["title"]) this.title = d["title"]; if (d["content"]) this.content = d["content"]; if (d["prompt"]) this.prompt = d["prompt"]; if (d["category"]) this.category = d["category"]; if (d["model"]) this.model = d["model"] } catch (e) { /* ignore */ } }
}
