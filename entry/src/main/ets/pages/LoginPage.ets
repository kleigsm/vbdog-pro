/**
 * LoginPage — 登录 / 注册页面
 * 手机号 + 密码登录，首次使用自动切换注册模式
 */

import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import { COLORS } from "../common/Constants"

@Entry
@Component
struct LoginPage {
  @State phone: string = ""
  @State password: string = ""
  @State nickname: string = ""
  @State isRegister: boolean = false
  @State loading: boolean = false
  @State errorMsg: string = ""
  @Link isLoggedIn: boolean

  build() {
    Column() {
      // 顶部装饰
      Column() {
        Text("VBDog Pro")
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.primary)
          .margin({ top: 80, bottom: 8 })
        Text("AI Prompt 创作者社区")
          .fontSize(16)
          .fontColor(COLORS.textSecondary)
          .margin({ bottom: 40 })
      }
      .width("100%")
      .alignItems(HorizontalAlign.Center)

      // 表单
      Column({ space: 16 }) {
        // 手机号
        TextInput({ placeholder: "手机号", text: this.phone })
          .width("100%")
          .height(52)
          .fontSize(16)
          .backgroundColor("#F0F0F5")
          .borderRadius(12)
          .type(InputType.Number)
          .maxLength(11)
          .onChange((value: string) => {
            this.phone = value
            this.errorMsg = ""
          })

        // 昵称（仅注册模式）
        if (this.isRegister) {
          TextInput({ placeholder: "昵称", text: this.nickname })
            .width("100%")
            .height(52)
            .fontSize(16)
            .backgroundColor("#F0F0F5")
            .borderRadius(12)
            .maxLength(20)
            .onChange((value: string) => {
              this.nickname = value
              this.errorMsg = ""
            })
        }

        // 密码
        TextInput({ placeholder: "密码", text: this.password })
          .width("100%")
          .height(52)
          .fontSize(16)
          .backgroundColor("#F0F0F5")
          .borderRadius(12)
          .type(InputType.Password)
          .maxLength(20)
          .onChange((value: string) => {
            this.password = value
            this.errorMsg = ""
          })
          .onSubmit(() => this.handleSubmit())

        // 错误提示
        if (this.errorMsg) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor(COLORS.error)
            .width("100%")
            .textAlign(TextAlign.Center)
        }

        // 提交按钮
        Button(this.loading ? (this.isRegister ? "注册中..." : "登录中...") : (this.isRegister ? "注册" : "登录"))
          .width("100%")
          .height(52)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(COLORS.primary)
          .borderRadius(12)
          .enabled(!this.loading)
          .onClick(() => this.handleSubmit())

        // 切换登录/注册
        Row() {
          Text(this.isRegister ? "已有账号？" : "没有账号？")
            .fontSize(14)
            .fontColor(COLORS.textSecondary)
          Text(this.isRegister ? "去登录" : "去注册")
            .fontSize(14)
            .fontColor(COLORS.primary)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.isRegister = !this.isRegister
              this.errorMsg = ""
            })
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }
      .width("88%")
      .padding({ top: 24 })
    }
    .width("100%")
    .height("100%")
    .backgroundColor(COLORS.background)
  }

  async handleSubmit() {
    this.errorMsg = ""

    if (this.phone.length < 11) {
      this.errorMsg = "请输入正确的手机号"
      return
    }
    if (this.password.length < 6) {
      this.errorMsg = "密码至少 6 位"
      return
    }
    if (this.isRegister && !this.nickname.trim()) {
      this.errorMsg = "请输入昵称"
      return
    }

    this.loading = true
    try {
      const api = getApi()
      const user = this.isRegister
        ? await api.register(this.phone, this.nickname.trim(), this.password)
        : await api.login(this.phone, this.password)

      await UserManager.setUser(user, user.id)
      this.isLoggedIn = true
    } catch (e) {
      if (e instanceof Object && typeof (e as Record<string,Object>)["message"] === "string") {
        this.errorMsg = (e as Record<string,string>)["message"]
      } else {
        this.errorMsg = "操作失败，请重试"
      }
    } finally {
      this.loading = false
    }
  }
}
