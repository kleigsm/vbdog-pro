/**
 * EntryAbility — 应用入口
 * 初始化 API 层和用户状态
 */

import { UIAbility, Want, AbilityConstant } from "@kit.AbilityKit"
import { window } from "@kit.ArkUI"
import { SupabaseClient } from "../common/SupabaseClient"
import { setApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 初始化 API 层（替换此行即可切换后端）
    setApi(new SupabaseClient())
    UserManager.init()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent("pages/Index", (err) => {
      if (err.code) console.error("Failed to load content: " + JSON.stringify(err))
    })
  }
}
