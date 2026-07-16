import { UserManager } from "../common/UserManager"
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
    animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.logoScale = 1
    })
    setTimeout(() => {
      animateTo({ duration: 200 }, () => {
        this.splashOpacity = 0.6
      })
    }, 600)
  }

  build() {
    if (!this.appReady) {
      Column() {
        Column({ space: 12 }) {
          Text("VBDog Pro")
            .fontSize(36).fontWeight(FontWeight.Bold)
            .fontColor(COLORS.primary)
            .scale({ x: this.logoScale, y: this.logoScale })
            .opacity(this.splashOpacity)
          Text("AI Prompt 创作者社区")
            .fontSize(15)
            .fontColor(COLORS.textSecondary)
            .opacity(this.splashOpacity)
          LoadingProgress()
            .width(28).height(28)
            .margin({ top: 32 })
            .color(COLORS.primary)
            .opacity(this.splashOpacity)
        }.justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }.width("100%").height("100%").justifyContent(FlexAlign.Center)
       .backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    } else if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Tabs({ index: $$this.currentTab }) {
        TabContent() { FeedPage() }.tabBar(this.tabLabel("发现", 0))
        TabContent() { SearchPage() }.tabBar(this.tabLabel("搜索", 1))
        TabContent() { CreatePage() }.tabBar(this.tabLabel("发布", 2))
        TabContent() { this.messageCombined() }.tabBar(this.tabLabel("消息", 3))
        TabContent() { ProfilePage() }.tabBar(this.tabLabel("我的", 4))
      }
      .barMode(BarMode.Fixed).barHeight(56).barPosition(BarPosition.End)
      .backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    }
  }

  @Builder messageCombined() {
    Tabs() {
      TabContent() { NotificationsPage() }.tabBar("通知")
      TabContent() { MessagesPage() }.tabBar("私信")
    }
  }

  @Builder tabLabel(label: string, index: number) {
    Column({ space: 2 }) {
      Row().width(20).height(3).borderRadius(2)
        .backgroundColor(this.currentTab === index ? COLORS.primary : Color.Transparent)
      Text(this.getTabIcon(index))
        .fontSize(20)
        .fontColor(this.currentTab === index ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary))
        .scale({ x: this.currentTab === index ? 1.1 : 1, y: this.currentTab === index ? 1.1 : 1 })
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === index ? COLORS.primary : (this.isDark ? COLORS.textSecondaryDark : COLORS.textSecondary))
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
    }.width("100%").alignItems(HorizontalAlign.Center)
    .padding({ top: 4 })
  }

  getTabIcon(index: number): string {
    const icons: string[] = ["🔥", "🔍", "✏", "💬", "👤"]
    return icons[index]
  }
}
