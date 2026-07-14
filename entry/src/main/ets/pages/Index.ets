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

@Entry
@Component
struct Index {
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @State currentTab: number = 0

  aboutToAppear(): void {
    setApi(new SupabaseClient())
    UserManager.init().then(() => {
      AppStorage.set("isLoggedIn", UserManager.isLoggedIn)
      if (UserManager.isLoggedIn) {
        const api = getApi() as SupabaseClient
        const user = UserManager.currentUser
        if (user) api.setUserId(user.id)
      }
    })
  }

  build() {
    if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Tabs({ index: $$this.currentTab }) {
        TabContent() { FeedPage() }.tabBar(this.tabLabel("发现", "🔥"))
        TabContent() { SearchPage() }.tabBar(this.tabLabel("搜索", "🔍"))
        TabContent() { CreatePage() }.tabBar(this.tabLabel("发布", "✏️"))
        TabContent() { this.messageCombined() }.tabBar(this.tabLabel("消息", "💬"))
        TabContent() { ProfilePage() }.tabBar(this.tabLabel("我的", "👤"))
      }
      .barMode(BarMode.Fixed).barHeight(56)
      .backgroundColor(COLORS.background)
    }
  }

  @Builder messageCombined() {
    Tabs() {
      TabContent() { NotificationsPage() }.tabBar("通知")
      TabContent() { MessagesPage() }.tabBar("私信")
    }
  }

  @Builder tabLabel(label: string, icon: string) {
    Column({ space: 2 }) { Text(icon).fontSize(20); Text(label).fontSize(10) }.width("100%")
  }
}
