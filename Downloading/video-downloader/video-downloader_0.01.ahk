#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\video-downloader-methods.ahk"

SetWorkingDir(A_ScriptDir)

app_version := "0.01"
lib_dir := A_ScriptDir "\lib"
yt_dlp_path := lib_dir "\yt-dlp.exe"
ffmpeg_path := lib_dir "\ffmpeg.exe"
ffprobe_path := lib_dir "\ffprobe.exe"
work_dir := A_ScriptDir "\.runtime"
batch_path := work_dir "\urls.txt"
log_path := work_dir "\download.log"
exit_path := work_dir "\exit-code.txt"
command_path := work_dir "\download-command.cmd"
download_pid := 0

if (!DirExist(lib_dir))
{
    DirCreate(lib_dir)
}

if (!DirExist(work_dir))
{
    DirCreate(work_dir)
}

default_output_dir := A_ScriptDir "\downloads"

if (!DirExist(default_output_dir))
{
    DirCreate(default_output_dir)
}

main_gui := Gui("", "video-downloader " app_version)
main_gui.SetFont("s10", "Segoe UI")

main_gui.AddText("xm ym", "Video URL(s)")
url_edit := main_gui.AddEdit("xm w780 r7")
paste_button := main_gui.AddButton("xm y+8 w110", "Paste URL")
clear_button := main_gui.AddButton("x+8 w110", "Clear")

main_gui.AddText("xm y+18", "Output folder")
output_edit := main_gui.AddEdit("xm w650", default_output_dir)
browse_button := main_gui.AddButton("x+8 yp-1 w120", "Browse...")

main_gui.AddText("xm y+18", "Quality")
quality_dropdown := main_gui.AddDropDownList("xm w190 Choose1", ["Best MP4", "1080p MP4", "720p MP4", "Audio MP3"])

main_gui.AddText("x+30 yp", "Browser cookies")
browser_dropdown := main_gui.AddDropDownList("x+0 y+4 w170 Choose1", ["No cookies", "Chrome", "Edge", "Firefox"])
playlist_checkbox := main_gui.AddCheckBox("x+30 yp+2", "Allow playlists")

install_button := main_gui.AddButton("xm y+22 w210 h34", "Install / Update Dependencies")
download_button := main_gui.AddButton("x+10 w140 h34 Default", "Download")
cancel_button := main_gui.AddButton("x+10 w110 h34 Disabled", "Cancel")
open_button := main_gui.AddButton("x+10 w130 h34", "Open Folder")

progress_bar := main_gui.AddProgress("xm y+18 w780 h20 Range0-100", 0)
status_text := main_gui.AddText("xm y+8 w780", "Ready.")

paste_button.OnEvent("Click", pasteUrl)
clear_button.OnEvent("Click", clearUrls)
browse_button.OnEvent("Click", browseOutput)
install_button.OnEvent("Click", installDependenciesFromUi)
download_button.OnEvent("Click", startDownload)
cancel_button.OnEvent("Click", cancelDownload)
open_button.OnEvent("Click", openOutputFolder)
main_gui.OnEvent("Close", closeApp)

main_gui.Show("w820 h500")
updateDependencyStatus()

/*
Pastes clipboard text into the URL field.
Existing text is preserved and a newline is inserted when necessary.
*/
pasteUrl(*)
{
    global url_edit

    clipboard_text := Trim(A_Clipboard)

    if (clipboard_text = "")
    {
        return
    }

    if (Trim(url_edit.Value) = "")
    {
        url_edit.Value := clipboard_text
    }
    else
    {
        url_edit.Value .= "`r`n" clipboard_text
    }
}

/*
Clears the URL input field.
This does not modify downloaded files or runtime dependencies.
*/
clearUrls(*)
{
    global url_edit
    url_edit.Value := ""
}

/*
Opens the Windows folder picker for the download destination.
The selected directory is written back to the output field.
*/
browseOutput(*)
{
    global output_edit

    start_dir := Trim(output_edit.Value)

    if (!DirExist(start_dir))
    {
        start_dir := A_ScriptDir
    }

    selected_dir := DirSelect(start_dir, 3, "Select download folder")

    if (selected_dir != "")
    {
        output_edit.Value := selected_dir
    }
}

