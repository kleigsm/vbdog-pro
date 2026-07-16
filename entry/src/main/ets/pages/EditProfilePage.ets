import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, F_SM, F_BODY, F_LG } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"
import { promptAction } from "@kit.ArkUI"

const AVATARS: string[] = ["🐤", "🐗", "🐐", "🛯", "🐣", "🐃", "🐎", "🛦", "🐍", "🐙", "🐛", "🐖", "🐢", "🐂", "🐁", "🛩", "🐒", "🜁", "🛮", "🛬", "🐵", "🕻", "🍓", "🛰"]

@Entry
@Component
struct EditProfilePage {
  @State name: string = ""
  @State bio: string = ""
  @State username: string = ""
  @State avatar: string = "🐤"
  @State showAvatars: boolean = false

  aboutToAppear(): void {
    const user = UserManager.currentUser
    this.name = user?.nickname ?? ""
    this.bio = user?.bio ?? ""
    this.username = user?.phone ?? ""
    this.avatar = "🐤"
  }

  save(): void {
    UserManager.saveProfile(this.name.trim(), this.bio.trim())
    promptAction.showToast({ message: "保存成功", duration: 1500 })
    router.back()
  }

  build() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(C_TEXT1)
          .onClick(() => { router.back() })
        Text("编辑资料").fontSize(F_LG).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("保存").fontSize(F_BODY).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
          .onClick(() => { this.save() })
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      Column() {
        Column() {
          Text(this.avatar).fontSize(56)
        }.width(80).height(80).borderRadius(40)
        .backgroundColor("#FFF3E0").justifyContent(FlexAlign.Center).margin({ top: S_XL })
        .onClick(() => { this.showAvatars = !this.showAvatars })

        Text("点击更换头像").fontSize(F_SM).fontColor(C_PRIMARY).margin({ top: S_MD })

        if (this.showAvatars) {
          Row() {
            ForEach(AVATARS, (a: string) => {
              Text(a).fontSize(28).padding(4)
                .backgroundColor(this.avatar === a ? "#FFF3E0" : Color.Transparent)
                .borderRadius(R_MD).margin(2)
                .onClick(() => { this.avatar = a; this.showAvatars = false })
            }, (a: string) => a)
          }.width("100%").padding(S_LG).margin({ top: S_SM })
        }
      }.width("100%").alignItems(HorizontalAlign.Center)

      Column() {
        Text("昵称").fontSize(F_SM).fontColor(C_TEXT3).margin({ bottom: S_SM }).width("100%")
        TextInput({ text: this.name }).fontColor(C_TEXT1).fontSize(F_BODY).backgroundColor(C_BG).borderRadius(R_MD)
          .height(44).padding({ left: S_LG }).width("100%").onChange((v: string) => { this.name = v })
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })

      Column() {
        Text("手机号").fontSize(F_SM).fontColor(C_TEXT3).margin({ bottom: S_SM }).width("100%")
        TextInput({ text: this.username }).fontColor(C_TEXT1).fontSize(F_BODY).backgroundColor(C_BG).borderRadius(R_MD)
          .height(44).padding({ left: S_LG }).width("100%").enabled(false)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })

      Column() {
        Text("简介").fontSize(F_SM).fontColor(C_TEXT3).margin({ bottom: S_SM }).width("100%")
        TextArea({ text: this.bio }).fontColor(C_TEXT1).fontSize(F_BODY).backgroundColor(C_BG).borderRadius(R_MD)
          .height(100).padding({ left: S_LG, top: S_MD }).width("100%").onChange((v: string) => { this.bio = v })
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_LG })
    }.width("100%").height("100%").backgroundColor(C_BG)
  }
}
