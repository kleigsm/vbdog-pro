import { getApi } from "../common/ApiProvider"
import { COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"

@Component
export struct LoginPage {
  @State phone: string = ""
  @State password: string = ""
  @State nickname: string = ""
  @State isRegister: boolean = false
  @State loading: boolean = false
  @State errorMsg: string = ""

  build() {
    Column() {
      Column() {
        Text("VBDog Pro").fontSize(36).fontWeight(FontWeight.Bold).fontColor(COLORS.primary).margin({ top: 80, bottom: 8 })
        Text("AI Prompt 创作者社区").fontSize(16).fontColor(COLORS.textSecondary).margin({ bottom: 40 })
      }.width("100%").alignItems(HorizontalAlign.Center)

      Column({ space: 16 }) {
        TextInput({ placeholder: "手机号", text: this.phone }).width("100%").height(52).fontSize(16).backgroundColor("#F0F0F5").borderRadius(12).type(InputType.Number).maxLength(11).onChange((v: string) => { this.phone = v; this.errorMsg = "" })

        if (this.isRegister) {
          TextInput({ placeholder: "昵称", text: this.nickname }).width("100%").height(52).fontSize(16).backgroundColor("#F0F0F5").borderRadius(12).maxLength(20).onChange((v: string) => { this.nickname = v; this.errorMsg = "" })
        }

        TextInput({ placeholder: "密码", text: this.password }).width("100%").height(52).fontSize(16).backgroundColor("#F0F0F5").borderRadius(12).type(InputType.Password).maxLength(20).onChange((v: string) => { this.password = v; this.errorMsg = "" }).onSubmit(() => this.handleSubmit())

        if (this.errorMsg) { Text(this.errorMsg).fontSize(13).fontColor(COLORS.error).width("100%").textAlign(TextAlign.Center) }

        Button(this.loading ? (this.isRegister ? "注册中..." : "登录中...") : (this.isRegister ? "注册" : "登录"))
          .width("100%").height(52).fontSize(17).fontWeight(FontWeight.Medium).backgroundColor(COLORS.primary).borderRadius(12).enabled(!this.loading).onClick(() => this.handleSubmit())

        Row() {
          Text(this.isRegister ? "已有账号？" : "没有账号？").fontSize(14).fontColor(COLORS.textSecondary)
          Text(this.isRegister ? "去登录" : "去注册").fontSize(14).fontColor(COLORS.primary).fontWeight(FontWeight.Medium).onClick(() => { this.isRegister = !this.isRegister; this.errorMsg = "" })
        }.justifyContent(FlexAlign.Center).margin({ top: 8 })
      }.width("88%").padding({ top: 24 })
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async handleSubmit(): Promise<void> {
    this.errorMsg = ""
    if (this.phone.length < 11) { this.errorMsg = "请输入正确的手机号"; return }
    if (this.password.length < 6) { this.errorMsg = "密码至少 6 位"; return }
    if (this.isRegister && !this.nickname.trim()) { this.errorMsg = "请输入昵称"; return }
    this.loading = true
    try {
      const user = this.isRegister ? await getApi().register(this.phone, this.nickname.trim(), this.password) : await getApi().login(this.phone, this.password)
      await UserManager.setUser(user, user.id)
      AppStorage.set("isLoggedIn", true)
    } catch (e) { this.errorMsg = "操作失败，请重试" }
    finally { this.loading = false }
  }
}