/*
Opens the current output directory in Windows Explorer.
The directory is created first when it does not yet exist.
*/
openOutputFolder(*)
{
    global output_edit

    output_dir := Trim(output_edit.Value)

    if (output_dir = "")
    {
        return
    }

    if (!DirExist(output_dir))
    {
        DirCreate(output_dir)
    }

    Run("explorer.exe " quoteArg(output_dir))
}

/*
Installs or updates yt-dlp and installs FFmpeg when it is missing.
Official yt-dlp and Gyan FFmpeg Windows release URLs are used.
*/
installDependencies(force_ffmpeg := false)
{
    global lib_dir, yt_dlp_path, ffmpeg_path, ffprobe_path, status_text

    yt_dlp_url := "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    ffmpeg_url := "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    ffmpeg_zip := lib_dir "\ffmpeg-release-essentials.zip"
    extract_dir := lib_dir "\ffmpeg-extract"

    if (!DirExist(lib_dir))
    {
        DirCreate(lib_dir)
    }

    status_text.Text := "Downloading latest yt-dlp..."
    downloadWithPowerShell(yt_dlp_url, yt_dlp_path)

    if (force_ffmpeg || !FileExist(ffmpeg_path) || !FileExist(ffprobe_path))
    {
        status_text.Text := "Downloading FFmpeg essentials package..."
        downloadWithPowerShell(ffmpeg_url, ffmpeg_zip)

        if (DirExist(extract_dir))
        {
            DirDelete(extract_dir, true)
        }

        DirCreate(extract_dir)
        status_text.Text := "Extracting FFmpeg..."
        expandZipWithPowerShell(ffmpeg_zip, extract_dir)

        found_ffmpeg := ""
        found_ffprobe := ""

        Loop Files extract_dir "\*", "FR"
        {
            if (A_LoopFileName = "ffmpeg.exe")
            {
                found_ffmpeg := A_LoopFileFullPath
            }
            else if (A_LoopFileName = "ffprobe.exe")
            {
                found_ffprobe := A_LoopFileFullPath
            }
        }

        if (found_ffmpeg = "" || found_ffprobe = "")
        {
            throw Error("FFmpeg executables were not found after extraction.")
        }

        FileCopy(found_ffmpeg, ffmpeg_path, 1)
        FileCopy(found_ffprobe, ffprobe_path, 1)

        if (FileExist(ffmpeg_zip))
        {
            FileDelete(ffmpeg_zip)
        }

        if (DirExist(extract_dir))
        {
            DirDelete(extract_dir, true)
        }
    }
}

/*
Runs dependency installation from the UI and reports the result.
The FFmpeg package is reused unless the executables are missing.
*/
installDependenciesFromUi(*)
{
    global install_button, download_button, status_text

    install_button.Enabled := false
    download_button.Enabled := false

    try
    {
        installDependencies(false)
        status_text.Text := "Dependencies are ready."
        MsgBox("yt-dlp and FFmpeg are ready.", "video-downloader", "Iconi")
    }
    catch as error_value
    {
        status_text.Text := "Dependency installation failed."
        MsgBox(error_value.Message, "Dependency installation failed", "Iconx")
    }
    finally
    {
        install_button.Enabled := true
        download_button.Enabled := true
        updateDependencyStatus()
    }
}

/*
Downloads one file through Windows PowerShell.
The function throws an error when PowerShell returns a non-zero exit code.
*/
downloadWithPowerShell(url, destination_path)
{
    command := "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    script := "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri " quotePowerShell(url) " -OutFile " quotePowerShell(destination_path) " -UseBasicParsing"
    exit_code := RunWait(command quoteArg(script), , "Hide")

    if (exit_code != 0 || !FileExist(destination_path))
    {
        throw Error("Download failed: " url)
    }
}

