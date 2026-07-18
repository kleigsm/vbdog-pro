import os
base = r"D:\Projects\vbdog-pro\entry\src\main\ets\pages"

def w(rel, content):
    path = os.path.join(base, rel)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("OK " + rel)

# Index.ets
w("Index.ets", '''import { UserManager } from "../common/UserManager"
import { SupabaseClient } from "../common/SupabaseClient"
import { getApi, setApi } from "../common/ApiProvider"
import { COLORS } from "../common/Constants"
import { LoginPage } from "./LoginPage"
import { FeedPage } from "./FeedPage"
import { SearchPage } from "./SearchPage"
import { CreatePage } from "./CreatePage"
import { ProfilePage } from "./ProfilePage"
import { NotificationsPage } from "./NotificationsPage"
import { MessagesPage } from "./MessagesPage"

AppStorage.setOrCreate("isLoggedIn", false)
AppStorage.setOrCreate("isDark", false)

@Entry
@Component
struct Index {
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @StorageLink("isDark") isDark: boolean = false
  @State currentTab: number = 0
  @State appReady: boolean = false
  @State splashOpacity: number = 0
  @State logoScale: number = 0.8

  aboutToAppear(): void {
    setApi(new SupabaseClient())
    this.animateSplash()
    UserManager.restoreSession().then(() => {
      AppStorage.set("isLoggedIn", UserManager.isLoggedIn)
      if (UserManager.isLoggedIn) {
        const api = getApi() as SupabaseClient
        const user = UserManager.currentUser
        if (user) api.setUserId(user.id)
      }
      this.appReady = true
    })
  }

  animateSplash(): void {
    this.splashOpacity = 1
    animateTo({ duration: 600, curve: Curve.EaseOut }, () => { this.logoScale = 1 })
    setTimeout(() => { animateTo({ duration: 200 }, () => { this.splashOpacity = 0.6 }) }, 600)
  }

  build() {
    if (!this.appReady) {
      Column() {
        Column({ space: 12 }) {
          Text("VBDog Pro").fontSize(36).fontWeight(FontWeight.Bold).fontColor(COLORS.primary).scale({ x: this.logoScale, y: this.logoScale }).opacity(this.splashOpacity)
          Text("AI Prompt \u521b\u4f5c\u8005\u793e\u533a").fontSize(15).fontColor(COLORS.textSecondary).opacity(this.splashOpacity)
          LoadingProgress().width(28).height(28).margin({ top: 32 }).color(COLORS.primary).opacity(this.splashOpacity)
        }.justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    } else if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Tabs({ index: $$this.currentTab }) {
        TabContent() { FeedPage() }.tabBar(this.tabLabel("\u53d1\u73b0", 0))
        TabContent() { SearchPage() }.tabBar(this.tabLabel("\u641c\u7d22", 1))
        TabContent() { CreatePage() }.tabBar(this.tabLabel("\u53d1\u5e03", 2))
        TabContent() { this.messageCombined() }.tabBar(this.tabLabel("\u6d88\u606f", 3))
        TabContent() { ProfilePage() }.tabBar(this.tabLabel("\u6211\u7684", 4))
      }.barMode(BarMode.Fixed).barHeight(56).barPosition(BarPosition.End).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    }
  }

  @Builder messageCombined() {
    Tabs() { TabContent() { NotificationsPage() }.tabBar("\u901a\u77e5"); TabContent() { MessagesPage() }.tabBar("\u79c1\u4fe1") }
  }

  @Builder tabLabel(label: string, index: number) {
    Column({ space: 2 }) {
      Row().width(20).height(3).borderRadius(2).backgroundColor(this.currentTab === index ? COLORS.primary : Color.Transparent)
      Text(this.getTabIcon(index)).fontSize(20).fontColor(this.currentTab === index ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary))
      Text(label).fontSize(10).fontColor(this.currentTab === index ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary)).fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
    }.width("100%").alignItems(HorizontalAlign.Center).padding({ top: 4 })
  }

  getTabIcon(index: number): string {
    return ["\U0001F525", "\U0001F50D", "\U0000270F", "\U0001F4AC", "\U0001F464"][index]
  }
}
''')

