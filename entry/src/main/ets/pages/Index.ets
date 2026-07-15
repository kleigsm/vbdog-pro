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

  aboutToAppear(): void {
    setApi(new SupabaseClient())
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

  build() {
    if (!this.appReady) {
      Column() {
        Text("VBDog Pro").fontSize(32).fontWeight(FontWeight.Bold).fontColor(COLORS.primary)
        Text("AI Prompt 创作者社区").fontSize(14).fontColor(COLORS.textSecondary).margin({ top: 8 })
        LoadingProgress().width(32).height(32).margin({ top: 40 }).color(COLORS.primary)
      }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(COLORS.background)
    } else if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Tabs({ index: $$this.currentTab }) {
        TabContent() { FeedPage() }.tabBar(this.tabLabel("发现", "🔥"))
        TabContent() { SearchPage() }.tabBar(this.tabLabel("搜索", "🔍"))
        TabContent() { CreatePage() }.tabBar(this.tabLabel("发布", "✏️"))
        TabContent() { this.messageCombined() }.tabBar(this.tabLabel("消息", "💬"))
        TabContent() { ProfilePage() }.tabBar(this.tabLabel("我的", "👤"))
      }.barMode(BarMode.Fixed).barHeight(56).barPosition(BarPosition.End).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    }
  }

  @Builder messageCombined() { Tabs() { TabContent() { NotificationsPage() }.tabBar("通知"); TabContent() { MessagesPage() }.tabBar("私信") } }
  @Builder tabLabel(label: string, icon: string) { Column({ space: 2 }) { Text(icon).fontSize(20); Text(label).fontSize(10) }.width("100%") }
}
