import { C_DARK_BG, C_BG, C_DARK_CARD, C_CARD, C_DARK_TEXT1, C_TEXT1, C_DARK_TEXT2, C_TEXT2, C_DARK_TEXT3, C_TEXT3, C_PRIMARY, C_RED, S_XS, S_SM, S_MD, S_LG, S_XL, S_2XL, R_LG, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { Post } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
export struct ProfilePage {
  @StorageLink("isDark") isDark: boolean = false
  @StorageLink("isLoggedIn") isLoggedIn: boolean = false
  @State tab: number = 0
  @State nick: string = ""
  @State bio: string = ""
  @State av: string = "🐤"
  @State uname: string = ""
  @State lv: number = 1
  @State fol: number = 0
  @State fow: number = 0
  @State lks: number = 0
  @State myPosts: Post[] = []
  @State likedPosts: Post[] = []
  @State collectedPosts: Post[] = []
  @State loading: boolean = true
  @State adminPostCount: number = 0
  @State adminUserCount: number = 0
  @State adminCommentCount: number = 0
  @State adminReportCount: number = 0

  aboutToAppear(): void { this.refresh(); setTimeout(() => { this.refresh() }, 300) }
  onPageShow(): void { this.refresh() }

  getLevelTitle(): string {
    if (this.lv >= 10) return "🎳 传奇创作者"
    if (this.lv >= 7) return "💵 资深大师"
    if (this.lv >= 5) return "⭐ 高级玩家"
    if (this.lv >= 3) return "🔡 熟练用户"
    return "🌡 新手入门"
  }

  getLevelProgress(): number {
    const thresholds = [0, 100, 500, 1500, 5000, 15000, 50000, 100000, 200000, 500000]
    const current = thresholds[Math.min(this.lv - 1, thresholds.length - 1)]
    const next = thresholds[Math.min(this.lv, thresholds.length - 1)]
    if (next === current) return 100
    const exp = UserManager.currentUser?.exp ?? 0
    return Math.min(100, Math.round(((exp - current) / (next - current)) * 100))
  }

  async refresh(): Promise<void> {
    this.loading = true
    const uid = UserManager.currentUser?.id
    if (!uid) {
      this.loading = false
      return
    }
    try {
      const fresh = await getApi().getUserProfile(uid)
      this.nick = fresh?.nickname ?? "用户"
      this.bio = fresh?.bio ?? ""
      this.uname = fresh?.phone ?? ""
      this.lv = fresh?.level ?? 1
      this.fol = fresh?.followerCount ?? 0
      this.fow = fresh?.followingCount ?? 0
      UserManager.currentUser!.followerCount = this.fol
      UserManager.currentUser!.followingCount = this.fow
      UserManager.currentUser!.level = this.lv
    } catch (_e) {
      const user = UserManager.currentUser
      this.nick = user?.nickname ?? "用户"
      this.bio = user?.bio ?? ""
      this.uname = user?.phone ?? ""
      this.lv = user?.level ?? 1
      this.fol = user?.followerCount ?? 0
      this.fow = user?.followingCount ?? 0
    }
    this.loadPosts()
    if (UserManager.isAdmin) this.loadAdminStats()
  }

  async loadPosts(): Promise<void> {
    const uid = UserManager.currentUser?.id
    if (!uid) { this.loading = false; return }
    try {
      this.myPosts = await getApi().getUserPosts(uid) as Post[]
      this.lks = 0
      for (let i = 0; i < this.myPosts.length; i++) {
        this.lks += this.myPosts[i].likeCount
      }
    } catch (_e) {
      this.myPosts = []
      this.lks = 0
    } finally {
      this.loading = false
    }
  }

  async loadLiked(): Promise<void> {
    this.loading = true
    const uid = UserManager.currentUser?.id
    if (!uid) { this.loading = false; return }
    try {
      this.likedPosts = await getApi().getUserLikes(uid) as Post[]
    } catch (_e) { this.likedPosts = [] }
    finally { this.loading = false }
  }

  async loadCollected(): Promise<void> {
    this.loading = true
    const uid = UserManager.currentUser?.id
    if (!uid) { this.loading = false; return }
    try {
      this.collectedPosts = await getApi().getUserCollections(uid) as Post[]
    } catch (_e) { this.collectedPosts = [] }
    finally { this.loading = false }
  }

  async deleteMyPost(post: Post): Promise<void> {
    try {
      await getApi().deletePost(post.id)
      this.myPosts = this.myPosts.filter((p: Post) => p.id !== post.id)
    } catch (_e) { }
  }
  async loadAdminStats(): Promise<void> {
    try {
      const posts = await getApi().getPosts("", "latest", 0)
      this.adminPostCount = posts.length
      this.adminUserCount = (await getApi().getAllUsers()).length
      this.adminCommentCount = (await getApi().getAllComments()).length
      const reports = await getApi().getReports()
      this.adminReportCount = reports.length
    } catch (_e) { }
  }

  build() {
    Column() {
      // Profile header
      Column() {
        Row() {
          Text(this.nick.charAt(0)).fontSize(40).fontColor("#FFF")
            .width(64).height(64).borderRadius(32).textAlign(TextAlign.Center)
            .backgroundColor(this.getAvatarColor(this.nick))
          Column() {
            Text(this.nick).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            Text("@用户" + (UserManager.currentUser?.level ?? 1)).fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 2 })
            Row() {
              Text("Lv." + this.lv).fontSize(F_CAPT).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
                .padding({ left: S_SM, right: S_SM, top: 2, bottom: 2 }).backgroundColor("#FFF3E0").borderRadius(8)
              Text(this.getLevelTitle()).fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ left: S_SM })
            }.margin({ top: 4 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: S_LG })
          Text("编辑").fontSize(F_SM).fontColor(C_PRIMARY)
            .padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM })
            .borderRadius(16).borderWidth(1).borderColor(C_PRIMARY)
            .onClick(() => { router.pushUrl({ url: "pages/EditProfilePage" }) })
        }.width("100%")

        if (this.bio) {
          Text(this.bio).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).margin({ top: S_MD }).width("100%")
        }

        // Level progress bar
        Row() {
          Column() {}.width(this.getLevelProgress().toString() + "%").height("100%")
            .borderRadius(3).backgroundColor(C_PRIMARY)
        }.width("100%").height(4).backgroundColor(this.isDark ? C_DARK_BG : C_BG).borderRadius(3).margin({ top: S_MD })
        Text("升级进度 " + this.getLevelProgress() + "%").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: S_XS })

        // Stats
        Row() {
          Column() {
            Text(this.fol.toString()).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            Text("粉丝").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
          }.onClick(() => { router.pushUrl({ url: "pages/FollowListPage", params: { userId: UserManager.currentUser?.id ?? "", type: "follower" } }) })
          Column() {
            Text(this.fow.toString()).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            Text("关注").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
          }.margin({ left: S_2XL }).onClick(() => { router.pushUrl({ url: "pages/FollowListPage", params: { userId: UserManager.currentUser?.id ?? "", type: "following" } }) })
          Column() {
            Text(this.lks.toString()).fontSize(F_LG).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).fontWeight(FontWeight.Bold)
            Text("获赞").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
          }.margin({ left: S_2XL })
        }.width("100%").margin({ top: S_MD })
      }.width("100%").padding(S_LG).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

      // Admin panel (only for admin)
      if (UserManager.isAdmin) {
        Column() {
          Row() {
            Column() {
              Text(this.adminPostCount.toString()).fontSize(20).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("帖子").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text(this.adminUserCount.toString()).fontSize(20).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("用户").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text(this.adminCommentCount.toString()).fontSize(20).fontColor(C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("评论").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text(this.adminReportCount.toString()).fontSize(20).fontColor(this.adminReportCount > 0 ? "#FF4757" : C_PRIMARY).fontWeight(FontWeight.Bold)
              Text("举报").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM })
          Button("🔰 进入管理后台").fontSize(F_BODY).fontColor("#FFFFFF").fontWeight(FontWeight.Bold)
            .backgroundColor(C_PRIMARY).borderRadius(20).height(44).width("92%")
            .onClick(() => { router.pushUrl({ url: "pages/AdminPage" }) })
            .margin({ top: S_MD, bottom: S_LG })
        }.width("100%").backgroundColor(this.isDark ? C_DARK_CARD : C_CARD).margin({ top: S_MD }).borderRadius(16)
      }

      // Tab bar
      Row() {
        ForEach(UserManager.isAdmin ? ["我的发布"] : ["我的发布", "我的喜欢", "我的收藏"], (t: string, i: number) => {
          Text(t).fontSize(F_BODY).fontColor(this.tab === i ? C_PRIMARY : C_TEXT2)
            .fontWeight(this.tab === i ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: S_MD, bottom: S_MD })
            .borderWidth({ bottom: this.tab === i ? 2 : 0 }).borderColor(this.tab === i ? C_PRIMARY : Color.Transparent)
            .onClick(() => {
              this.tab = i
              if (i === 0) this.loadPosts()
              else if (i === 1) this.loadLiked()
              else this.loadCollected()
            })
        }, (_t: string, i: number) => i.toString())
      }.width("100%").backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)

      // Content
      if (this.loading) {
        LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 60 })
        } else if (this.tab === 0) {
          if (this.myPosts.length === 0) {
            Column() { Text("暂无发布").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 60 }) }.width("100%").layoutWeight(1)
          } else {
            List() {
              ForEach(this.myPosts, (p: Post) => {
                ListItem() {
                Row() {
                  Column() {
                    Text(p.title).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).maxLines(1).width("100%")
                    Text(p.likeCount + "赞 · " + p.commentCount + "评论").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 2 })
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Button("删除").fontSize(11).fontColor("#FFFFFF").backgroundColor(C_RED).borderRadius(10).height(28)
                    .padding({ left: S_MD, right: S_MD })
                    .onClick(() => this.deleteMyPost(p))
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: p.id } }))
              }
            }, (p: Post) => p.id)
          }.layoutWeight(1).width("100%")
        }
        } else if (this.tab === 1 && !UserManager.isAdmin) {
        if (this.likedPosts.length === 0) {
          Column() { Text("暂无喜欢").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 60 }) }.width("100%").layoutWeight(1)
        } else if (!UserManager.isAdmin) {
          List() {
            ForEach(this.likedPosts, (p: Post) => {
              ListItem() {
                Row() {
                  Text("❤️").fontSize(16).margin({ right: S_MD })
                  Text(p.title).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).layoutWeight(1).maxLines(1)
                  Text(p.author?.nickname ?? "").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: p.id } }))
              }
            }, (p: Post) => p.id)
          }.layoutWeight(1).width("100%")
        }
      } else {
        if (this.collectedPosts.length === 0) {
          Column() { Text("暂无收藏").fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3).margin({ top: 60 }) }.width("100%").layoutWeight(1)
        } else {
          List() {
            ForEach(this.collectedPosts, (p: Post) => {
              ListItem() {
                Row() {
                  Text("⭐").fontSize(16).margin({ right: S_MD })
                  Text(p.title).fontSize(F_BODY).fontColor(this.isDark ? C_DARK_TEXT1 : C_TEXT1).layoutWeight(1).maxLines(1)
                  Text(p.author?.nickname ?? "").fontSize(F_CAPT).fontColor(this.isDark ? C_DARK_TEXT3 : C_TEXT3)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: p.id } }))
              }
            }, (p: Post) => p.id)
          }.layoutWeight(1).width("100%")
        }
      }

      // Settings + Logout
      Row() {
        Text("设置").fontSize(F_SM).fontColor(this.isDark ? C_DARK_TEXT2 : C_TEXT2).onClick(() => { router.pushUrl({ url: "pages/SettingsPage" }) })
        Blank()
        Text("退出登录").fontSize(F_SM).fontColor(C_RED).onClick(() => {
          UserManager.clear(); AppStorage.set("isLoggedIn", false)
        })
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM }).backgroundColor(this.isDark ? C_DARK_CARD : C_CARD)
    }.width("100%").height("100%").backgroundColor(this.isDark ? C_DARK_BG : C_BG)
  }

  getAvatarColor(nickname: string): string {
    const colors: string[] = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"]
    let hash = 0
    for (let i = 0; i < nickname.length; i++) { hash = nickname.charCodeAt(i) + ((hash << 5) - hash) }
    return colors[Math.abs(hash) % colors.length]
  }
}