/*
Extracts a ZIP archive using the PowerShell Expand-Archive command.
The function throws an error when extraction fails.
*/
expandZipWithPowerShell(zip_path, destination_dir)
{
    command := "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    script := "Expand-Archive -LiteralPath " quotePowerShell(zip_path) " -DestinationPath " quotePowerShell(destination_dir) " -Force"
    exit_code := RunWait(command quoteArg(script), , "Hide")

    if (exit_code != 0)
    {
        throw Error("Could not extract FFmpeg archive.")
    }
}

/*
Checks whether yt-dlp, ffmpeg and ffprobe are available.
The status label is updated without changing any files.
*/
updateDependencyStatus()
{
    global yt_dlp_path, ffmpeg_path, ffprobe_path, status_text

    if (FileExist(yt_dlp_path) && FileExist(ffmpeg_path) && FileExist(ffprobe_path))
    {
        status_text.Text := "Ready. Dependencies found."
    }
    else
    {
        status_text.Text := "Dependencies missing. Use Install / Update Dependencies."
    }
}

/*
Ensures that all runtime dependencies exist before a download starts.
The user can approve automatic installation when required.
*/
ensureDependencies()
{
    global yt_dlp_path, ffmpeg_path, ffprobe_path

    if (FileExist(yt_dlp_path) && FileExist(ffmpeg_path) && FileExist(ffprobe_path))
    {
        return true
    }

    answer := MsgBox("yt-dlp or FFmpeg is missing.`n`nInstall the required dependencies now?", "video-downloader", "YesNo Icon?")

    if (answer != "Yes")
    {
        return false
    }

    installDependencies(false)
    return FileExist(yt_dlp_path) && FileExist(ffmpeg_path) && FileExist(ffprobe_path)
}

/*
Starts a hidden yt-dlp process for all URLs currently in the input field.
URLs are passed through a batch file so pasted text is not executed by CMD.
*/
startDownload(*)
{
    global url_edit, output_edit, quality_dropdown, browser_dropdown, playlist_checkbox
    global batch_path, log_path, exit_path, command_path, yt_dlp_path, download_pid
    global progress_bar, status_text, download_button, cancel_button, install_button

    if (download_pid != 0 && ProcessExist(download_pid))
    {
        return
    }

    try
    {
        urls := parseUrlList(url_edit.Value)

        if (urls.Length = 0)
        {
            MsgBox("Paste at least one video URL first.", "video-downloader", "Icon!")
            return
        }

        if (!ensureDependencies())
        {
            updateDependencyStatus()
            return
        }

        output_dir := Trim(output_edit.Value)

        if (output_dir = "")
        {
            throw Error("Choose an output folder.")
        }

        if (!DirExist(output_dir))
        {
            DirCreate(output_dir)
        }

        fileDeleteIfExists(batch_path)
        fileDeleteIfExists(log_path)
        fileDeleteIfExists(exit_path)
        fileDeleteIfExists(command_path)

        url_text := ""

        for url in urls
        {
            url_text .= url "`r`n"
        }

        FileAppend(url_text, batch_path, "UTF-8-RAW")

        args := buildYtDlpArgs(
            batch_path,
            output_dir,
            quality_dropdown.Text,
            browser_dropdown.Text,
            playlist_checkbox.Value = 1
        )

        command_text := "@echo off`r`n"
        command_text .= quoteArg(yt_dlp_path) " " args " > " quoteArg(log_path) " 2>&1`r`n"
        command_text .= "set _VD_EXIT=%ERRORLEVEL%`r`n"
        command_text .= "> " quoteArg(exit_path) " echo %_VD_EXIT%`r`n"
        command_text .= "exit /b %_VD_EXIT%`r`n"
        FileAppend(command_text, command_path, "CP0")

        progress_bar.Value := 0
        status_text.Text := "Starting download..."
        download_button.Enabled := false
        install_button.Enabled := false
        cancel_button.Enabled := true

        Run(A_ComSpec " /D /Q /C " quoteArg(command_path), , "Hide", &download_pid)
        SetTimer(checkDownloadStatus, 350)
    }
    catch as error_value
    {
        status_text.Text := "Could not start download."
        MsgBox(error_value.Message, "video-downloader", "Iconx")
        resetDownloadUi()
    }
}

