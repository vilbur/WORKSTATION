#NoEnv
#SingleInstance Force
#Include %A_ScriptDir%\..\src\Keyboard-Setup-Core.ahk

assertEquals("hello world", keyboardToggleThreeCase("HELLO WORLD"), "Upper to lower")
assertEquals("Hello World", keyboardToggleThreeCase("hello world"), "Lower to Capital")
assertEquals("HELLO WORLD", keyboardToggleThreeCase("Hello World"), "Capital to upper")
assertEquals("!? 123", keyboardToggleThreeCase("!? 123"), "Nonletters unchanged")

assertEquals("Hello World", keyboardCycleConvention("hello world"), "lowercase to Capital")
assertEquals("HELLO WORLD", keyboardCycleConvention("Hello World"), "Capital to uppercase")
assertEquals("HelloWorld", keyboardCycleConvention("HELLO WORLD"), "uppercase to Pascal")
assertEquals("helloWorld", keyboardCycleConvention("HelloWorld"), "Pascal to camel")
assertEquals("hello_world", keyboardCycleConvention("helloWorld"), "camel to snake low")
assertEquals("Hello_World", keyboardCycleConvention("hello_world"), "snake low to Capital")
assertEquals("HELLO_WORLD", keyboardCycleConvention("Hello_World"), "snake Capital to upper")
assertEquals("hello world", keyboardCycleConvention("HELLO_WORLD"), "snake upper to lowercase")

assertEquals(Chr(34) . "hello" . Chr(34), keyboardToggleQuotes("hello"), "Wrap quotes")
assertEquals("hello", keyboardToggleQuotes(Chr(34) . "hello" . Chr(34)), "Unwrap quotes")
assertEquals("file%20name%20%26%20more", keyboardUrlEncode("file name & more"), "URL encode")

MsgBox, 64, Keyboard Setup Tests, PASS: Case cycles, quotes, URL encoding.
ExitApp, 0

/*
Stop immediately when an assertion fails.
*/
assertEquals(expected, actual, description)
{
    if (expected != actual)
    {
        MsgBox, 16, Keyboard Setup Tests, % "FAIL: " . description . "`nExpected: " . expected . "`nActual: " . actual
        ExitApp, 1
    }
}
