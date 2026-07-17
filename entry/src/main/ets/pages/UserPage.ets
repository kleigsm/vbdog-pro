import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, S_SM, S_MD, S_LG, S_2XL, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { Post } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
struct UserPage {
  @StorageLink("isDark") isDark: boolean = false
  @State userId: string = ""
  @State nick: string = ""
  @State bio: string = ""
  @State lv: number = 1
  @State fol: number = 0
  @State fow: number = 0
  @State posts: Post[] = []
  @State loading: boolean = true

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    const uid: string = params && params["userId"] ? params["userId"] as string : ""
    if (uid) {
      this.userId = uid
      this.loadUser(uid)
    }
  }

  async loadUser(uid: string): Promise<void> {
    this.loading = true
    try {
      const user = await getApi().getUserProfile(uid)
      this.nick = user?.nickname ?? "用户"
      this.bio = user?.bio ?? ""
      this.lv = user?.level ?? 1
      this.fol = user?.followerCount ?? 0
      this.fow = user?.followingCount ?? 0
      this.posts = await getApi().getUserPosts(uid) as Post[]
    } catch (_e) { }
    finally { this.loading = false }
  }

  getApi().blockUser(this.userId)
                promptAction.showToast({ message: "已屏蔽" }): void {
    router.pushUrl({ url: "pages/MessagesPage", params: { chatWith: this.userId, chatName: this.nick } })
  }

  build() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1)
          .onClick(() => { router.back() })
        Text(this.nick || "用户主页").fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

      if (this.loading) {
        LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 80 })
      } else {
        Column() {
          Text(this.nick.charAt(0)).fontSize(48).fontColor("#FFF")
            .width(72).height(72).borderRadius(36).textAlign(TextAlign.Center)
            .backgroundColor(this.getAvatarColor(this.nick))

          Text(this.nick).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold).margin({ top: S_MD })
          Text("Lv." + this.lv).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
          if (this.bio) {
            Text(this.bio).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ top: S_SM }).textAlign(TextAlign.Center).width("80%")
          }

          Row() {
            Column() {
              Text(this.fol.toString()).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
              Text("粉丝").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }
            Column() {
              Text(this.fow.toString()).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
              Text("关注").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.margin({ left: S_2XL })
          }.width("100%").margin({ top: S_MD })

          Row() {
            Button("+ 关注").fontSize(F_BODY).fontColor("#FFFFFF").backgroundColor(C_PRIMARY)
              .borderRadius(20).height(36).layoutWeight(1)
              .onClick(() => { promptAction.showToast({ message: "已关注", duration: 1000 }) })
            Button("屏蔽").fontSize(F_BODY).fontColor(C_PRIMARY).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)
              .borderRadius(20).height(36).layoutWeight(1).margin({ left: S_MD })
              .borderWidth(1).borderColor(C_PRIMARY)
              .onClick(() => { this.getApi().blockUser(this.userId)
                promptAction.showToast({ message: "已屏蔽" }) })
          }.width("100%").margin({ top: S_MD })
        }.width("100%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

        if (this.posts.length > 0) {
          List() {
            ForEach(this.posts, (p: Post) => {
              ListItem() {
                Row() {
                  Text(p.title).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).maxLines(1).layoutWeight(1)
                  Text(p.likeCount.toString()).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => { router.pushUrl({ url: "pages/PostDetailPage", params: { postId: p.id } }) })
              }
            }, (p: Post) => p.id)
          }.layoutWeight(1).width("100%")
        } else {
          Column() { Text("暂无帖子").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 40 }) }.width("100%").layoutWeight(1)
        }
      }
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }

  getAvatarColor(nickname: string): string {
    const colors: string[] = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
    let hash = 0
    for (let i = 0; i < nickname.length; i++) { hash = nickname.charCodeAt(i) + ((hash << 5) - hash) }
    return colors[Math.abs(hash) % colors.length]
  }
}
