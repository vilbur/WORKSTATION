/*
Cycle selected text through UPPERCASE, lowercase and Capital words.
*/
keyboardToggleThreeCase(input_text)
{
    if !RegExMatch(input_text, "\p{L}")
    {
        return input_text
    }

    StringLower, lower_text, input_text
    StringUpper, upper_text, input_text
    StringUpper, capital_text, lower_text, T

    if (input_text == upper_text)
    {
        return lower_text
    }
    if (input_text == lower_text)
    {
        return capital_text
    }
    return upper_text
}

/*
Wrap selected text in double quotes or remove its matching outer quotes.
*/
keyboardToggleQuotes(input_text)
{
    quote_character := Chr(34)
    text_length := StrLen(input_text)
    if (text_length >= 2 && SubStr(input_text, 1, 1) == quote_character && SubStr(input_text, 0) == quote_character)
    {
        return SubStr(input_text, 2, text_length - 2)
    }
    return quote_character . input_text . quote_character
}

/*
Convert text to the next of eight naming conventions without removing line breaks.
*/
keyboardCycleConvention(input_text)
{
    line_break := InStr(input_text, "`r`n") ? "`r`n" : "`n"
    normalized_text := StrReplace(input_text, "`r`n", "`n")
    result_text := ""
    for line_index, line_text in StrSplit(normalized_text, "`n")
    {
        if (line_index > 1)
        {
            result_text .= line_break
        }
        result_text .= keyboardCycleConventionLine(line_text)
    }
    return result_text
}

/*
Detect and advance the naming style of one line.
*/
keyboardCycleConventionLine(line_text)
{
    if (Trim(line_text) == "")
    {
        return line_text
    }

    working_text := RegExReplace(line_text, "([A-Z])([A-Z][a-z])", "$1 $2")
    working_text := RegExReplace(working_text, "([a-z0-9])([A-Z])", "$1 $2")
    working_text := Trim(RegExReplace(working_text, "[_\s]+", " "))
    StringLower, working_text, working_text
    words := StrSplit(working_text, " ")

    next_style := 1
    Loop, 8
    {
        if (keyboardComposeConvention(words, A_Index) == line_text)
        {
            next_style := Mod(A_Index, 8) + 1
            break
        }
    }
    return keyboardComposeConvention(words, next_style)
}

/*
Compose a list of words using one of the eight supported styles.
*/
keyboardComposeConvention(words, style_index)
{
    result_text := ""
    for word_index, word_text in words
    {
        StringLower, lower_word, word_text
        StringUpper, upper_word, lower_word
        StringUpper, capital_word, lower_word, T

        if (style_index == 1 || style_index == 2 || style_index == 3)
        {
            separator := word_index > 1 ? " " : ""
        }
        else if (style_index >= 6)
        {
            separator := word_index > 1 ? "_" : ""
        }
        else
        {
            separator := ""
        }

        if (style_index == 1 || style_index == 6 || (style_index == 5 && word_index == 1))
        {
            converted_word := lower_word
        }
        else if (style_index == 3 || style_index == 8)
        {
            converted_word := upper_word
        }
        else
        {
            converted_word := capital_word
        }
        result_text .= separator . converted_word
    }
    return result_text
}

/*
Percent-encode UTF-8 text for a web query string.
*/
keyboardUrlEncode(input_text)
{
    byte_count := StrPut(input_text, "UTF-8") - 1
    VarSetCapacity(buffer, byte_count + 1, 0)
    StrPut(input_text, &buffer, byte_count + 1, "UTF-8")
    encoded_text := ""
    Loop, %byte_count%
    {
        byte_value := NumGet(buffer, A_Index - 1, "UChar")
        if ((byte_value >= 0x30 && byte_value <= 0x39) || (byte_value >= 0x41 && byte_value <= 0x5A) || (byte_value >= 0x61 && byte_value <= 0x7A) || byte_value == 0x2D || byte_value == 0x2E || byte_value == 0x5F || byte_value == 0x7E)
        {
            encoded_text .= Chr(byte_value)
        }
        else
        {
            encoded_text .= "%" . Format("{:02X}", byte_value)
        }
    }
    return encoded_text
}
