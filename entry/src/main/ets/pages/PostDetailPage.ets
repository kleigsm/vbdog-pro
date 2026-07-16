import { getApi } from "../common/ApiProvider"
import { Post, Comment, LevelItem, LEVELS } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"
import { router } from "@kit.ArkUI"
import { pasteboard } from "@kit.BasicServicesKit"

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
    if (this.loading) {
      Column() { LoadingProgress().width(40).height(40) }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    } else if (!this.post) {
      Column({ space: 12 }) { Text("\u{1F615}").fontSize(48); Text("\u5e16\u5b50\u4e0d\u5b58\u5728").fontSize(15).fontColor(COLORS.textSecondary) }.width("100%").height("100%").justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)
    } else {
      Column() {
        Row() {
          Text("\u2190 \u8fd4\u56de").fontSize(15).fontColor(COLORS.primary).onClick(() => router.back())
          Blank()
          if (this.isOwnPost()) {
            Text("\u7f16\u8f91").fontSize(13).fontColor(COLORS.primary).margin({ right: 14 }).onClick(() => this.editPost())
            Text("\u5220\u9664").fontSize(13).fontColor(COLORS.error).onClick(() => this.showDelete = true)
          }
        }.width("100%").padding(14)

        Scroll() {
          Column() {
            this.authorSection()
            Text(this.post!.title).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.isDark ? COLORS.textDark : COLORS.text).width("100%").padding({ left: 16, right: 16, top: 4, bottom: 10 })
            if (this.post!.tags && this.post!.tags.length > 0) {
              Row({ space: 6 }) {
                ForEach(this.post!.tags, (tag: string) => {
                  Text("#" + tag).fontSize(12).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "10").borderRadius(6).padding({ left: 10, right: 10, top: 4, bottom: 4 }).onClick(() => this.searchTag(tag))
                })
              }.width("100%").padding({ left: 16, right: 16, bottom: 10 })
            }
            Text(this.post!.content).fontSize(15).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(25).width("100%").padding({ left: 16, right: 16, bottom: 14 })
            if (this.post!.category || this.post!.model) {
              Row({ space: 8 }) {
                if (this.post!.category) { Text(this.post!.category).fontSize(12).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "10").borderRadius(6).padding({ left: 10, right: 10, top: 4, bottom: 4 }) }
                if (this.post!.model) { Text(this.post!.model).fontSize(12).fontColor(COLORS.textSecondary).backgroundColor(this.isDark ? "#2A2A40" : "#F0F0F5").borderRadius(6).padding({ left: 10, right: 10, top: 4, bottom: 4 }) }
              }.padding({ left: 16, bottom: 14 })
            }
            if (this.post!.prompt) {
              Column() {
                Row() {
                  Row({ space: 4 }) { Text("\u2726").fontSize(12).fontColor("#FFB800"); Text("Prompt").fontSize(11).fontColor("#FFB800") }.backgroundColor("#FFB80018").borderRadius(4).padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  Blank()
                  Text("\u590d\u5236").fontSize(11).fontColor(COLORS.primary).onClick(() => { const pb = pasteboard.getSystemPasteboard(); pb.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post!.prompt)) })
                  Text("  \u6539\u7f16").fontSize(11).fontColor(COLORS.primary).onClick(() => this.remixPost())
                }.width("100%").margin({ bottom: 10 })
                Text(this.post!.prompt).fontSize(13).fontColor("#E0E0E6").fontFamily("monospace").lineHeight(20).width("100%")
              }.width("100%").padding(14).margin({ left: 16, right: 16, bottom: 16 }).backgroundColor(this.isDark ? "#0D0D1A" : "#1D1D1F").borderRadius(14).border({ width: 1, color: this.isDark ? "#2A2A40" : "#333" })
            }
            Row({ space: 0 }) {
              Row({ space: 4 }) { Text(this.liked ? "\u2764\ufe0f" : "\u{1F90D}").fontSize(22).scale({ x: this.likeAnimScale, y: this.likeAnimScale }).onClick(() => this.toggleLike()); Text(this.formatCount(this.post!.likeCount)).fontSize(13).fontColor(COLORS.textSecondary) }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Row({ space: 4 }) { Text(this.collected ? "\u2b50" : "\u2606").fontSize(22).scale({ x: this.collectAnimScale, y: this.collectAnimScale }).onClick(() => this.toggleCollect()); Text(this.formatCount(this.post!.collectCount)).fontSize(13).fontColor(COLORS.textSecondary) }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Row({ space: 4 }) { Text("\u{1F4AC}").fontSize(18); Text(this.formatCount(this.post!.commentCount)).fontSize(13).fontColor(COLORS.textSecondary) }.layoutWeight(1).justifyContent(FlexAlign.Center)
              Text("\u2197").fontSize(20).layoutWeight(1).textAlign(TextAlign.Center).onClick(() => { const pb = pasteboard.getSystemPasteboard(); pb.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.post!.title + "\n\n" + this.post!.prompt)) })
            }.width("100%").padding({ top: 14, bottom: 14 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card)
            Divider().strokeWidth(8).color(this.isDark ? "#1A1A30" : "#F0F0F5")
            if (this.similarPosts.length > 0) {
              Column() {
                Text("\u63a8\u8350\u5e16\u5b50").fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text).width("100%").padding({ left: 16, right: 16, top: 14, bottom: 8 })
                List({ space: 0 }) { ForEach(this.similarPosts, (sp: Post) => { ListItem() { Row({ space: 10 }) { Text(sp.title).fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text).maxLines(1).layoutWeight(1); Text("\u2764\ufe0f " + this.formatCount(sp.likeCount)).fontSize(11).fontColor(COLORS.textSecondary); Text("\u203a").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").padding(14).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).onClick(() => router.pushUrl({ url: "pages/PostDetailPage", params: { postId: sp.id } })) } }) }.height(160)
              }.width("100%")
              Divider().strokeWidth(8).color(this.isDark ? "#1A1A30" : "#F0F0F5")
            }
            this.commentSection()
          }.width("100%")
        }.layoutWeight(1)

        if (this.replyTo) { Row() { Text("\u56de\u590d " + this.replyNickname).fontSize(12).fontColor(COLORS.primary); Blank(); Text("\u2715").fontSize(14).fontColor(COLORS.textSecondary).onClick(() => { this.replyTo = ""; this.replyNickname = "" }) }.width("100%").padding({ left: 14, right: 14, top: 8, bottom: 8 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).border({ width: { top: 1 }, color: this.isDark ? "#2A2A40" : "#E5E5EA" }) }
        Row({ space: 10 }) {
          TextInput({ placeholder: "\u8bf4\u70b9\u4ec0\u4e48...", text: this.newComment }).layoutWeight(1).height(42).fontSize(14).backgroundColor(this.isDark ? "#2A2A40" : "#F0F0F5").borderRadius(21).padding({ left: 18, right: 18 }).onChange((v: string) => { this.newComment = v })
          Button("\u53d1\u9001").fontSize(13).height(38).backgroundColor(this.newComment.trim() ? COLORS.primary : "#CCC").borderRadius(19).fontColor("#FFF").padding({ left: 16, right: 16 }).onClick(() => this.submitComment())
        }.width("100%").padding({ left: 12, right: 12, top: 8, bottom: 8 }).backgroundColor(this.isDark ? COLORS.cardDark : COLORS.card).shadow({ radius: 4, color: COLORS.shadowNav, offsetY: -2 })
      }.width("100%").height("100%").backgroundColor(this.isDark ? COLORS.backgroundDark : COLORS.background)

      if (this.showDelete) {
        Column() {
          Column({ space: 14 }) {
            Text("\u786e\u8ba4\u5220\u9664").fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text); Text("\u5220\u9664\u540e\u65e0\u6cd5\u6062\u590d\uff0c\u786e\u5b9a\u8981\u5220\u9664\u8fd9\u4e2a\u5e16\u5b50\u5417\uff1f").fontSize(14).fontColor(COLORS.textSecondary).textAlign(TextAlign.Center)
            Row({ space: 12 }) { Button("\u53d6\u6d88").width("45%").height(42).backgroundColor("#F0F0F5").fontColor(COLORS.text).borderRadius(10).onClick(() => this.showDelete = false); Button("\u786e\u8ba4\u5220\u9664").width("45%").height(42).backgroundColor(COLORS.error).fontColor("#FFF").borderRadius(10).onClick(() => this.doDelete()) }.width("100%").justifyContent(FlexAlign.Center)
          }.width("80%").padding(24).backgroundColor(COLORS.card).borderRadius(16)
        }.width("100%").height("100%").backgroundColor(COLORS.shadowModal).justifyContent(FlexAlign.Center).onClick(() => this.showDelete = false)
      }
    }
  }

  @Builder authorSection() {
    Row({ space: 10 }) {
      Text(this.post!.author?.nickname?.charAt(0) ?? "\u7528").fontSize(22).fontColor("#FFF").width(48).height(48).borderRadius(24).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(this.post!.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
      Column({ space: 3 }) {
        Row({ space: 6 }) { Text(this.post!.author?.nickname ?? "\u7528\u6237").fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.getLevelBadge(this.post!.author?.level ?? 1)).fontSize(10).fontColor(COLORS.primary).backgroundColor(COLORS.primary + "14").borderRadius(4).padding({ left: 6, right: 6, top: 2, bottom: 2 }) }
        Text(this.formatTime(this.post!.createdAt)).fontSize(12).fontColor(COLORS.textSecondary)
      }.alignItems(HorizontalAlign.Start)
    }.width("100%").padding(16)
  }

  @Builder commentSection() {
    Column() {
      Row() { Text("\u8bc4\u8bba").fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(" " + this.comments.length.toString()).fontSize(13).fontColor(COLORS.textSecondary) }.width("100%").padding(16)
      if (this.comments.length === 0) { Text("\u6682\u65e0\u8bc4\u8bba\uff0c\u6765\u8bf4\u4e24\u53e5\u5427").fontSize(13).fontColor(COLORS.textSecondary).width("100%").textAlign(TextAlign.Center).padding({ top: 40, bottom: 40 }) }
      else {
        List({ space: 0 }) {
          ForEach(this.comments, (comment: Comment) => {
            ListItem() {
              Column() {
                Row({ space: 10 }) {
                  Text((comment.author?.nickname ?? "\u7528").charAt(0)).fontSize(15).fontColor("#FFF").width(36).height(36).borderRadius(18).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(comment.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
                  Column({ space: 3 }) {
                    Row({ space: 8 }) { Text(comment.author?.nickname ?? "\u7528\u6237").fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.formatTime(comment.createdAt)).fontSize(11).fontColor(COLORS.textSecondary) }
                    if (comment.replyTo) { Text("\u21b3 \u56de\u590d").fontSize(11).fontColor(COLORS.textSecondary).margin({ bottom: 2 }) }
                    Text(comment.content).fontSize(14).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(20)
                    Row({ space: 14 }) { Text("\u56de\u590d").fontSize(11).fontColor(COLORS.primary).onClick(() => { this.replyTo = comment.id; this.replyNickname = comment.author?.nickname ?? "\u7528\u6237" }); Text(comment.liked ? "\u2764\ufe0f" : "\u{1F90D}").fontSize(13).onClick(() => this.toggleCommentLike(comment)) }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width("100%")
                ForEach(this.comments.filter((c: Comment) => c.replyTo === comment.id), (sub: Comment) => {
                  Row({ space: 10 }) {
                    Text((sub.author?.nickname ?? "\u7528").charAt(0)).fontSize(13).fontColor("#FFF").width(28).height(28).borderRadius(14).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[(sub.author?.nickname?.length ?? 0) % AVATAR_COLORS.length])
                    Column({ space: 2 }) { Row({ space: 8 }) { Text(sub.author?.nickname ?? "\u7528\u6237").fontSize(12).fontColor(this.isDark ? COLORS.textDark : COLORS.text); Text(this.formatTime(sub.createdAt)).fontSize(10).fontColor(COLORS.textSecondary) }; Text(sub.content).fontSize(13).fontColor(this.isDark ? COLORS.textDark : COLORS.text).lineHeight(18) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  }.width("100%").padding({ left: 44, right: 16, top: 4, bottom: 8 })
                })
              }.width("100%").padding({ left: 16, right: 16, top: 10, bottom: 10 })
            }
          })
        }.layoutWeight(1)
      }
    }.width("100%")
  }

  async loadAll(): Promise<void> { this.loading = true; try { this.post = await getApi().getPostDetail(this.postId); this.liked = this.post.liked; this.collected = this.post.collected; this.loadSimilar() } catch (e) { } finally { this.loading = false }; this.loadComments() }
  async loadComments(): Promise<void> { try { this.comments = await getApi().getComments(this.postId) } catch (e) { } }
  async loadSimilar(): Promise<void> { try { if (this.post?.category) { this.similarPosts = await getApi().getPosts(this.post.category, "hot", 0) as Post[]; this.similarPosts = this.similarPosts.filter((p: Post) => p.id !== this.postId).slice(0, 3) } } catch (e) { } }
  isOwnPost(): boolean { return UserManager.currentUser?.id === this.post?.userId }
  editPost(): void { router.pushUrl({ url: "pages/CreatePage", params: { editPostId: this.postId, editTitle: this.post?.title, editContent: this.post?.content, editPrompt: this.post?.prompt, editCategory: this.post?.category, editModel: this.post?.model } }) }
  searchTag(tag: string): void { router.pushUrl({ url: "pages/SearchPage", params: { query: tag } }) }
  remixPost(): void { router.pushUrl({ url: "pages/CreatePage", params: { remixFrom: this.postId, remixTitle: "\u6539\u7f16\u81ea: " + (this.post?.title ?? ""), remixPrompt: this.post?.prompt ?? "" } }) }
  async doDelete(): Promise<void> { try { await getApi().deletePost(this.postId); router.back() } catch (e) { } }
  async toggleLike(): Promise<void> { if (!this.post) return; try { const r = await getApi().likePost(this.postId); this.liked = r.liked; this.post.likeCount = r.likeCount; this.likeAnimScale = 1.8; animateTo({ duration: 300 }, () => { this.likeAnimScale = 1 }) } catch (e) { } }
  async toggleCollect(): Promise<void> { if (!this.post) return; try { const r = await getApi().collectPost(this.postId); this.collected = r.collected; this.post.collectCount = r.collectCount; this.collectAnimScale = 1.8; animateTo({ duration: 300 }, () => { this.collectAnimScale = 1 }) } catch (e) { } }
  async toggleCommentLike(comment: Comment): Promise<void> { try { const r = await getApi().likeComment(comment.id); comment.liked = r.liked; comment.likeCount = r.likeCount } catch (e) { } }
  async submitComment(): Promise<void> { const text = this.newComment.trim(); if (!text) return; try { const nc = await getApi().addComment(this.postId, text, this.replyTo || undefined); this.comments = [...this.comments, nc]; this.newComment = ""; if (this.post) this.post.commentCount++; this.replyTo = ""; this.replyNickname = "" } catch (e) { } }
  formatCount(n: number): string { if (n >= 10000) return (n / 10000).toFixed(1) + "w"; if (n >= 1000) return (n / 1000).toFixed(1) + "k"; return n.toString() }
  formatTime(t: string): string { if (!t) return ""; const d = new Date(t); const diff = Date.now() - d.getTime(); if (diff < 60000) return "\u521a\u521a"; if (diff < 3600000) return Math.floor(diff / 60000) + "\u5206\u949f\u524d"; if (diff < 86400000) return Math.floor(diff / 3600000) + "\u5c0f\u65f6\u524d"; if (diff < 604800000) return Math.floor(diff / 86400000) + "\u5929\u524d"; return (d.getMonth() + 1) + "-" + d.getDate() }
  getLevelBadge(level: number): string { const l: LevelItem | undefined = LEVELS.find((li: LevelItem) => li.level === level); return l ? l.title.replace(/[^\u4e00-\u9fa5]/g, "") : "" }
}