import { preferences } from "@kit.ArkData"
import { User } from "./Models"
import { getApi } from "./ApiProvider"
import { SupabaseClient } from "./SupabaseClient"
import { common } from "@kit.AbilityKit"

const STORE_NAME: string = "vbdog_pro_user"
const KEY_USER_ID: string = "userId"
const KEY_NICKNAME: string = "nickname"
const KEY_PHONE: string = "phone"

export class UserManager {
  private static _store: preferences.Preferences | null = null
  private static _currentUser: User | null = null
  private static _context: common.Context | null = null

  static init(context: common.Context): void {
    UserManager._context = context
    try {
      UserManager._store = preferences.getPreferencesSync(context, { name: STORE_NAME })
      const userId: string = UserManager._store.getSync(KEY_USER_ID, "") as string
      if (userId) {
        const api = getApi() as SupabaseClient
        api.setUserId(userId)
        UserManager._store.getSync(KEY_USER_ID, "")  // warm up
      }
    } catch (e) {
      UserManager._store = null
    }
  }

  static async restoreSession(): Promise<void> {
    if (!UserManager._store) return
    try {
      const userId: string = UserManager._store.getSync(KEY_USER_ID, "") as string
      if (!userId) return
      const api = getApi() as SupabaseClient
      api.setUserId(userId)
      UserManager._currentUser = await api.getCurrentUser()
    } catch (e) {
      UserManager.clear()
    }
  }

  static get currentUser(): User | null { return UserManager._currentUser }
  static get isLoggedIn(): boolean { return UserManager._currentUser !== null }

  static async setUser(user: User, userId: string): Promise<void> {
    UserManager._currentUser = user
    const api = getApi() as SupabaseClient
    api.setUserId(userId)
    if (UserManager._store) {
      try {
        UserManager._store.putSync(KEY_USER_ID, userId)
        UserManager._store.putSync(KEY_PHONE, user.phone)
        UserManager._store.putSync(KEY_NICKNAME, user.nickname)
        UserManager._store.flush()
      } catch (e) { /* ignore */ }
    }
  }

  static clear(): void {
    UserManager._currentUser = null
    if (UserManager._store) {
      try {
        UserManager._store.deleteSync(KEY_USER_ID)
        UserManager._store.deleteSync(KEY_PHONE)
        UserManager._store.deleteSync(KEY_NICKNAME)
        UserManager._store.flush()
      } catch (e) { /* ignore */ }
    }
  }
}