/*
Polls yt-dlp progress output and updates the progress bar.
When the hidden process ends, the final exit code is reported to the user.
*/
checkDownloadStatus()
{
    global download_pid, log_path, exit_path, progress_bar, status_text

    if (FileExist(log_path))
    {
        try
        {
            log_text := FileRead(log_path, "UTF-8")
            last_percent := ""
            last_speed := ""
            last_eta := ""
            search_pos := 1

            while (search_pos := RegExMatch(log_text, "PROGRESS:\s*([0-9.]+)%\|([^|]*)\|([^`r`n]*)", &progress_match, search_pos))
            {
                last_percent := progress_match[1]
                last_speed := Trim(progress_match[2])
                last_eta := Trim(progress_match[3])
                search_pos := progress_match.Pos(0) + progress_match.Len(0)
            }

            if (last_percent != "")
            {
                progress_bar.Value := Round(last_percent)
                status_text.Text := "Downloading: " last_percent "%   " last_speed "   ETA " last_eta
            }
        }
    }

    if (download_pid != 0 && !ProcessExist(download_pid))
    {
        SetTimer(checkDownloadStatus, 0)
        exit_code := readExitCode()

        if (exit_code = 0)
        {
            progress_bar.Value := 100
            status_text.Text := "Download complete."
        }
        else
        {
            status_text.Text := "Download failed. Exit code: " exit_code
            showLastLogLines()
        }

        download_pid := 0
        resetDownloadUi()
    }
}

/*
Reads the exit code written by the generated command file.
A value of -1 means that no usable exit code was available.
*/
readExitCode()
{
    global exit_path

    if (!FileExist(exit_path))
    {
        return -1
    }

    value := Trim(FileRead(exit_path, "CP0"))

    if (!IsInteger(value))
    {
        return -1
    }

    return value + 0
}

/*
Shows the last part of the yt-dlp log after a failed download.
The complete log remains in the hidden .runtime project directory.
*/
showLastLogLines()
{
    global log_path

    if (!FileExist(log_path))
    {
        return
    }

    log_text := FileRead(log_path, "UTF-8")
    lines := StrSplit(StrReplace(log_text, "`r", ""), "`n")
    start_index := Max(1, lines.Length - 14)
    message := ""

    Loop lines.Length - start_index + 1
    {
        index := start_index + A_Index - 1
        message .= lines[index] "`r`n"
    }

    if (Trim(message) != "")
    {
        MsgBox(message, "yt-dlp error", "Iconx")
    }
}

/*
Cancels the active command process and its child yt-dlp process tree.
Partially downloaded temporary files are left for yt-dlp to resume later.
*/
cancelDownload(*)
{
    global download_pid, status_text

    if (download_pid = 0)
    {
        return
    }

    if (ProcessExist(download_pid))
    {
        RunWait(A_ComSpec " /D /Q /C taskkill /PID " download_pid " /T /F >nul 2>&1", , "Hide")
    }

    SetTimer(checkDownloadStatus, 0)
    download_pid := 0
    status_text.Text := "Download cancelled."
    resetDownloadUi()
}

/*
Restores the button states after a download finishes or is cancelled.
This function does not alter the progress bar or status message.
*/
resetDownloadUi()
{
    global download_button, cancel_button, install_button

    download_button.Enabled := true
    install_button.Enabled := true
    cancel_button.Enabled := false
}

/*
Deletes one runtime file when it exists.
Missing files are intentionally ignored.
*/
fileDeleteIfExists(file_path)
{
    if (FileExist(file_path))
    {
        FileDelete(file_path)
    }
}

/*
Closes the application after stopping any active download process.
The dependency binaries and completed downloads are preserved.
*/
closeApp(*)
{
    global download_pid

    if (download_pid != 0 && ProcessExist(download_pid))
    {
        answer := MsgBox("A download is still running.`n`nCancel it and close?", "video-downloader", "YesNo Icon?")

        if (answer != "Yes")
        {
            return true
        }

        cancelDownload()
    }

    ExitApp()
}
