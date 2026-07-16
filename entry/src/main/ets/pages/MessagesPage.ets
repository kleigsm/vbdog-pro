import { getApi } from "../common/ApiProvider"
import { Conversation, Message } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { UserManager } from "../common/UserManager"

@Entry
@Component
export struct MessagesPage {
  @State conversations: Conversation[] = []
  @State messages: Message[] = []
  @State newMsg: string = ""
  @State loading: boolean = true
  @State activeChat: string = ""
  @State activeName: string = ""

  aboutToAppear(): void { this.loadConversations() }

  build() { if (this.activeChat) { this.chatView() } else { this.conversationList() } }

  @Builder conversationList() {
    Column() {
      Text("私信").fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text).width("100%").padding(16)
      if (this.loading) { LoadingProgress().width(32).height(32).margin({ top: 80 }) }
      else if (this.conversations.length === 0) { Column({ space: 12 }) { Text("💬").fontSize(48); Text("暂无私信").fontSize(14).fontColor(COLORS.textSecondary) }.width("100%").margin({ top: 80 }) }
      else {
        List({ space: 0 }) { ForEach(this.conversations, (conv: Conversation) => { ListItem() { Row({ space: 12 }) { Text(conv.nickname.charAt(0)).fontSize(18).fontColor("#FFF").width(48).height(48).borderRadius(24).textAlign(TextAlign.Center).backgroundColor(AVATAR_COLORS[conv.nickname.length % AVATAR_COLORS.length]); Column({ space: 4 }) { Row() { Text(conv.nickname).fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank(); Text(this.formatChatTime(conv.lastTime)).fontSize(11).fontColor(COLORS.textSecondary) }.width("100%"); Text(conv.lastMessage).fontSize(13).fontColor(COLORS.textSecondary).maxLines(1) }.alignItems(HorizontalAlign.Start).layoutWeight(1); if (conv.unreadCount > 0) { Text(conv.unreadCount.toString()).fontSize(11).fontColor("#FFF").backgroundColor(COLORS.primary).borderRadius(9).width(18).height(18).textAlign(TextAlign.Center) } }.width("100%").padding(14).onClick(() => { this.activeChat = conv.userId; this.activeName = conv.nickname; this.loadMessages() }) } }) }.layoutWeight(1)
      }
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  @Builder chatView() {
    Column() {
      Row({ space: 12 }) { Text("\u2190").fontSize(22).fontColor(COLORS.primary).onClick(() => { this.activeChat = "" }); Text(this.activeName).fontSize(17).fontWeight(FontWeight.Medium).fontColor(COLORS.text); Blank() }.width("100%").padding(14)
      Divider().strokeWidth(0.5).color("#E5E5EA")
      List({ space: 10 }) { ForEach(this.messages, (msg: Message) => { ListItem() { Row() { if (msg.fromUserId !== (UserManager.currentUser?.id ?? "")) { Blank() }; Column({ space: 2 }) { Text(msg.text).fontSize(14).fontColor(msg.fromUserId === (UserManager.currentUser?.id ?? "") ? "#FFF" : COLORS.text).backgroundColor(msg.fromUserId === (UserManager.currentUser?.id ?? "") ? COLORS.primary : "#F0F0F5").borderRadius(16).padding({ left: 14, right: 14, top: 10, bottom: 10 }).constraintSize({ maxWidth: "75%" }); if (msg.fromUserId !== (UserManager.currentUser?.id ?? "")) { Text(this.formatChatTime(msg.createdAt)).fontSize(10).fontColor(COLORS.textSecondary).padding({ left: 4 }) } else { Text(this.formatChatTime(msg.createdAt)).fontSize(10).fontColor(COLORS.textSecondary).alignSelf(ItemAlign.End).padding({ right: 4 }) } }; if (msg.fromUserId === (UserManager.currentUser?.id ?? "")) { Blank() } }.width("100%") } }) }.layoutWeight(1).padding(12)
      Row({ space: 10 }) { TextInput({ placeholder: "输入消息...", text: this.newMsg }).layoutWeight(1).height(42).fontSize(14).backgroundColor("#F0F0F5").borderRadius(21).padding({ left: 18, right: 18 }).onChange((v: string) => { this.newMsg = v }); Button("发送").fontSize(13).height(38).backgroundColor(this.newMsg.trim() ? COLORS.primary : "#CCC").borderRadius(19).fontColor("#FFF").padding({ left: 16, right: 16 }).onClick(() => this.sendMsg()) }.width("100%").padding(10).backgroundColor(COLORS.card)
    }.width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async loadConversations() { this.loading = true; try { this.conversations = await getApi().getConversations() ?? [] } catch { this.conversations = [] } finally { this.loading = false } }
  async loadMessages() { try { this.messages = await getApi().getMessages(this.activeChat) } catch { this.messages = [] } }
  async sendMsg() { const text = this.newMsg.trim(); if (!text) return; try { const msg = await getApi().sendMessage(this.activeChat, text); this.messages = [...this.messages, msg]; this.newMsg = "" } catch { /* ignore */ } }
  formatChatTime(t: string): string { if (!t) return ""; const d = new Date(t); const now = new Date(); const diff = now.getTime() - d.getTime(); if (diff < 86400000) return d.getHours() + ":" + d.getMinutes().toString().padStart(2, "0"); return (d.getMonth() + 1) + "-" + d.getDate() }
}