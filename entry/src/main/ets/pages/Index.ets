/**
 * Index — 主容器
 * 未登录显示 LoginPage，已登录显示 Tab 导航
 */

import { UserManager } from "../common/UserManager"
import { SupabaseClient } from "../common/SupabaseClient"
import { getApi, setApi } from "../common/ApiProvider"
import { COLORS } from "../common/Constants"

@Entry
@Component
struct Index {
  @State isLoggedIn: boolean = false
  @State currentTab: number = 0

  aboutToAppear(): void {
    setApi(new SupabaseClient())
    UserManager.init().then(() => {
      this.isLoggedIn = UserManager.isLoggedIn
      if (this.isLoggedIn) {
        const api = getApi() as SupabaseClient
        const user = UserManager.currentUser
        if (user) api.setUserId(user.id)
      }
    })
  }

  build() {
    if (!this.isLoggedIn) {
      LoginPage({ isLoggedIn: $isLoggedIn })
    } else {
      Tabs({ index: $$this.currentTab }) {
        TabContent() {
          FeedPage({ isLoggedIn: $isLoggedIn })
        }.tabBar(this.tabLabel("发现", "🔍"))

        TabContent() {
          Column() { Text("搜索").fontSize(16) }
            .width("100%").height("100%")
            .justifyContent(FlexAlign.Center)
            .backgroundColor(COLORS.background)
        }.tabBar(this.tabLabel("搜索", "🔎"))

        TabContent() {
          Column() { Text("发布").fontSize(16) }
            .width("100%").height("100%")
            .justifyContent(FlexAlign.Center)
            .backgroundColor(COLORS.background)
        }.tabBar(this.tabLabel("发布", "✏️"))

        TabContent() {
          Column() { Text("消息").fontSize(16) }
            .width("100%").height("100%")
            .justifyContent(FlexAlign.Center)
            .backgroundColor(COLORS.background)
        }.tabBar(this.tabLabel("消息", "💬"))

        TabContent() {
          Column() { Text("我的").fontSize(16) }
            .width("100%").height("100%")
            .justifyContent(FlexAlign.Center)
            .backgroundColor(COLORS.background)
        }.tabBar(this.tabLabel("我的", "👤"))
      }
      .barMode(BarMode.Fixed)
      .barHeight(56)
      .backgroundColor(COLORS.background)
    }
  }

  @Builder tabLabel(label: string, icon: string) {
    Column({ space: 2 }) {
      Text(icon).fontSize(20)
      Text(label).fontSize(10)
    }
    .width("100%")
  }
}
