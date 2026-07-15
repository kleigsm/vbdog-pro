import { UIAbility, Want, AbilityConstant } from "@kit.AbilityKit"
import { window } from "@kit.ArkUI"
import { SupabaseClient } from "../common/SupabaseClient"
import { setApi } from "../common/ApiProvider"
import { UserManager } from "../common/UserManager"

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    setApi(new SupabaseClient())
    UserManager.init(this.context)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent("pages/Index", (err) => {
      if (err.code) console.error("Failed to load content: " + JSON.stringify(err))
    })
  }
}
