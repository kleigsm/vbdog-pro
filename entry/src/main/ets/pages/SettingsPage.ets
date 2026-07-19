import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, C_BORDER, C_DARK_BG, C_DARK_CARD, C_DARK_TEXT1, C_DARK_TEXT2, C_DARK_TEXT3, C_DARK_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_LG, F_SM, F_BODY, F_LG, APP_NAME, APP_VERSION } from "../common/Constants"
import router from "@ohos.router"
import { UserManager } from "../common/UserManager"
import { promptAction } from "@kit.ArkUI"
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
struct SettingsPage {
  @StorageLink("isDark") isDark: boolean = false

  onMenuItem(item: string): void {
    promptAction.showToast({ message: item + "功能开发中", duration: 1500 })
  }

  build() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1)
          .onClick(() => { router.back() })
        Text("设置").fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

      Row() {
        Text(this.isDark ? "深色模式" : "浅色模式").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.isDark }).onChange((v: boolean) => {
          this.isDark = v; AppStorage.set("isDark", v)
        })
      }.width("100%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).margin({ top: S_MD })

      Column() {
        ForEach(["账号与安全", "隐私设置", "通知设置", "帮助与反馈"], (item: string) => {
          Row() {
            Text(item).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).layoutWeight(1)
            Image($r("sys.symbol.chevron_right")).width(16).height(16).fillColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD + 2, bottom: S_MD + 2 })
          .onClick(() => { this.onMenuItem(item) })
        }, (item: string) => item)
      }.width("100%").backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).margin({ top: S_MD })

      Column() {
        Text(APP_NAME + " v" + APP_VERSION).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
        Text("AI 创作者社区").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 2 })
        Text("HarmonyOS 原生应用").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 1 })
      }.width("100%").padding(S_XL).alignItems(HorizontalAlign.Center).margin({ top: 24 })

      Button("切换账号").fontSize(F_BODY).fontColor(C_PRIMARY).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(22)
        .borderWidth(1).borderColor(C_PRIMARY).height(44).width("80%").margin({ top: S_LG })
        .onClick(() => { router.pushUrl({ url: "pages/LoginPage" }) })

      Button("退出登录").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).backgroundColor(this.isDark ? C_DARK_BG : C_BG).borderRadius(22)
        .height(44).width("80%").margin({ top: S_MD })
        .onClick(() => {
          router.back(); AppStorage.set("isLoggedIn", false)
        })
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }
}