# LoginPage
w("LoginPage.ets", '''import { getApi } from "../common/ApiProvider"
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
        Text("AI Prompt \u521b\u4f5c\u8005\u793e\u533a").fontSize(16).fontColor("rgba(255,255,255,0.8)").margin({ top: 4 })
        Text("\u53d1\u73b0 \u00b7 \u5206\u4eab \u00b7 \u521b\u9020").fontSize(13).fontColor("rgba(255,255,255,0.55)").margin({ top: 48 })
      }.width("100%").height("38%").justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).linearGradient({ angle: 160, colors: [[COLORS.primary, 0], ["#E55A2B", 1]] })

      Column({ space: 14 }) {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Text("\U0001F4F1").fontSize(18)
            TextInput({ placeholder: "\u624b\u673a\u53f7", text: this.phone }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).type(InputType.Number).maxLength(11).onChange((v: string) => { this.phone = v; this.errorMsg = "" })
          }.width("100%")
          if (this.isRegister) {
            Row({ space: 10 }) {
              Text("\U0001F464").fontSize(18)
              TextInput({ placeholder: "\u6635\u79f0", text: this.nickname }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).maxLength(20).onChange((v: string) => { this.nickname = v; this.errorMsg = "" })
            }.width("100%")
          }
          Row({ space: 10 }) {
            Text("\U0001F511").fontSize(18)
            TextInput({ placeholder: "\u5bc6\u7801", text: this.password }).layoutWeight(1).height(48).fontSize(15).backgroundColor("#F8F8FA").borderRadius(14).type(InputType.Password).maxLength(20).onChange((v: string) => { this.password = v; this.errorMsg = "" }).onSubmit(() => this.handleSubmit())
          }.width("100%")
        }
        if (this.errorMsg) { Text(this.errorMsg).fontSize(13).fontColor(COLORS.error).width("100%").textAlign(TextAlign.Center) }
        Button(this.loading ? (this.isRegister ? "\u6ce8\u518c\u4e2d..." : "\u767b\u5f55\u4e2d...") : (this.isRegister ? "\u6ce8\u518c" : "\u767b\u5f55")).width("100%").height(50).fontSize(16).fontWeight(FontWeight.Medium).fontColor("#FFF").backgroundColor(COLORS.primary).borderRadius(24).shadow({ radius: 8, color: COLORS.primary + "33", offsetY: 4 }).enabled(!this.loading).onClick(() => this.handleSubmit())
        Row() {
          Text(this.isRegister ? "\u5df2\u6709\u8d26\u53f7\uff1f" : "\u6ca1\u6709\u8d26\u53f7\uff1f").fontSize(14).fontColor(COLORS.textSecondary)
          Text(this.isRegister ? "\u53bb\u767b\u5f55" : "\u53bb\u6ce8\u518c").fontSize(14).fontColor(COLORS.primary).fontWeight(FontWeight.Medium).onClick(() => { this.isRegister = !this.isRegister; this.errorMsg = "" })
        }.justifyContent(FlexAlign.Center)
      }.width("88%").padding({ top: 28, bottom: 24, left: 16, right: 16 }).backgroundColor(COLORS.card).borderRadius({ topLeft: 28, topRight: 28 }).margin({ top: -24 })
    }.width("100%").height("100%").backgroundColor(COLORS.primary)
  }

  async handleSubmit(): Promise<void> {
    this.errorMsg = ""
    if (this.phone.length < 11) { this.errorMsg = "\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7"; return }
    if (this.password.length < 6) { this.errorMsg = "\u5bc6\u7801\u81f3\u5c11 6 \u4f4d"; return }
    if (this.isRegister && !this.nickname.trim()) { this.errorMsg = "\u8bf7\u8f93\u5165\u6635\u79f0"; return }
    this.loading = true
    try {
      const user = this.isRegister ? await getApi().register(this.phone, this.nickname.trim(), this.password) : await getApi().login(this.phone, this.password)
      await UserManager.setUser(user, user.id)
      AppStorage.set("isLoggedIn", true)
    } catch (e) { this.errorMsg = "\u64cd\u4f5c\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5" }
    finally { this.loading = false }
  }
}
''')

print("Index + Login OK")