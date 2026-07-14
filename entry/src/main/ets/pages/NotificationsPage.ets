/**
 * NotificationsPage — 通知中心
 */

import { getApi } from "../common/ApiProvider"
import { VNotification } from "../common/Models"
import { COLORS, AVATAR_COLORS } from "../common/Constants"
import { router } from "@kit.ArkUI"

@Entry
@Component
struct NotificationsPage {
  @State notifications: VNotification[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadNotifications() }

  build() {
    Column() {
      Row() {
        Text("通知").fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.text)
        Blank()
        if (this.notifications.some(n => !n.read)) {
          Text("全部已读").fontSize(13).fontColor(COLORS.primary)
            .onClick(() => this.markAllRead())
        }
      }
      .width("100%").padding(16)

      if (this.loading) {
        LoadingProgress().width(32).height(32).margin({ top: 80 })
      } else if (this.notifications.length === 0) {
        Column({ space: 12 }) {
          Text("🔔").fontSize(48)
          Text("暂无通知").fontSize(14).fontColor(COLORS.textSecondary)
        }.width("100%").margin({ top: 80 })
      } else {
        List({ space: 0 }) {
          ForEach(this.notifications, (n: VNotification) => {
            ListItem() {
              Row({ space: 10 }) {
                // 头像
                Text((n.fromUser?.nickname ?? "用").charAt(0))
                  .fontSize(16).fontColor("#FFF")
                  .width(40).height(40).borderRadius(20)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(AVATAR_COLORS[(n.fromUser?.nickname?.length ?? 0) % AVATAR_COLORS.length])
                  .opacity(n.read ? 0.5 : 1)

                Column({ space: 3 }) {
                  Row({ space: 6 }) {
                    Text(this.getTypeIcon(n.type)).fontSize(14)
                    Text(n.fromUser?.nickname ?? "").fontSize(14).fontWeight(FontWeight.Medium).fontColor(COLORS.text)
                    Text(this.getTypeLabel(n.type)).fontSize(11).fontColor(COLORS.textSecondary)
                  }
                  Text(n.content).fontSize(13).fontColor(COLORS.textSecondary).maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(this.formatTime(n.createdAt)).fontSize(11).fontColor(COLORS.textSecondary)
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)

                if (!n.read) {
                  Circle({ width: 8, height: 8 }).fill(COLORS.primary)
                }
              }
              .width("100%").padding(14)
              .backgroundColor(n.read ? COLORS.card : (COLORS.primary + "08"))
              .onClick(() => this.onNotificationTap(n))
            }
          })
        }.layoutWeight(1)
      }
    }
    .width("100%").height("100%").backgroundColor(COLORS.background)
  }

  async loadNotifications() {
    this.loading = true
    try {
      this.notifications = await getApi().getNotifications()
    } catch { this.notifications = [] }
    finally { this.loading = false }
  }

  async markAllRead() {
    for (const n of this.notifications) {
      if (!n.read) {
        try { await getApi().markNotificationRead(n.id); n.read = true }
        catch { /* skip */ }
      }
    }
  }

  async onNotificationTap(n: VNotification) {
    if (!n.read) {
      try { await getApi().markNotificationRead(n.id); n.read = true }
      catch { /* skip */ }
    }
    // 跳转到相关帖子
    if (n.relatedId && (n.type === "like" || n.type === "comment")) {
      router.pushUrl({ url: "pages/PostDetailPage", params: { postId: n.relatedId } })
    }
  }

  getTypeIcon(type: string): string {
    const m: Record<string, string> = { "like": "❤️", "comment": "💬", "follow": "👤", "message": "✉️" }
    return m[type] ?? "🔔"
  }

  getTypeLabel(type: string): string {
    const m: Record<string, string> = { "like": "赞了你", "comment": "评论了你", "follow": "关注了你", "message": "发了消息" }
    return m[type] ?? ""
  }

  formatTime(t: string): string {
    if (!t) return ""
    const d = new Date(t)
    const now = new Date()
    const diff = now.getTime() - d.getTime()
    if (diff < 60000) return "刚刚"
    if (diff < 3600000) return Math.floor(diff / 60000) + "分钟前"
    if (diff < 86400000) return Math.floor(diff / 3600000) + "小时前"
    return `${d.getMonth() + 1}-${d.getDate()}`
  }
}
