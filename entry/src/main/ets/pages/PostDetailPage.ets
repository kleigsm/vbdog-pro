import { getApi } from "../common/ApiProvider"
import { Post, Comment, LevelItem, LEVELS } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"
import { pasteboard } from "@kit.BasicServicesKit"
import { promptAction } from "@kit.ArkUI"

@Entry
@Component
struct PostDetailPage {
  @State post: Post | null = null
  @State comments: Comment[] = []
  @State newComment: string = ""
  @State loading: boolean = true
  @State liked: boolean = false
  @State collected: boolean = false
  @State likeAnimScale: number = 1
  @State collectAnimScale: number = 1
  @State replyTo: string = ""
  @State replyNickname: string = ""
  @State similarPosts: Post[] = []
  @State showDelete: boolean = false
  @StorageLink("isDark") isDark: boolean = false
  private postId: string = ""

  aboutToAppear(): void {
    const params: Object = router.getParams() as Object
    if (params) { const p: Record<string, string> = params as Record<string, string>; this.postId = p["postId"] ?? ""; this.loadAll() }
  }

  build() {
    if (this.loading) { Column() { LoadingProgress().width(40).height(40) }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background) }
    else if (!this.post) { Column({ space: 12 }) { Text("😕").fontSize(48); Text("帖子不存在").fontSize(15).fontColor(COLORS.textSecondary) }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background) }
    else {
      Column() {
        Row() { Text("← 返回").fontSize(15).fontColor(COLORS.primary).onClick(() => router.back()); Blank(); if (this.isOwnPost()) { Text("删除").fontSize(13).fontColor(COLORS.error).onClick(() => this.showDelete = true) } }.width("100%").padding(16)

        Scroll() {
          Column() {
            this.authorSection()
            Text(this.post!.title).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text).width("100%").padding({ left: 16, right: 16, top: 8, bottom: 12 })

            // Tags
            if (this.post!.tags && this.post!.tags.length > 0) {
              Row({ space: 6 }) {
                ForEach(this.post!.tags, (tag: string) => {
                  Text("#" + tag).fontSize(12).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "14").borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 }).onClick(() => this.searchTag(tag))
                })
              }.width("100%").padding({ left: 16, right: 16, bottom: 10 })
            }

            Text(this.post!.content).fontSize(15).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(24).width("100%").padding({ left: 16, right: 16, bottom: 16 })

            if (this.post!.category || this.post!.model) {
              Row({ space: 8 }) {
                if (this.post!.category) { Text(this.post!.category).fontSize(11).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "14").borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 }) }
                if (this.post!.model) { Text(this.post!.model).fontSize(11).fontColor(COLORS.textSecondary).backgroundColor(this.isDark ? "#3A3A4A" : "#F0F0F5").borderRadius(4).padding({ left: 8, right: 8, top: 2, bottom: 2 }) }
              }.padding({ left: 16, bottom: 12 })
            }

            if (this.post!.prompt) {
              Column() {
                Row() { Text("Prompt").fontSize(11).fontColor("#FFB800").backgroundColor("#FFB80020").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }); Blank(); Text("复制").fontSize(11).fontColor(COLORS.primary).onClick(() => { const pboard = pasteboard.getSystemPasteboard(); pboard.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post!.prompt)) }); Text("  改编").fontSize(11).fontColor(COLORS.primary).onClick(() => this.remixPost()) }.width("100%").margin({ bottom: 10 })
                Text(this.post!.prompt).fontSize(13).fontColor("#E5E5EA").fontFamily("monospace").lineHeight(22).width("100%")
              }.width("100%").padding(14).margin({ left: 16, right: 16, bottom: 16 }).backgroundColor("#1D1D1F").borderRadius(12)
            }

            this.actionBar()
            Divider().strokeWidth(8).color(this.isDark ? "#3A3A4A" : "#F0F0F5").margin({ top: 4, bottom: 4 })

            // Similar posts
            if (this.similarPosts.length > 0) {
              Column() {
                Text("推荐帖子").fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text).width("100%").padding({ left: 16, right: 16, top: 12, bottom: 8 })
                List({ space: 0 }) {
                  ForEach(this.similarPosts, (sp: Post) => {
                    ListItem() {
                      Row({ space: 10 }) { Text(sp.title).fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(1).layoutWeight(1); Text("❤️ " + sp.likeCount).fontSize(11).fontColor(COLORS.textSecondary) }
                      .width("100%").padding(14).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)
                      .onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: sp.id } }))
                    }
                  })
                }.height(150)
              }.width("100%")
              Divider().strokeWidth(8).color(this.isDark ? "#3A3A4A" : "#F0F0F5")
            }

            this.commentSection()
          }.width("100%")
        }.layoutWeight(1)

        if (this.replyTo) {
          Row() { Text("回复 " + this.replyNickname + "：").fontSize(12).fontColor(COLORS.textSecondary); Blank(); Text("✕").fontSize(14).fontColor(COLORS.textSecondary).onClick(() => { this.replyTo = ""; this.replyNickname = "" }) }.width("100%").padding({ left: 12, right: 12, top: 6, bottom: 6 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)
        }

        Row({ space: 10 }) {
          TextInput({ placeholder: "说点什么...", text: this.newComment }).layoutWeight(1).height(40).fontSize(14).backgroundColor(this.isDark ? "#3A3A4A" : "#F0F0F5").borderRadius(20).padding({ left: 16, right: 16 }).onChange((v: string) => { this.newComment = v })
          Button("发送").fontSize(13).height(36).backgroundColor(this.newComment.trim() ? COLORS.primary : "#CCC").borderRadius(18).onClick(() => this.submitComment())
        }.width("100%").padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).shadow({ radius: 4, color: "#00000008", offsetY: -2 })
      }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)

      // Delete dialog
      if (this.showDelete) {
        Column() {
          Column({ space: 12 }) {
            Text("确认删除").fontSize(18).fontWeight(FontWeight.Bold)
            Text("删除后无法恢复，确定要删除这个帖子吗？").fontSize(14).fontColor(COLORS.textSecondary).textAlign(TextAlign.Center)
            Row({ space: 12 }) {
              Button("取消").width("45%").height(40).backgroundColor("#F0F0F5").fontColor(COLORS.text).onClick(() => this.showDelete = false)
              Button("确认删除").width("45%").height(40).backgroundColor(COLORS.error).fontColor("#FFF").onClick(() => this.doDelete())
            }.width("100%").justifyContent(FlexAlign.Center)
          }.width("80%").padding(24).backgroundColor(COLORS.card).borderRadius(16)
        }.width("100%").height("100%").backgroundColor("#00000080").justifyContent(FlexAlign.Center).onClick(() => this.showDelete = false)
      }
    }
  }

  @Builder authorSection() {
    Row({ space: 10 }) {
      Text(this.post!.author?.nickname?.charAt(0) ?? "用").fontSize(20).fontColor("#FFF").width(44).height(44).borderRadius(22).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(this.post!.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
      Column({ space: 2 }) {
        Row({ space: 6 }) { Text(this.post!.author?.nickname ?? "用户").fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.getLevelTitle(this.post!.author?.level ?? 1)).fontSize(11).fontColor(COLORS.primary) }
        Text(this.formatTime(this.post!.createdAt)).fontSize(12).fontColor(COLORS.textSecondary)
      }.alignItems(HorizontalAlign.Start)
      Blank()
    }.width("100%").padding(16)
  }

  @Builder actionBar() {
    Row({ space: 24 }) {
      Row({ space: 4 }) { Text(this.liked ? "❤️" : "🤍").fontSize(20).scale({ x: this.likeAnimScale, y: this.likeAnimScale }).onClick(() => this.toggleLike()); Text(this.formatCount(this.post!.likeCount)).fontSize(13).fontColor(COLORS.textSecondary) }
      Row({ space: 4 }) { Text(this.collected ? "⭐" : "☆").fontSize(20).scale({ x: this.collectAnimScale, y: this.collectAnimScale }).onClick(() => this.toggleCollect()); Text(this.formatCount(this.post!.collectCount)).fontSize(13).fontColor(COLORS.textSecondary) }
      Row({ space: 4 }) { Text("💬").fontSize(18); Text(this.formatCount(this.post!.commentCount)).fontSize(13).fontColor(COLORS.textSecondary) }
      Text("↗").fontSize(18).onClick(() => { const pboard = pasteboard.getSystemPasteboard(); pboard.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post!.title + "\n\n" + this.post!.prompt)) })
    }.width("100%").justifyContent(FlexAlign.SpaceEvenly).padding({ top: 12, bottom: 12 })
  }

  @Builder commentSection() {
    Column() {
      Row() { Text("评论").fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(" (" + this.comments.length + ")").fontSize(13).fontColor(COLORS.textSecondary) }.width("100%").padding(16)
      if (this.comments.length === 0) { Text("暂无评论，来说两句吧").fontSize(13).fontColor(COLORS.textSecondary).width("100%").textAlign(TextAlign.Center).padding({ top: 40, bottom: 40 }) }
      else {
        List({ space: 0 }) {
          ForEach(this.comments, (comment: Comment) => {
            ListItem() {
              Column() {
                Row({ space: 10 }) {
                  Text((comment.author?.nickname ?? "用").charAt(0)).fontSize(15).fontColor("#FFF").width(34).height(34).borderRadius(17).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(comment.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
                  Column({ space: 4 }) {
                    Row({ space: 8 }) { Text(comment.author?.nickname ?? "用户").fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.formatTime(comment.createdAt)).fontSize(11).fontColor(COLORS.textSecondary) }
                    if (comment.replyTo) { Text("↳ 回复 @某用户").fontSize(11).fontColor(COLORS.textSecondary).margin({ bottom: 2 }) }
                    Text(comment.content).fontSize(14).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(20)
                    Row({ space: 12 }) { Text("回复").fontSize(11).fontColor(COLORS.primary).onClick(() => { this.replyTo = comment.id; this.replyNickname = comment.author?.nickname ?? "用户" }); Text(comment.liked ? "❤️" : "🤍").fontSize(13).onClick(() => this.toggleCommentLike(comment)) }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width("100%")
                ForEach(this.comments.filter((c: Comment) => c.replyTo === comment.id), (sub: Comment) => {
                  Row({ space: 10 }) {
                    Text((sub.author?.nickname ?? "用").charAt(0)).fontSize(13).fontColor("#FFF").width(28).height(28).borderRadius(14).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(sub.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
                    Column({ space: 2 }) { Row({ space: 8 }) { Text(sub.author?.nickname ?? "用户").fontSize(12).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.formatTime(sub.createdAt)).fontSize(10).fontColor(COLORS.textSecondary) }; Text(sub.content).fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(18) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  }.width("100%").padding({ left: 44, right: 16, top: 4, bottom: 8 })
                })
              }.width("100%").padding({ left: 16, right: 16, top: 10, bottom: 10 })
            }
          })
        }.layoutWeight(1)
      }
    }.width("100%")
  }

  async loadAll(): Promise<void> { this.loading = true; try { this.post = await getApi().getPostDetail(this.postId); this.liked = this.post.liked; this.collected = this.post.collected; this.loadSimilar() } catch (e) { /* ignore */ } finally { this.loading = false }; this.loadComments() }

  async loadComments(): Promise<void> { try { this.comments = await getApi().getComments(this.postId) } catch (e) { /* ignore */ } }

  async loadSimilar(): Promise<void> { try { if (this.post?.category) { this.similarPosts = await getApi().getPosts(this.post.category, "hot", 0) as Post[]; this.similarPosts = this.similarPosts.filter((p: Post) => p.id !== this.postId).slice(0, 3) } } catch (e) { /* ignore */ } }

  isOwnPost(): boolean { return UserManager.currentUser?.id === this.post?.userId }

  searchTag(tag: string): void { router.pushUrl({ url: "pages/SearchPage", params: { query: tag } }) }

  remixPost(): void { router.pushUrl({ url: "pages/CreatePage", params: { remixFrom: this.postId, remixTitle: "改编自: " + (this.post?.title ?? ""), remixPrompt: this.post?.prompt ?? "" } }) }

  async doDelete(): Promise<void> {
    try { await getApi().deletePost(this.postId); router.back() } catch (e) { /* ignore */ }
  }

  async toggleLike(): Promise<void> { if (!this.post) return; try { const r = await getApi().likePost(this.postId); this.liked = r.liked; this.post.likeCount = r.likeCount; this.likeAnimScale = 1.8; animateTo({ duration: 300 }, () => { this.likeAnimScale = 1 }) } catch (e) { /* ignore */ } }

  async toggleCollect(): Promise<void> { if (!this.post) return; try { const r = await getApi().collectPost(this.postId); this.collected = r.collected; this.post.collectCount = r.collectCount; this.collectAnimScale = 1.8; animateTo({ duration: 300 }, () => { this.collectAnimScale = 1 }) } catch (e) { /* ignore */ } }

  async toggleCommentLike(comment: Comment): Promise<void> { try { const r = await getApi().likeComment(comment.id); comment.liked = r.liked; comment.likeCount = r.likeCount } catch (e) { /* ignore */ } }

  async submitComment(): Promise<void> { const text = this.newComment.trim(); if (!text) return; try { const nc = await getApi().addComment(this.postId, text, this.replyTo || undefined); this.comments = [...this.comments, nc]; this.newComment = ""; if (this.post) this.post.commentCount++; this.replyTo = ""; this.replyNickname = "" } catch (e) { /* ignore */ } }

  formatCount(n: number): string { if (n >= 10000) return (n / 10000).toFixed(1) + "w"; if (n >= 1000) return (n / 1000).toFixed(1) + "k"; return n.toString() }
  formatTime(t: string): string { if (!t) return ""; const d = new Date(t); const diff = Date.now() - d.getTime(); if (diff < 60000) return "刚刚"; if (diff < 3600000) return Math.floor(diff / 60000) + "分钟前"; if (diff < 86400000) return Math.floor(diff / 3600000) + "小时前"; if (diff < 604800000) return Math.floor(diff / 86400000) + "天前"; return `${d.getMonth() + 1}-${d.getDate()}` }
  getLevelTitle(level: number): string { const l: LevelItem | undefined = LEVELS.find((li: LevelItem) => li.level === level); return l ? l.title : "" }
}
