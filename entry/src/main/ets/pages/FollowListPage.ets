import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, S_XS, S_SM, S_MD, S_LG, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { User } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import router from "@ohos.router"
import { promptAction } from "@kit.ArkUI"
import { UserManager } from "../common/UserManager"

@Entry
@Component
struct FollowListPage {
  @StorageLink("isDark") isDark: boolean = false
  @State users: User[] = []
  @State loading: boolean = true
  @State title: string = ""
  private userId: string = ""
  private listType: string = ""

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.userId = (params["userId"] as string) ?? ""
      this.listType = (params["type"] as string) ?? "follower"
      this.title = this.listType === "follower" ? "\u7c89\u4e1d" : "\u5173\u6ce8"
      this.loadList()
    }
  }

  async loadList(): Promise<void> {
    this.loading = true
    try {
      if (this.listType === "follower") {
        this.users = await getApi().getFollowers(this.userId) as User[]
      } else {
        this.users = await getApi().getFollowing(this.userId) as User[]
      }
    } catch (_e) { this.users = [] }
    finally { this.loading = false }
  }

  avatarColor(nick: string): string {
    const colors = ["#FF6B35", "#FF4444", "#00C853", "#2979FF", "#AA00FF", "#FF6D00", "#00BCD4", "#E91E63"]
    let hash = 0
    for (let i = 0; i < nick.length; i++) hash = nick.charCodeAt(i) + ((hash << 5) - hash)
    return colors[Math.abs(hash) % colors.length]
  }

  build() {
    Column() {
      Row() {
        Text(this.title).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM }).backgroundColor(C_CARD)

      if (this.loading) {
        LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: "30%" })
      } else if (this.users.length === 0) {
        Text(this.listType === "follower" ? "\u8fd8\u6ca1\u6709\u7c89\u4e1d" : "\u8fd8\u6ca1\u6709\u5173\u6ce8\u7684\u4eba").fontSize(F_BODY)
          .fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).width("100%").textAlign(TextAlign.Center).margin({ top: "30%" })
      } else {
        Scroll() {
          Column() {
            ForEach(this.users, (u: User) => {
              Row() {
                Text(u.nickname.charAt(0)).fontSize(20).fontColor("#FFF")
                  .width(40).height(40).borderRadius(20).textAlign(TextAlign.Center)
                  .backgroundColor(this.avatarColor(u.nickname))
                  .onClick(() => { router.pushUrl({ url: "pages/UserPage", params: { userId: u.id } }) })
                Column() {
                  Text(u.nickname).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Medium)
                  if (u.bio) {
                    Text(u.bio).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }.margin({ left: S_MD }).alignItems(HorizontalAlign.Start).layoutWeight(1)
                  .onClick(() => { router.pushUrl({ url: "pages/UserPage", params: { userId: u.id } }) })
                Text("Lv." + u.level).fontSize(F_CAPT).fontColor(C_PRIMARY).margin({ right: S_SM })
                if (u.id !== UserManager.currentUser?.id) {
                  if (this.listType === "following") {
                    Button("已关注").fontSize(F_CAPT).fontColor(C_PRIMARY)
                      .backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).borderRadius(12).height(28)
                      .padding({ left: S_SM, right: S_SM }).borderWidth(1).borderColor(C_PRIMARY)
                      .onClick(async () => {
                        try {
                          await getApi().followUser(u.id)
                          this.users = this.users.filter((x: User) => x.id !== u.id)
                          promptAction.showToast({ message: "已取关", duration: 1000 })
                        } catch (_e) {
                          promptAction.showToast({ message: "操作失败", duration: 1500 })
                        }
                      })
                  } else {
                    Button("+ 关注").fontSize(F_CAPT).fontColor("#FFFFFF")
                      .backgroundColor(C_PRIMARY).borderRadius(12).height(28)
                      .padding({ left: S_SM, right: S_SM })
                      .onClick(async () => {
                        try {
                          await getApi().followUser(u.id)
                          promptAction.showToast({ message: "已关注", duration: 1000 })
                        } catch (_e) {
                          promptAction.showToast({ message: "操作失败", duration: 1500 })
                        }
                      })
                  }
                }
              }.width("100%").padding(S_LG)
            }, (u: User) => u.id)
          }.width("100%").justifyContent(FlexAlign.Start)
        }.width("100%")
      }
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }
}
