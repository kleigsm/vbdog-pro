/**
 * ProfilePage — 个人主页
 */

import { getApi } from "../common/ApiProvider"
import { Post, LEVELS, AVATAR_COLORS } from "../common/Models"
import { COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"

@Entry
@Component
struct ProfilePage {
  @State posts: Post[] = []
  @State loading: boolean = true
  @State activeTab: number = 0  // 0=帖子, 1=收藏
  @Link isLoggedIn: boolean

  aboutToAppear(): void { this.loadData() }

  build() {
    Column() {
      // 用户信息卡片
      Column({ space: 8 }) {
        // 头像
        Text(UserManager.currentUser?.nickname?.charAt(0) ?? "用")
          .fontSize(36).fontColor("#FFF")
          .width(72).height(72).borderRadius(36)
          .textAlign(TextAlign.Center)
          .backgroundColor(AVATAR_COLORS[(UserManager.currentUser?.nickname?.length ?? 0) % AVATAR_COLORS.length])

        Text(UserManager.currentUser?.nickname ?? "用户")
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.text)

        Text(this.getLevelTitle(UserManager.currentUser?.level ?? 1))
          .fontSize(12).fontColor(COLORS.primary)
          .backgroundColor(COLORS.primary + "14")
          .borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 })

        if (UserManager.currentUser?.bio) {
          Text(UserManager.currentUser.bio)
            .fontSize(13).fontColor(COLORS.textSecondary).maxLines(2)
        }

        // 统计数据
        Row({ space: 24 }) {
          this.statItem(this.posts.length.toString(), "帖子")
          this.statItem((UserManager.currentUser?.followingCount ?? 0).toString(), "关注")
          this.statItem((UserManager.currentUser?.followerCount ?? 0).toString(), "粉丝")
        }.margin({ top: 8 })

        // 编辑按钮
        Button("编辑资料")
          .fontSize(13).height(32)
          .backgroundColor("#F0F0F5").fontColor(COLORS.text)
          .borderRadius(16)
          .onClick(() => { /* TODO: EditProfile */ })
      }
      .width("100%").padding({ top: 20, bottom: 16 })
      .backgroundColor(COLORS.card)

      // Tab: 帖子 / 收藏
      Row({ space: 0 }) {
        Button("帖子").fontSize(14)
          .fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.activeTab === 0 ? COLORS.primary : COLORS.textSecondary)
          .type(ButtonType.Normal).backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.activeTab = 0; this.loadPosts() })
        Button("收藏").fontSize(14)
          .fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(this.activeTab === 1 ? COLORS.primary : COLORS.textSecondary)
          .type(ButtonType.Normal).backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => { this.activeTab = 1; this.loadCollections() })
      }.width("100%").height(44)

      Divider().strokeWidth(0.5).color("#E5E5EA")

      // 帖子列表
      if (this.loading) {
        LoadingProgress().width(32).height(32).margin({ top: 60 })
      } else if (this.posts.length === 0) {
        Text(this.activeTab === 0 ? "还没有发布帖子" : "还没有收藏帖子")
          .fontSize(13).fontColor(COLORS.textSecondary).margin({ top: 60 })
      } else {
        List({ space: 1 }) {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(post.title)
                  .fontSize(14).fontColor(COLORS.text).maxLines(1).layoutWeight(1)
                Text("❤️ " + post.likeCount + "  💬 " + post.commentCount)
                  .fontSize(11).fontColor(COLORS.textSecondary)
              }
              .width("100%").padding(14)
              .backgroundColor(COLORS.card)
              .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }))
            }
          })
        }.layoutWeight(1).backgroundColor("#F0F0F5")
      }

      // 退出登录
      Button("退出登录")
        .fontSize(13).fontColor(COLORS.error)
        .type(ButtonType.Normal).backgroundColor(Color.Transparent)
        .width("100%").padding(14)
        .onClick(() => {
          UserManager.clear()
          this.isLoggedIn = false
        })
    }
    .width("100%").height("100%").backgroundColor(COLORS.background)
  }

  @Builder statItem(value: string, label: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text)
      Text(label).fontSize(11).fontColor(COLORS.textSecondary)
    }
  }

  async loadData() {
    this.loading = true
    await this.loadPosts()
    this.loading = false
  }

  async loadPosts() {
    try {
      const uid = UserManager.currentUser?.id
      if (uid) this.posts = await getApi().getUserPosts(uid)
    } catch { this.posts = [] }
  }

  async loadCollections() {
    this.loading = true
    try {
      const uid = UserManager.currentUser?.id
      if (uid) this.posts = await getApi().getUserCollections(uid)
    } catch { this.posts = [] }
    finally { this.loading = false }
  }

  getLevelTitle(level: number): string {
    return LEVELS.find(l => l.level === level)?.title ?? ""
  }
}
