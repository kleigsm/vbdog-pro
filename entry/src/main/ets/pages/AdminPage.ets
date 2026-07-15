import { getApi } from "../common/ApiProvider"
import { Post, LevelItem, LEVELS } from "../common/Models"
import { COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
export struct AdminPage {
  @State posts: Post[] = []
  @State loading: boolean = true
  @State userCount: number = 0
  @State postCount: number = 0
  @State deletingId: string = ""

  aboutToAppear(): void { this.loadData() }

  build() {
    Column() {
      Row() { Text("管理后台").fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text); Blank() }.width("100%").padding(16)

      // Dashboard
      Row({ space: 12 }) {
        this.statCard("用户", this.userCount.toString(), COLORS.primary)
        this.statCard("帖子", this.postCount.toString(), COLORS.success)
      }.width("100%").padding({ left: 16, right: 16, bottom: 12 })

      Divider().strokeWidth(8).color("#F0F0F5")

      Row() { Text("所有帖子").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank() }.width("100%").padding(16)

      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else {
        List({ space: 1 }) {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              Row({ space: 12 }) {
                Column({ space: 2 }) {
                  Text(post.title).fontSize(14).fontColor(COLORS.text).maxLines(1)
                  Text("作者: " + (post.author?.nickname ?? "用户") + "  ❤️ " + post.likeCount).fontSize(11).fontColor(COLORS.textSecondary)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                if (this.deletingId === post.id) {
                  LoadingProgress().width(20).height(20)
                } else {
                  Text("删除").fontSize(12).fontColor(COLORS.error).onClick(() => this.deletePost(post))
                }
              }.width("100%").padding(14).backgroundColor(COLORS.card)
              .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } }))
            }
          })
        }.layoutWeight(1).backgroundColor("#F0F0F5")
      }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  @Builder statCard(label: string, value: string, color: string) {
    Column({ space: 4 }) {
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(color)
      Text(label).fontSize(12).fontColor(COLORS.textSecondary)
    }.width("47%").padding(16).backgroundColor(COLORS.card).borderRadius(12)
  }

  async loadData(): Promise<void> {
    this.loading = true
    try {
      // Get recent posts
      const allPosts: Post[] = await getApi().getPosts("", "latest", 0) as Post[]
      this.posts = allPosts
      this.postCount = allPosts.length
      this.userCount = 3 // placeholder
    } catch (e) { /* ignore */ }
    finally { this.loading = false }
  }

  async deletePost(post: Post): Promise<void> {
    const confirmed = alert("确认删除帖子「" + post.title + "」？", "管理后台", ["取消", "确认删除"])
    if (confirmed === "确认删除") {
      this.deletingId = post.id
      try {
        await getApi().deletePost(post.id)
        this.posts = this.posts.filter(p => p.id !== post.id)
        this.postCount--
      } catch (e) { /* ignore */ }
      finally { this.deletingId = "" }
    }
  }
}
