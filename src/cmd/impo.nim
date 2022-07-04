import std/os
import zippy/ziparchives
import init
import ../modpack/manifest
import ../term/log

proc paxImport*(path: string, force: bool, skipGit: bool): void =
    ## import the modpack from .zip
    if force:
        removeDir(packFolder)
    else:
        rejectPaxProject()

    let (_, name, ext) = splitFile(path)
    if ext != ".zip":
        echoError "Target file is not a .zip file."
        quit(1)
    
    echoDebug "Importing .zip.."
    extractAll(path, tempPackFolder)
    let nestedModpackDir = joinPath(tempPackFolder, "modpack/")
    if dirExists(nestedModpackDir):
        moveDir(nestedModpackDir, projectFolder)
    else:
        moveDir(tempPackFolder, packFolder)

    if not fileExists(packFolder / "manifest.json"):
        echoError "Could not import .zip: manifest.json not found."
        echoClr indentPrefix, "Make sure your .zip file is a valid minecraft modpack in the curseforge modpack format."
        quit(1)
    
    let manifest = readManifestFromDisk()
    manifest.writeToDisk()

    createDir(overridesFolder)
    writeFile(paxFile, "Modpack generated by PAX")

    if not skipGit:
        paxInitGit()

    echoInfo (name & ext).fgGreen, " imported."