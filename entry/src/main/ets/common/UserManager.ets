/**
 * UserManager — 用户状态管理（DataStore 持久化）
 */

import { preferences } from "@kit.ArkData"
import { User } from "./Models"
import { getApi } from "./ApiProvider"
import { SupabaseClient } from "./SupabaseClient"

const STORE_NAME = "vbdog_pro_user"
const KEY_USER_ID = "userId"
const KEY_NICKNAME = "nickname"
const KEY_PHONE = "phone"

export class UserManager {
  private static _store: preferences.Preferences | null = null
  private static _currentUser: User | null = null

  static async init(): Promise<void> {
    UserManager._store = preferences.getPreferencesSync(getContext(), { name: STORE_NAME })
    const userId = UserManager._store.getSync(KEY_USER_ID, "") as string
    if (userId) {
      const api = getApi() as SupabaseClient
      api.setUserId(userId)
      try {
        UserManager._currentUser = await api.getCurrentUser()
      } catch {
        UserManager.clear()
      }
    }
  }

  static get currentUser(): User | null { return UserManager._currentUser }
  static get isLoggedIn(): boolean { return UserManager._currentUser !== null }

  static async setUser(user: User, userId: string): Promise<void> {
    UserManager._currentUser = user
    const api = getApi() as SupabaseClient
    api.setUserId(userId)
    if (UserManager._store) {
      UserManager._store.putSync(KEY_USER_ID, userId)
      UserManager._store.putSync(KEY_PHONE, user.phone)
      UserManager._store.putSync(KEY_NICKNAME, user.nickname)
      UserManager._store.flush()
    }
  }

  static clear(): void {
    UserManager._currentUser = null
    if (UserManager._store) {
      UserManager._store.deleteSync(KEY_USER_ID)
      UserManager._store.deleteSync(KEY_PHONE)
      UserManager._store.deleteSync(KEY_NICKNAME)
      UserManager._store.flush()
    }
  }
}
