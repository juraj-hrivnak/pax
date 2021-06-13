import asyncdispatch, options, os, strutils, terminal
import common
import ../api/metadata
import ../cli/prompt, ../cli/term
import ../util/flow
import ../mc/version
import ../modpack/files, ../modpack/install, ../modpack/loader

proc paxInit*(force: bool): void =
  ## initialize a new modpack in the current directory
  if not force:
    rejectPaxProject()
    returnIfNot promptYN("Are you sure you want to create a pax manifest in the current folder?", default = true)

  echoRoot styleDim, "MANIFEST" 
  var manifest = Manifest()
  manifest.name = prompt(indentPrefix & "Modpack name")
  manifest.author = prompt(indentPrefix & "Modpack author")
  manifest.version = prompt(indentPrefix & "Modpack version", default = "1.0.0")
  manifest.mcVersion = Version(prompt(indentPrefix & "Minecraft version", default = "1.16.5"))

  let loader = prompt(indentPrefix & "Loader", choices = @["forge", "fabric"], default = "forge").toLoader
  let loaderId = waitFor(manifest.mcVersion.getMcModloaderId(loader))
  if loaderId.isNone:
    echoError "This is either not a minecraft version, or no ", loader, " version exists for this minecraft version."
    quit(1)
  manifest.mcModloaderId = loaderId.get()
  echoDebug "Installed ", loader, " version ", fgGreen, manifest.mcModloaderId

  echoInfo "Creating manifest.."
  removeDir(packFolder)
  createDir(packFolder)
  createDir(overridesFolder)
  writeFile(paxFile, "Modpack generated by PAX")
  manifest.writeToDisk()