/**
 * Index — 主容器页面
 * 应用启动的第一个页面，Tab 导航入口
 */

@Entry
@Component
struct Index {
  @State currentTab: number = 0

  build() {
    Tabs({ index: $$this.currentTab }) {
      TabContent() {
        Text("Feed")
      }.tabBar("发现")

      TabContent() {
        Text("Search")
      }.tabBar("搜索")

      TabContent() {
        Text("Create")
      }.tabBar("发布")

      TabContent() {
        Text("Messages")
      }.tabBar("消息")

      TabContent() {
        Text("Profile")
      }.tabBar("我的")
    }
    .barMode(BarMode.Fixed)
  }
}
