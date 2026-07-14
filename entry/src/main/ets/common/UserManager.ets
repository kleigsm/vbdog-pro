/**
 * UserManager — 用户状态管理
 * 使用 DataStore 持久化登录态
 */

import { preferences } from "@kit.ArkData"
import { User } from "./Models"
import { setApi } from "./ApiProvider"
import { SupabaseClient } from "./SupabaseClient"

const STORE_NAME = "vbdog_pro_user"
const KEY_TOKEN = "token"
const KEY_USER_ID = "userId"
const KEY_PHONE = "phone"
const KEY_NICKNAME = "nickname"

export class UserManager {
  private static _store: preferences.Preferences | null = null
  private static _currentUser: User | null = null

  static async init(): Promise<void> {
    UserManager._store = preferences.getPreferencesSync(getContext(), { name: STORE_NAME })
    // 恢复登录态
    const token = UserManager._store.getSync(KEY_TOKEN, "") as string
    if (token) {
      const client = new SupabaseClient()
      client.setToken(token)
      setApi(client)
      try {
        UserManager._currentUser = await client.getCurrentUser()
      } catch {
        // token 过期，清除
        UserManager.clear()
      }
    }
  }

  static get currentUser(): User | null {
    return UserManager._currentUser
  }

  static get isLoggedIn(): boolean {
    return UserManager._currentUser !== null
  }

  static async setUser(user: User, token: string): Promise<void> {
    UserManager._currentUser = user
    if (UserManager._store) {
      UserManager._store.putSync(KEY_TOKEN, token)
      UserManager._store.putSync(KEY_USER_ID, user.id)
      UserManager._store.putSync(KEY_PHONE, user.phone)
      UserManager._store.putSync(KEY_NICKNAME, user.nickname)
      UserManager._store.flush()
    }
  }

  static clear(): void {
    UserManager._currentUser = null
    if (UserManager._store) {
      UserManager._store.deleteSync(KEY_TOKEN)
      UserManager._store.deleteSync(KEY_USER_ID)
      UserManager._store.flush()
    }
  }
}
