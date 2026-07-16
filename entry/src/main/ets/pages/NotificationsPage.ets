import { C_BG, C_CARD, C_TEXT1, C_TEXT2, C_TEXT3, C_PRIMARY, C_RED, C_BORDER, S_XS, S_SM, S_MD, S_LG, S_XL, R_LG, F_CAPT, F_SM, F_BODY, F_H3 } from "../common/Constants"
import { VNotification } from "../common/Models"
import { getApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"
import router from "@ohos.router"

interface ConvItem {
  userId: string; displayName: string; avatar: string; lastMsg: string; time: string; unread: number;
}

@Entry
@Component
export struct NotificationsPage {
  @State tab: number = 0
  @State notifications: VNotification[] = []
  @State conversations: ConvItem[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadAll() }

  getUnread(): number {
    let count = 0
    for (let i = 0; i < this.notifications.length; i++) {
      if (!this.notifications[i].read) count++
    }
    return count
  }

  markAllRead(): void {
    for (let i = 0; i < this.notifications.length; i++) {
      this.notifications[i].read = true
    }
    this.notifications = [...this.notifications]
  }

  getIcon(type: string): string {
    const m: Record<string, string> = { "like": "❤️", "collect": "⭐", "comment": "💬", "follow": "👢", "reply": "↩️" }
    return m[type] ?? "🔔"
  }

  formatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const now = new Date()
    const diff = now.getTime() - d.getTime()
    if (diff < 60000) return "刚刚"
    if (diff < 3600000) return Math.floor(diff / 60000) + "分钟前"
    if (diff < 86400000) return Math.floor(diff / 3600000) + "小时前"
    return (d.getMonth() + 1) + "-" + d.getDate()
  }

  async loadAll(): Promise<void> {
    this.loading = true
    try {
      this.notifications = await getApi().getNotifications()
    } catch (_e) { this.notifications = [] }
    this.loading = false
  }

  async onNotificationTap(n: VNotification): Promise<void> {
    if (!n.read) {
      try { await getApi().markNotificationRead(n.id); n.read = true } catch (_e) { }
    }
    if (n.relatedId && (n.type === "like" || n.type === "comment" || n.type === "collect" || n.type === "reply")) {
      router.pushUrl({ url: "pages/PostDetailPage", params: { postId: n.relatedId } })
    } else if (n.type === "follow" && n.fromUser) {
      router.pushUrl({ url: "pages/UserPage", params: { userId: n.fromUser.id } })
    } else if (n.type === "message" && n.fromUser) {
      router.pushUrl({ url: "pages/MessagesPage", params: { chatWith: n.fromUser.id, chatName: n.fromUser.nickname } })
    }
  }

  build() {
    Column() {
      Row() {
        Text("动态").fontSize(F_H3).fontColor(C_TEXT1).fontWeight(FontWeight.Bold).layoutWeight(1)
        if (this.tab === 0 && this.getUnread() > 0) {
          Text("全部已读").fontSize(F_SM).fontColor(C_PRIMARY).onClick(() => this.markAllRead())
        }
      }.width("100%").padding({ left: S_LG, right: S_LG, top: S_SM + 2, bottom: S_SM }).backgroundColor(C_CARD)

      Row() {
        ForEach(["通知", "私信"], (t: string, i: number) => {
          Text(t).fontSize(F_BODY).fontColor(this.tab === i ? C_PRIMARY : C_TEXT2)
            .fontWeight(this.tab === i ? FontWeight.Bold : FontWeight.Normal)
            .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: S_MD, bottom: S_MD })
            .borderWidth({ bottom: this.tab === i ? 2 : 0 }).borderColor(this.tab === i ? C_PRIMARY : Color.Transparent)
            .onClick(() => { this.tab = i })
        }, (_t: string, i: number) => i.toString())
      }.width("100%").backgroundColor(C_CARD)

      if (this.tab === 0) {
        if (this.loading) {
          LoadingProgress().width(32).height(32).color(C_PRIMARY).margin({ top: 80 })
        } else if (this.notifications.length === 0) {
          Column() {
            Text("🔔").fontSize(40).margin({ bottom: S_MD })
            Text("暂无通知").fontSize(F_BODY).fontColor(C_TEXT2)
          }.layoutWeight(1).width("100%").justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.notifications, (n: VNotification) => {
              ListItem() {
                Row() {
                  Stack() {
                    Text(this.getIcon(n.type)).fontSize(24)
                    if (!n.read) { Circle({ width: 8, height: 8 }).fill(C_RED).position({ x: 20, y: 0 }) }
                  }.margin({ right: S_MD })
                  Column() {
                    Row() {
                      Text((n.fromUser?.nickname ?? "用户")).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Medium)
                      Text(" " + n.content).fontSize(F_BODY).fontColor(C_TEXT2)
                    }
                    Text(this.formatTime(n.createdAt)).fontSize(F_CAPT).fontColor(C_TEXT3).margin({ top: 2 })
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .backgroundColor(n.read ? C_BG : C_CARD)
                .onClick(() => this.onNotificationTap(n))
              }
            }, (n: VNotification) => n.id)
          }.layoutWeight(1).width("100%")
        }
      } else {
        if (this.conversations.length === 0) {
          Column() {
            Text("💬").fontSize(40).margin({ bottom: S_MD })
            Text("暂无消息").fontSize(F_BODY).fontColor(C_TEXT2)
          }.layoutWeight(1).width("100%").justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.conversations, (c: ConvItem) => {
              ListItem() {
                Row() {
                  Text(c.avatar || "👤").fontSize(32).margin({ right: S_MD })
                  Column() {
                    Text(c.displayName).fontSize(F_BODY).fontColor(C_TEXT1).fontWeight(FontWeight.Medium)
                    Text(c.lastMsg || "").fontSize(F_SM).fontColor(C_TEXT3).maxLines(1)
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  if (c.unread > 0) {
                    Text(c.unread.toString()).fontSize(F_CAPT).fontColor("#FFFFFF").backgroundColor("#FF4757")
                      .borderRadius(8).padding({ left: 6, right: 6, top: 1, bottom: 1 })
                  }
                }.width("100%").padding({ left: S_LG, right: S_LG, top: S_MD, bottom: S_MD })
                .onClick(() => { router.pushUrl({ url: "pages/MessagesPage" }) })
              }
            }, (c: ConvItem) => c.userId)
          }.layoutWeight(1).width("100%")
        }
      }
    }.width("100%").height("100%").backgroundColor(C_BG)
  }
}
