import { UserManager } from "../common/UserManager"
import { SupabaseClient } from "../common/SupabaseClient"
import { getApi, setApi } from "../common/ApiProvider"
import { C_PRIMARY, C_BG, C_DARK_BG, C_TEXT2, C_DARK_TEXT2, C_TEXT3, C_CARD, C_DARK_CARD, C_BORDER, C_DARK_BORDER, S_XS, S_XL, F_CAPT, F_BODY, F_H1 } from "../common/Constants"
import { LoginPage } from "./LoginPage"
import { FeedPage } from "./FeedPage"
import { SearchPage } from "./SearchPage"
import { CreatePage } from "./CreatePage"
import { ProfilePage } from "./ProfilePage"
import { NotificationsPage } from "./NotificationsPage"

AppStorage.setOrCreate("isLoggedIn", false)

interface TabItem { idx: number; title: string; icon: string }

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
        Column({ space: 16 }) {
          Text("🐤").fontSize(80)
          Text("VBDog Pro").fontSize(F_H1).fontWeight(FontWeight.Bold).fontColor(C_PRIMARY)
          Text("AI Prompt 创作者社区").fontSize(F_BODY).fontColor(C_TEXT2)
          LoadingProgress().width(28).height(28).margin({ top: 24 }).color(C_PRIMARY)
        }.justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? C_DARK_BG : C_BG)
    } else if (!this.isLoggedIn) {
      LoginPage()
    } else {
      Column() {
        Tabs({ index: $$this.currentTab }) {
          TabContent() { FeedPage() }
          TabContent() { SearchPage() }
          TabContent() { CreatePage({ onCreated: () => { this.currentTab = 0 } }) }
          TabContent() { NotificationsPage() }
          TabContent() { ProfilePage() }
        }
        .barHeight(0).width("100%").layoutWeight(1)
        .onChange((i: number) => { this.currentTab = i })

        Row() {
          ForEach(this.tabs, (t: TabItem) => { this.makeTab(t) }, (t: TabItem) => t.idx.toString())
        }
        .width("100%").padding({ left: S_XL, right: S_XL, top: S_XS, bottom: 4 })
        .backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderWidth({ top: 0.5 }).borderColor(this.isDark ? C_DARK_BORDER : C_BORDER)
      }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
    }
  }

  private tabs: TabItem[] = [
    { idx: 0, title: "发现", icon: "🔥" },
    { idx: 1, title: "搜索", icon: "🔍" },
    { idx: 2, title: "发布", icon: "" },
    { idx: 3, title: "动态", icon: "💬" },
    { idx: 4, title: "我的", icon: "👤" },
  ]

  @Builder makeTab(t: TabItem) {
    Column() {
      if (t.idx === 2) {
        Column() {
          Text("+").fontSize(26).fontColor("#FFFFFF").fontWeight(FontWeight.Bold)
        }
        .width(42).height(42).borderRadius(21).backgroundColor(C_PRIMARY).justifyContent(FlexAlign.Center)
        .shadow({ radius: 6, color: C_PRIMARY + "60", offsetY: 2 })
      } else {
        Text(t.icon).fontSize(20)
      }
      if (t.idx !== 2) {
        Text(t.title).fontSize(F_CAPT).fontColor(this.currentTab === t.idx ? C_PRIMARY : C_TEXT3)
          .fontWeight(this.currentTab === t.idx ? FontWeight.Bold : FontWeight.Normal).margin({ top: 2 })
      }
    }
    .layoutWeight(1).height(54).justifyContent(FlexAlign.Center)
    .onClick(() => { this.currentTab = t.idx })
  }
}
