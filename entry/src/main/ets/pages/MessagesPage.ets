import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_MD, R_LG, F_CAPT, F_SM, F_BODY, F_LG } from "../common/Constants"
import { getApi } from "../common/ApiProvider"
import { Conversation, Message } from "../common/Models"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"

@Entry
@Component
export struct MessagesPage {
  @State conversations: Conversation[] = []
  @State messages: Message[] = []
  @State newMsg: string = ""
  @State loading: boolean = true
  @State activeChat: string = ""
  @State activeName: string = ""
  private scroller: Scroller = new Scroller()
  private myId: string = UserManager.currentUser?.id ?? ""

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>
    if (params && params["chatWith"]) {
      this.activeChat = params["chatWith"] as string
      this.activeName = params["chatName"] as string || ""
      this.loadMessages()
    }
    this.loadConversations()
  }

  build() {
    if (this.activeChat) {
      this.chatView()
    } else {
      this.conversationList()
    }
  }

  @Builder conversationList() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(C_TEXT1)
          .onClick(() => { router.back() })
        Text("私信").fontSize(F_LG).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      if (this.loading) {
        LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 80 })
      } else if (this.conversations.length === 0) {
        Column() {
          Text("💬").fontSize(48).margin({ bottom: S_MD })
          Text("暂无私信").fontSize(F_BODY).fontColor(C_TEXT2)
          Text("去关注一些创作者，开始交流吧").fontSize(F_CAPT).fontColor(C_TEXT3).margin({ top: S_XS })
        }.layoutWeight(1).width("100%").justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.conversations, (conv: Conversation) => {
            ListItem() {
              Row() {
                Text(conv.nickname.charAt(0)).fontSize(20).fontColor("#FFF")
                  .width(44).height(44).borderRadius(22).textAlign(TextAlign.Center)
                  .backgroundColor(this.getAvatarColor(conv.nickname))
                Column() {
                  Row() {
                    Text(conv.nickname).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Medium)
                    Blank()
                    Text(this.formatChatTime(conv.lastTime)).fontSize(F_CAPT).fontColor(C_TEXT3)
                  }.width("100%")
                  Text(conv.lastMessage).fontSize(F_SM).fontColor(C_TEXT3).maxLines(1)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: S_MD })
                if (conv.unreadCount > 0) {
                  Text(conv.unreadCount.toString()).fontSize(11).fontColor("#FFF")
                    .backgroundColor(C_PRIMARY).borderRadius(9).width(18).height(18).textAlign(TextAlign.Center)
                }
              }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
              .onClick(() => { this.activeChat = conv.userId; this.activeName = conv.nickname; this.loadMessages() })
            }
          }, (conv: Conversation) => conv.userId)
        }.layoutWeight(1).width("100%")
      }
    }.width("100%").height("100%").backgroundColor(C_BG)
  }

  @Builder chatView() {
    Column() {
      Row() {
        Image($r("sys.symbol.chevron_left")).width(24).height(24).fillColor(C_TEXT1)
          .onClick(() => { this.activeChat = ""; this.loadConversations() })
        Text(this.activeName).fontSize(F_LG).fontColor(C_TEXT1).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Text("").width(24)
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: Message, i: number) => {
          ListItem() {
            Column() {
              if (i === 0 || this.shouldShowDate(msg, this.messages[i - 1])) {
                Text(this.formatDate(msg.createdAt)).fontSize(F_CAPT).fontColor(C_TEXT3)
                  .width("100%").textAlign(TextAlign.Center).padding({ top: S_SM, bottom: S_XS })
              }
              Row() {
                if (msg.fromUserId !== this.myId) Blank()
                Column() {
                  Text(msg.text).fontSize(F_BODY)
                    .fontColor(msg.fromUserId === this.myId ? "#FFFFFF" : C_TEXT1)
                    .padding({ left: S_MD, right: S_MD, top: S_SM, bottom: S_SM }).borderRadius(16)
                    .backgroundColor(msg.fromUserId === this.myId ? C_PRIMARY : C_CARD)
                    .constraintSize({ maxWidth: "75%" })
                  Text(this.formatMsgTime(msg.createdAt)).fontSize(10).fontColor(C_TEXT3)
                    .alignSelf(msg.fromUserId === this.myId ? ItemAlign.End : ItemAlign.Start)
                    .margin({ top: 2 })
                  if (msg.fromUserId === this.myId && i === this.messages.length - 1) {
                    Text("已发送").fontSize(10).fontColor(C_TEXT3)
                      .alignSelf(ItemAlign.End).margin({ top: 1 })
                  }
                }.alignItems(msg.fromUserId === this.myId ? HorizontalAlign.End : HorizontalAlign.Start)
                .margin({ left: S_MD, right: S_MD, bottom: S_SM })
                if (msg.fromUserId !== this.myId) Blank()
              }.width("100%")
            }.width("100%")
          }
        }, (_msg: Message, i: number) => i.toString())
      }.layoutWeight(1).width("100%").padding({ top: S_MD })

      Row() {
        TextInput({ placeholder: "输入消息...", text: this.newMsg })
          .fontColor(C_TEXT1).fontSize(F_BODY).backgroundColor(C_CARD).borderRadius(20)
          .borderWidth(1).borderColor(C_BORDER).layoutWeight(1).height(40).padding({ left: S_LG })
          .onChange((v: string) => { this.newMsg = v }).onSubmit(() => this.sendMsg())
        Text("发送").fontSize(F_BODY).fontColor(this.newMsg.trim() ? C_PRIMARY : C_TEXT3)
          .margin({ left: S_MD }).fontWeight(FontWeight.Bold).onClick(() => this.sendMsg())
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM, bottom: S_SM }).backgroundColor(C_CARD)
    }.width("100%").height("100%").backgroundColor(C_BG)
  }

  async loadConversations(): Promise<void> {
    this.loading = true
    try { this.conversations = await getApi().getConversations() ?? [] } catch (_e) { }
    finally { this.loading = false }
  }

  async loadMessages(): Promise<void> {
    try {
      this.messages = await getApi().getMessages(this.activeChat) ?? []
      setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 100)
    } catch (_e) { }
  }

  async sendMsg(): Promise<void> {
    const text = this.newMsg.trim(); if (!text) return
    try {
      const msg = await getApi().sendMessage(this.activeChat, text)
      this.messages = [...this.messages, msg]; this.newMsg = ""
      setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom) }, 100)
    } catch (_e) { }
  }

  shouldShowDate(current: Message, previous: Message): boolean {
    if (!current.createdAt || !previous.createdAt) return false
    const cd = new Date(current.createdAt)
    const pd = new Date(previous.createdAt)
    return cd.toDateString() !== pd.toDateString()
  }

  formatDate(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const now = new Date()
    const diff = now.getTime() - d.getTime()
    if (diff < 86400000 && d.getDate() === now.getDate()) return "今天"
    const yesterday = new Date(now); yesterday.setDate(yesterday.getDate() - 1)
    if (d.toDateString() === yesterday.toDateString()) return "昨天"
    return (d.getFullYear()) + "年" + (d.getMonth() + 1) + "月" + d.getDate() + "日"
  }

  formatMsgTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const h = d.getHours().toString().padStart(2, "0")
    const m = d.getMinutes().toString().padStart(2, "0")
    return h + ":" + m
  }

  formatChatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const now = new Date()
    const diff = now.getTime() - d.getTime()
    if (diff < 86400000) return d.getHours() + ":" + d.getMinutes().toString().padStart(2, "0")
    if (diff < 172800000) return "昨天"
    return (d.getMonth() + 1) + "-" + d.getDate()
  }

  getAvatarColor(nickname: string): string {
    const colors: string[] = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
    let hash = 0
    for (let i = 0; i < nickname.length; i++) { hash = nickname.charCodeAt(i) + ((hash << 5) - hash) }
    return colors[Math.abs(hash) % colors.length]
  }
}
