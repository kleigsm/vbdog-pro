import { C_BG, C_DARK_BG, C_CARD, C_DARK_CARD, C_TEXT1, C_DARK_TEXT1, C_TEXT2, C_DARK_TEXT2, C_TEXT3, C_DARK_TEXT3, C_PRIMARY, C_RED, C_BORDER, C_DARK_BORDER, C_DARK, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, F_CAPT, F_SM, F_BODY, F_LG, F_H1, APP_NAME } from "../common/Constants"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import { promptAction } from "@kit.ArkUI"

@Component
export struct LoginPage {
  @StorageLink("isDark") isDark: boolean = false
  @State phone: string = ""
  @State password: string = ""
  @State nickname: string = ""
  @State isRegister: boolean = false
  @State loading: boolean = false
  @State errorMsg: string = ""

  build() {
    Column() {
      Column() {
        Text("🐤").fontSize(80)
        Text(APP_NAME).fontSize(F_H1).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold).margin({ top: S_MD })
        Text("AI 创作者社区").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ top: S_SM })
      }.width("100%").margin({ top: 60 })

      Column() {
        if (this.isRegister) {
          TextInput({ placeholder: "昵称（给自己取个名字）", text: this.nickname })
            .fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontSize(F_BODY)
            .backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_MD)
            .borderWidth(1).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER).height(50).padding({ left: S_LG }).width("100%").maxLength(20)
            .onChange((v: string) => { this.nickname = v; this.errorMsg = "" }).margin({ bottom: S_MD })
        }

        TextInput({ placeholder: "手机号（输入 11 位数字）", text: this.phone })
          .fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontSize(F_BODY)
          .backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_MD)
          .borderWidth(1).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER).height(50).padding({ left: S_LG }).width("100%").type(InputType.PhoneNumber).maxLength(11)
          .onChange((v: string) => { this.phone = v; this.errorMsg = "" }).margin({ bottom: S_MD })

        TextInput({ placeholder: "密码（至少 6 位）", text: this.password })
          .fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontSize(F_BODY)
          .backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(R_MD)
          .borderWidth(1).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER).height(50).padding({ left: S_LG }).width("100%").type(InputType.Password)
          .onChange((v: string) => { this.password = v; this.errorMsg = "" }).onSubmit(() => this.handleSubmit()).margin({ bottom: S_XL })

        if (this.errorMsg) {
          Text(this.errorMsg).fontSize(F_SM).fontColor(C_RED).width("100%").textAlign(TextAlign.Center).margin({ bottom: S_MD })
        }

        Button(this.loading ? (this.isRegister ? "注册中..." : "登录中...") : (this.isRegister ? "注册加入 VBDog" : "登录"))
          .fontSize(F_LG).fontColor("#FFFFFF").backgroundColor(C_PRIMARY).borderRadius(24)
          .height(50).width("100%").fontWeight(FontWeight.Bold)
          .enabled(!this.loading).onClick(() => this.handleSubmit())
      }.width("100%").padding({ left: S_XL, right: S_XL, top: S_XL })

      Text(this.isRegister ? "已有账号？去登录" : "没有账号？去注册").fontSize(F_SM).fontColor(C_PRIMARY)
        .margin({ top: S_LG }).onClick(() => { this.isRegister = !this.isRegister; this.errorMsg = "" })

      Text("模拟登录，任意手机号即可").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: S_XL })
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }

  async handleSubmit(): Promise<void> {
    this.errorMsg = ""
    if (this.phone.length < 11) { this.errorMsg = "请输入正确的手机号"; return }
    if (this.password.length < 6) { this.errorMsg = "密码至少 6 位"; return }
    if (this.isRegister && !this.nickname.trim()) { this.errorMsg = "请输入昵称"; return }
    this.loading = true
    try {
      const user = this.isRegister
        ? await getApi().register(this.phone, this.nickname.trim(), this.password)
        : await getApi().login(this.phone, this.password)
      await UserManager.setUser(user, user.id)
      AppStorage.set("isLoggedIn", true)
    } catch (e) {
      this.errorMsg = "操作失败，请重试"
    } finally {
      this.loading = false
    }
  }
}
