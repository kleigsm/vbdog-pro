import { preferences } from "@kit.ArkData"
import { getApi } from "./ApiProvider"
import { LikeResult, CollectResult, Comment } from "./Models"

interface QueuedOp {
  type: string
  postId: string
  commentId: string
  text: string
  replyTo: string
  timestamp: number
}

const QUEUE_KEY: string = "offline_queue"
const STORE_NAME: string = "vbdog_offline"

export class OfflineQueue {
  private static queue: QueuedOp[] = []
  private static timer: number = -1

  static init(): void {
    OfflineQueue.load()
    OfflineQueue.timer = setInterval(() => OfflineQueue.flush(), 5000)
  }

  static add(type: string, postId: string, commentId?: string, text?: string, replyTo?: string): void {
    const op: QueuedOp = {
      type: type,
      postId: postId,
      commentId: commentId ?? "",
      text: text ?? "",
      replyTo: replyTo ?? "",
      timestamp: Date.now()
    }
    OfflineQueue.queue.push(op)
    OfflineQueue.save()
  }

  static get count(): number { return OfflineQueue.queue.length }

  static async flush(): Promise<void> {
    if (OfflineQueue.queue.length === 0) return
    const ops: QueuedOp[] = [...OfflineQueue.queue]
    OfflineQueue.queue = []
    OfflineQueue.save()

    const api = getApi()
    for (let i = 0; i < ops.length; i++) {
      try {
        const op: QueuedOp = ops[i]
        if (op.type === "like") { await api.likePost(op.postId) }
        else if (op.type === "collect") { await api.collectPost(op.postId) }
        else if (op.type === "comment") { await api.addComment(op.postId, op.text, op.replyTo || undefined) }
      } catch (e) {
        // 重放失败，放回队列
        OfflineQueue.queue.push(ops[i])
        OfflineQueue.save()
        break
      }
    }
  }

  private static load(): void {
    try {
      const s = preferences.getPreferencesSync(getContext(), { name: STORE_NAME })
      const raw: string = s.getSync(QUEUE_KEY, "[]") as string
      OfflineQueue.queue = JSON.parse(raw) as QueuedOp[]
    } catch (e) { OfflineQueue.queue = [] }
  }

  private static save(): void {
    try {
      const s = preferences.getPreferencesSync(getContext(), { name: STORE_NAME })
      s.putSync(QUEUE_KEY, JSON.stringify(OfflineQueue.queue))
      s.flush()
    } catch (e) { /* ignore */ }
  }
}
