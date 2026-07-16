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
        Text("VBDog Pro").fontSize(40).fontWeight(FontWeight.Bold).fontColor("#FFF").margin({ top: 80, bottom: 6 })
        Text("AI Prompt 创作者社区").fontSize(16).fontColor("rgba(255,255,255,0.8)").margin({ top: 4 })
        Text("发现 · 分享 · 创造").fontSize(13).fontColor("rgba(255,255,255,0.55)").margin({ top: 48 })
      }.width("100%").height("38%").justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).linearGradient({ angle: 160, colors: [[COLORS.primary, 0], ["#E55A2B", 1]] })

      Column({ space: 14 }) {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Text("📱").fontSize(18)
            TextInput({ placeholder: "手机号", text: this.phone }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).type(InputType.Number).maxLength(11).onChange((v: string) => { this.phone = v; this.errorMsg = "" })
          }.width("100%")
          if (this.isRegister) {
            Row({ space: 10 }) {
              Text("👤").fontSize(18)
              TextInput({ placeholder: "昵称", text: this.nickname }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).maxLength(20).onChange((v: string) => { this.nickname = v; this.errorMsg = "" })
            }.width("100%")
          }
          Row({ space: 10 }) {
            Text("🔑").fontSize(18)
            TextInput({ placeholder: "密码", text: this.password }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).type(InputType.Password).maxLength(20).onChange((v: string) => { this.password = v; this.errorMsg = "" }).onSubmit(() => this.handleSubmit())
          }.width("100%")
        }
        if (this.errorMsg) { Text(this.errorMsg).fontSize(13).fontColor(COLORS.error).width("100%").textAlign(TextAlign.Center) }
        Button(this.loading ? (this.isRegister ? "注册中..." : "登录中...") : (this.isRegister ? "注册" : "登录")).width("100%").height(50).fontSize(16).fontWeight(FontWeight.Medium).fontColor("#FFF").backgroundColor(COLORS.primary).borderRadius(24).shadow({ radius: 8, color: COLORS.primary + "33", offsetY: 4 }).enabled(!this.loading).onClick(() => this.handleSubmit())
        Row() {
          Text(this.isRegister ? "已有账号？" : "没有账号？").fontSize(14).fontColor(COLORS.textSecondary)
          Text(this.isRegister ? "去登录" : "去注册").fontSize(14).fontColor(COLORS.primary).fontWeight(FontWeight.Medium).onClick(() => { this.isRegister = !this.isRegister; this.errorMsg = "" })
        }.justifyContent(FlexAlign.Center)
      }.width("88%").padding({ top: 28, bottom: 24, left: 16, right: 16 }).backgroundColor(COLORS.card).borderRadius({ topLeft: 28, topRight: 28 }).margin({ top: -24 })
    }.width("100%").height("100%").backgroundColor(COLORS.primary)
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
