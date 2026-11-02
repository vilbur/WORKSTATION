#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "lib\video-downloader-methods.ahk"

SetWorkingDir(A_ScriptDir)

passed_tests := 0
failed_tests := 0
failure_text := ""

runTest("HTTP URL accepted", isHttpUrl("https://www.youtube.com/watch?v=abc123") = true)
runTest("xHamster URL accepted", isHttpUrl("https://xhamster.com/videos/example") = true)
runTest("Non-HTTP input rejected", isHttpUrl("not a url") = false)

urls := parseUrlList("https://youtu.be/abc`nhttps://youtu.be/abc`nhttps://xhamster.com/videos/test")
runTest("Duplicate URLs removed", urls.Length = 2)

best_args := getQualityArgs("Best MP4")
runTest("Best MP4 uses merged streams", InStr(best_args, "bv*+ba/b") > 0)
runTest("Best MP4 requests MP4", InStr(best_args, "--merge-output-format mp4") > 0)

mp3_args := getQualityArgs("Audio MP3")
runTest("Audio preset extracts audio", InStr(mp3_args, "-x") > 0)
runTest("Audio preset requests MP3", InStr(mp3_args, "--audio-format mp3") > 0)

browser_args := getBrowserArgs("Chrome")
runTest("Chrome cookie argument", browser_args = " --cookies-from-browser chrome")
runTest("No-cookie argument empty", getBrowserArgs("No cookies") = "")

batch_path := A_ScriptDir "\test-urls.txt"
output_dir := A_ScriptDir "\test-output"
full_args := buildYtDlpArgs(batch_path, output_dir, "1080p MP4", "No cookies", false)
runTest("Batch file argument present", InStr(full_args, "--batch-file") > 0)
runTest("No-playlist enabled by default", InStr(full_args, "--no-playlist") > 0)
runTest("1080p filter present", InStr(full_args, "height<=1080") > 0)
runTest("CMD output template escapes percent signs", InStr(full_args, "%%(title)s") > 0)

summary := "Passed: " passed_tests "`nFailed: " failed_tests

if (failed_tests > 0)
{
    summary .= "`n`n" failure_text
    MsgBox(summary, "video-downloader tests", "Iconx")
    ExitApp(1)
}

MsgBox(summary, "video-downloader tests", "Iconi")
ExitApp(0)

/*
Runs one boolean test and records the result.
Failed test names are appended to the final summary dialog.
*/
runTest(test_name, condition)
{
    global passed_tests, failed_tests, failure_text

    if (condition)
    {
        passed_tests += 1
    }
    else
    {
        failed_tests += 1
        failure_text .= "FAILED: " test_name "`n"
    }
}
