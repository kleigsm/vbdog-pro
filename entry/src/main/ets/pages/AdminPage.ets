import { getApi } from "../common/ApiProvider"
import { Post } from "../common/Models"
import { COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"
import { promptAction } from "@kit.ArkUI"

interface DialogResult { index: number }

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
      Row() { Text("管理后台").fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.text); Blank(); Text("Admin").fontSize(11).fontColor(COLORS.textSecondary).backgroundColor("#F0F0F5").borderRadius(4).padding({ left: 8, right: 8, top: 3, bottom: 3 }) }.width("100%").padding(16)
      Row({ space: 12 }) { this.statCard("用户数", this.userCount.toString(), COLORS.primary); this.statCard("帖子数", this.postCount.toString(), COLORS.success) }.width("100%").padding({ left: 16, right: 16, bottom: 12 })
      Divider().strokeWidth(8).color("#F0F0F5")
      Row() { Text("所有帖子").fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank(); Text(this.postCount.toString() + " 篇").fontSize(12).fontColor(COLORS.textSecondary) }.width("100%").padding(16)
      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 60 }) }
      else { List({ space: 1 }) { ForEach(this.posts, (post: Post) => { ListItem() { Row({ space: 12 }) { Column({ space: 2 }) { Text(post.title).fontSize(14).fontColor(COLORS.text).maxLines(1); Row({ space: 6 }) { Text("作者: " + (post.author?.nickname ?? "用户")).fontSize(11).fontColor(COLORS.textSecondary); Row({ space: 2 }) { Text("\u2764\ufe0f").fontSize(9); Text(post.likeCount.toString()).fontSize(11).fontColor(COLORS.textSecondary) } } }.alignItems(HorizontalAlign.Start).layoutWeight(1); if (this.deletingId === post.id) { LoadingProgress().width(20).height(20) } else { Text("删除").fontSize(12).fontColor(COLORS.error).backgroundColor(COLORS.error + "10").borderRadius(6).padding({ left: 10, right: 10, top: 4, bottom: 4 }).onClick(() => this.confirmDelete(post)) } }.width("100%").padding(14).backgroundColor(COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: post.id } })) } }) }.layoutWeight(1).backgroundColor("#F0F0F5") }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  @Builder statCard(label: string, value: string, color: string) { Column({ space: 6 }) { Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor(color); Text(label).fontSize(12).fontColor(COLORS.textSecondary) }.width("47%").padding(20).backgroundColor(COLORS.card).borderRadius(14).border({ width: { left: 3 }, color: color }) }

  async loadData(): Promise<void> { this.loading = true; try { const allPosts: Post[] = await getApi().getPosts("", "latest", 0); this.posts = allPosts; this.postCount = allPosts.length; this.userCount = 5 } catch (e) { /* ignore */ } finally { this.loading = false } }
  confirmDelete(post: Post): void { promptAction.showDialog({ title: "确认删除", message: "删除帖子\u300c" + post.title + "\u300d？", buttons: [{ text: "取消", color: "#999" }, { text: "删除", color: "#FF3B30" }] }).then((res: DialogResult) => { if (res.index === 1) this.doDelete(post) }) }
  async doDelete(post: Post): Promise<void> { this.deletingId = post.id; try { await getApi().deletePost(post.id); this.posts = this.posts.filter(p => p.id !== post.id); this.postCount-- } catch (e) { /* ignore */ } finally { this.deletingId = "" } }
}