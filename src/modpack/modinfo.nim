import regex, sequtils, strutils, sugar, terminal
import ../api/cf
import ../mc/version

type
  Compability* = enum
    ## compability of a mod version with the modpack version
    ## none = will not be compatible
    ## major = mod major version matches modpack major version, probably compatible
    ## full = mod version exactly matches modpack version, fully compatible
    none, major, full

  Freshness* = enum
    ## if an update to the currently installed version is available
    ## old = file is not the latest version for all gameversions
    ## newestForAVersion = file is the latest version for a gameversion
    ## newest = file is the newest version for the current modpack version
    old, newestForAVersion, newest

proc getCompability*(file: CfModFile, modpackVersion: Version): Compability =
  ## get compability of a file
  if modpackVersion in file.gameVersions: return Compability.full
  if modpackVersion.minor in file.gameVersions.proper.map(minor): return Compability.major
  return Compability.none

proc getColor*(c: Compability): ForegroundColor =
  ## get the color for a compability
  case c:
    of Compability.full: fgGreen
    of Compability.major: fgYellow
    of Compability.none: fgRed

proc getMessage*(c: Compability): string =
  ## get the message for a certain compability
  case c:
    of Compability.full: "The installed mod is compatible with the modpack's minecraft version."
    of Compability.major: "The installed mod only matches the major version as the modpack. Issues may arise."
    of Compability.none: "The installed mod is incompatible with the modpack's minecraft version."

proc getFreshness*(file: CfModFile, modpackVersion: Version, cfMod: CfMod): Freshness =
  ## get freshness of a file
  let latestFiles = cfMod.gameVersionLatestFiles
  for versionFile in latestFiles:
    if versionFile.fileId == file.fileId:
      if versionFile.version == modpackVersion:
        return Freshness.newest
      elif file.gameVersions.proper.any((x) => x > modpackVersion):
        return Freshness.newestForAVersion
  return Freshness.old

proc getColor*(f: Freshness): ForegroundColor =
  ## get the color for a freshness
  case f:
    of Freshness.newest: fgGreen
    of Freshness.newestForAVersion: fgYellow
    of Freshness.old: fgRed

proc getMessage*(f: Freshness): string =
  ## get the message for a certain freshness
  case f:
    of Freshness.newest: "No mod updates available."
    of Freshness.newestForAVersion: "Your installed version is newer than the recommended version. Issues may arise."
    of Freshness.old: "There is a newer version of this mod available."

proc isFabricMod*(file: CfModFile): bool =
  ## returns true if `file` is a fabric mod.
  if "Fabric".Version in file.gameVersions:
    return true
  elif file.name.toLower.match(re".*\Wfabric\W.*"):
    return true
  return false

proc isForgeMod*(file: CfModFile): bool =
  ## returns true if `file` is a forge mod.
  if not ("Fabric".Version in file.gameVersions and not ("Forge".Version in file.gameVersions)):
    return true
  elif file.name.toLower.match(re".*\Wforge\W.*"):
    return true
  return false