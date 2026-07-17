import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, C_BLUE, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, R_LG, F_CAPT, F_SM, F_BODY, F_LG, F_H3, CATEGORIES, TARGET_MODELS, HOT_TAGS, Category, VTag } from "../common/Constants"
import { getApi } from "../common/ApiProvider"
import { promptAction } from "@kit.ArkUI"
import router from "@ohos.router"
import { preferences } from "@kit.ArkData"
import { photoAccessHelper } from "@kit.MediaLibraryKit"

@Entry
@Component
export struct CreatePage {
  @State title: string = ""
  @State content: string = ""
  @State promptText: string = ""
  @State category: string = "prompt"
  @State targetModel: string = "通用"
  @State tags: string[] = []
  @State submitting: boolean = false
  @State draftSaved: boolean = false
  @State remixAuthor: string = ""
  onCreated?: () => void
  private prefs: preferences.Preferences | null = null
  private saveTimer: number = -1

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params["remixPrompt"]) {
      this.title = (params["remixTitle"] as string) || ""
      this.promptText = (params["remixPrompt"] as string) || ""
      this.remixAuthor = (params["remixAuthor"] as string) || ""
      return
    }
    const ctx = this.getUIContext().getHostContext()
    if (ctx) {
      preferences.getPreferences(ctx, "vbdog_draft").then((p: preferences.Preferences) => {
        this.prefs = p
        p.get("title", "").then((v: preferences.ValueType) => { const s = v as string; if (s) this.title = s })
        p.get("content", "").then((v: preferences.ValueType) => { const s = v as string; if (s) this.content = s })
        p.get("prompt", "").then((v: preferences.ValueType) => { const s = v as string; if (s) this.promptText = s })
      })
    }
    this.saveTimer = setInterval(() => { this.saveDraft() }, 10000)
  }

  aboutToDisappear(): void { if (this.saveTimer >= 0) clearInterval(this.saveTimer) }

  saveDraft(): void {
    if (!this.title && !this.promptText) return
    if (this.prefs) {
      this.prefs.put("title", this.title)
      this.prefs.put("content", this.content)
      this.prefs.put("prompt", this.promptText)
      this.draftSaved = true; setTimeout(() => { this.draftSaved = false }, 2000)
    }
  }

  clearDraft(): void {
    if (this.prefs) { this.prefs.put("title", ""); this.prefs.put("content", ""); this.prefs.put("prompt", "") }
  }

  toggleTag(tag: string): void {
    const idx = this.tags.indexOf(tag)
    if (idx > -1) this.tags.splice(idx, 1)
    else if (this.tags.length < 5) this.tags.push(tag)
    this.tags = [...this.tags]
  }


  pickImages(): void {
    try {
      let picker = new photoAccessHelper.PhotoViewPicker()
      let self = this
      picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 9 - self.imageUris.length
      }).then((res: photoAccessHelper.PhotoSelectResult): void => {
        if (res.photoUris.length > 0) {
          self.imageUris = self.imageUris.concat(res.photoUris)
        }
      }).catch((): void => { })
    } catch (_e) { }
  }

  removeImage(index: number): void {
    this.imageUris.splice(index, 1)
    this.imageUris = this.imageUris.concat([])
  }
  submit(): void {
    if (!this.title.trim()) { promptAction.showToast({ message: "请输入标题", duration: 2000 }); return }
    if (!this.promptText.trim()) { promptAction.showToast({ message: "请输入 Prompt 内容", duration: 2000 }); return }
    this.submitting = true
    getApi().createPost({
      title: this.title.trim(), content: this.content.trim(), prompt: this.promptText.trim(),
      category: this.category, model: this.targetModel
    }).then(() => {
      promptAction.showToast({ message: "发布成功！🎉", duration: 2000 })
      this.title = ""; this.content = ""; this.promptText = ""; this.tags = []
      this.clearDraft()
      if (this.onCreated) this.onCreated()
    }).catch(() => {
      promptAction.showToast({ message: "发布失败", duration: 1500 })
    }).finally(() => { this.submitting = false })
  }

  build() {
    Column() {
      Row() {
        Text("发布作品").fontSize(F_H3).fontColor(C_TEXT1).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button(this.submitting ? "发布中..." : "发布").fontSize(F_BODY).fontColor("#FFFFFF")
          .backgroundColor(C_PRIMARY).borderRadius(20).height(36).padding({ left: S_XL, right: S_XL })
          .enabled(!this.submitting && this.title.trim().length > 0).onClick(() => this.submit())
        if (this.title || this.promptText) {
          Text("草稿已保存").fontSize(F_CAPT).fontColor(C_PRIMARY).opacity(this.draftSaved ? 1 : 0.5)
        }
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      Scroll() {
        Column() {
          if (this.remixAuthor) {
            Row() {
              Text("🎨 改编自 @" + this.remixAuthor).fontSize(F_SM).fontColor(C_PRIMARY)
                .backgroundColor(C_PRIMARY + "12").borderRadius(8)
                .padding({ left: S_MD, right: S_MD, top: S_XS, bottom: S_XS })
            }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD })
          }

          TextInput({ placeholder: "给你的作品起个吸引人的标题...", text: this.title })
            .fontColor(C_TEXT1).fontSize(F_LG).fontWeight(FontWeight.Bold).backgroundColor(C_CARD)
            .borderRadius(R_MD).padding({ left: S_LG, right: S_LG }).height(52).width("100%")
            .onChange((v: string) => { this.title = v })
            .margin({ left: S_LG, right: S_LG, top: S_LG })
          Text(this.title.length + "/50").fontSize(F_CAPT).fontColor(this.title.length > 50 ? "#FF4757" : C_TEXT3)
            .width("100%").textAlign(TextAlign.End).padding({ right: S_LG, top: S_XS })

          TextArea({ placeholder: "介绍一下你的作品：使用场景、效果、心得...", text: this.content })
            .fontColor(C_TEXT1).fontSize(F_BODY).backgroundColor(C_CARD).borderRadius(R_MD)
            .padding({ left: S_LG, right: S_LG, top: S_MD }).height(100).width("100%")
            .onChange((v: string) => { this.content = v })
            .margin({ left: S_LG, right: S_LG, top: S_MD })


          Column() {
            Text("添加图片（最多 9 张）").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              Column() { Text("#").fontSize(28); Text("选择图片").fontSize(10).fontColor(C_TEXT3) }
              .width(72).height(72).borderRadius(R_MD).backgroundColor(C_CARD).borderWidth(1).borderColor(C_BORDER)
              .justifyContent(FlexAlign.Center).margin({ right: S_SM })
              .onClick(() => { this.pickImages() })
              ForEach(this.imageUris, (uri: string, idx: number) => {
                Stack() {
                  Image(uri).width(72).height(72).borderRadius(R_MD).objectFit(ImageFit.Cover)
                  Text("X").fontSize(14).fontColor("#FFF").width(20).height(20)
                    .borderRadius(10).backgroundColor("#FF4757").textAlign(TextAlign.Center)
                    .position({ x: 56, y: 0 })
                    .onClick(() => { this.removeImage(idx) })
                }.margin({ right: S_SM })
              }, (uri: string, idx: number) => idx.toString())
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
          Column() {
            Text("Prompt / Skill 内容 *").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            TextArea({ placeholder: "粘贴你的 prompt 或 skill 原文...", text: this.promptText })
              .fontColor(C_TEXT1).fontSize(F_BODY).fontFamily("monospace")
              .backgroundColor("#F8F9FA").borderRadius(R_MD).borderWidth(1).borderColor(C_BORDER)
              .padding(12).height(160).width("100%")
              .onChange((v: string) => { this.promptText = v })
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
          Text("Prompt 字符: " + this.promptText.length).fontSize(F_CAPT).fontColor(C_TEXT3)
            .width("100%").textAlign(TextAlign.End).padding({ right: S_LG, top: S_XS })


          Column() {
            Text("添加图片（最多 9 张）").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              Column() { Text("#").fontSize(28); Text("选择图片").fontSize(10).fontColor(C_TEXT3) }
              .width(72).height(72).borderRadius(R_MD).backgroundColor(C_CARD).borderWidth(1).borderColor(C_BORDER)
              .justifyContent(FlexAlign.Center).margin({ right: S_SM })
              .onClick(() => { this.pickImages() })
              ForEach(this.imageUris, (uri: string, idx: number) => {
                Stack() {
                  Image(uri).width(72).height(72).borderRadius(R_MD).objectFit(ImageFit.Cover)
                  Text("X").fontSize(14).fontColor("#FFF").width(20).height(20)
                    .borderRadius(10).backgroundColor("#FF4757").textAlign(TextAlign.Center)
                    .position({ x: 56, y: 0 })
                    .onClick(() => { this.removeImage(idx) })
                }.margin({ right: S_SM })
              }, (uri: string, idx: number) => idx.toString())
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
          Column() {
            Text("分类").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              ForEach(CATEGORIES.slice(1), (c: Category) => {
                Text(c.icon + " " + c.name).fontSize(F_SM)
                  .fontColor(this.category === c.id ? "#FFFFFF" : C_TEXT2)
                  .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM }).borderRadius(16).margin({ right: S_SM })
                  .backgroundColor(this.category === c.id ? C_PRIMARY : C_CARD).borderWidth(1).borderColor(C_BORDER)
                  .onClick(() => { this.category = c.id })
              }, (c: Category) => c.id)
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })


          Column() {
            Text("添加图片（最多 9 张）").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              Column() { Text("#").fontSize(28); Text("选择图片").fontSize(10).fontColor(C_TEXT3) }
              .width(72).height(72).borderRadius(R_MD).backgroundColor(C_CARD).borderWidth(1).borderColor(C_BORDER)
              .justifyContent(FlexAlign.Center).margin({ right: S_SM })
              .onClick(() => { this.pickImages() })
              ForEach(this.imageUris, (uri: string, idx: number) => {
                Stack() {
                  Image(uri).width(72).height(72).borderRadius(R_MD).objectFit(ImageFit.Cover)
                  Text("X").fontSize(14).fontColor("#FFF").width(20).height(20)
                    .borderRadius(10).backgroundColor("#FF4757").textAlign(TextAlign.Center)
                    .position({ x: 56, y: 0 })
                    .onClick(() => { this.removeImage(idx) })
                }.margin({ right: S_SM })
              }, (uri: string, idx: number) => idx.toString())
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
          Column() {
            Text("适配模型").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              ForEach(TARGET_MODELS.slice(0, 8), (m: string) => {
                Text(m).fontSize(F_SM).fontColor(this.targetModel === m ? "#FFFFFF" : C_TEXT2)
                  .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM }).borderRadius(16).margin({ right: S_SM, bottom: S_SM })
                  .backgroundColor(this.targetModel === m ? C_BLUE : C_CARD).borderWidth(1).borderColor(C_BORDER)
                  .onClick(() => { this.targetModel = m })
              })
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })


          Column() {
            Text("添加图片（最多 9 张）").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              Column() { Text("#").fontSize(28); Text("选择图片").fontSize(10).fontColor(C_TEXT3) }
              .width(72).height(72).borderRadius(R_MD).backgroundColor(C_CARD).borderWidth(1).borderColor(C_BORDER)
              .justifyContent(FlexAlign.Center).margin({ right: S_SM })
              .onClick(() => { this.pickImages() })
              ForEach(this.imageUris, (uri: string, idx: number) => {
                Stack() {
                  Image(uri).width(72).height(72).borderRadius(R_MD).objectFit(ImageFit.Cover)
                  Text("X").fontSize(14).fontColor("#FFF").width(20).height(20)
                    .borderRadius(10).backgroundColor("#FF4757").textAlign(TextAlign.Center)
                    .position({ x: 56, y: 0 })
                    .onClick(() => { this.removeImage(idx) })
                }.margin({ right: S_SM })
              }, (uri: string, idx: number) => idx.toString())
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
          Column() {
            Text("标签（最多 5 个）").fontSize(F_SM).fontColor(C_TEXT2).margin({ bottom: S_SM }).width("100%")
            Row() {
              ForEach(HOT_TAGS.slice(0, 12), (t: VTag) => {
                Text(t.name).fontSize(F_SM)
                  .fontColor(this.tags.includes(t.name) ? "#FFFFFF" : C_TEXT2)
                  .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM }).borderRadius(16).margin({ right: S_SM, bottom: S_SM })
                  .backgroundColor(this.tags.includes(t.name) ? C_PRIMARY : C_CARD).borderWidth(1).borderColor(C_BORDER)
                  .onClick(() => { this.toggleTag(t.name) })
              })
            }
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })

          Column().height(80)
        }.width("100%")
      }.layoutWeight(1).width("100%")
    }.width("100%").height("100%").backgroundColor(C_BG)
  }
}
