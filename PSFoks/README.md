# **PSFoks 0.0.1**

A PowerShell 7 module implementing FOKS KV store functionality to support a Web interface
called, **Foks-Explorer**. 

This module is functional on either Windows, Linux, or MacOS operating systems where PowerShell 7 is supported.

1. **Installation of PSFoks**
   

    Copy the PSFoks directory to the default module installation location on your OS.  On Linux,
    this location is **$HOME/.local/share/powershell/modules**.

2. **Overview of PSFoks**
   

    **PS> Get-Command -module PKFoks**

    This command will provide the following output.

    ```
    CommandType     Name                                               Version    Source
    -----------     ----                                               -------    ------
    Alias           Foks-Bye                                           0.0.1      PSFoks
    Alias           Foks-ConsoleLog                                    0.0.1      PSFoks
    Function        Add-FoksKeyValue                                   0.0.1      PSFoks
    Function        Clear-FoksConsole                                  0.0.1      PSFoks
    Function        Edit-FoksKeyValue                                  0.0.1      PSFoks
    Function        Get-FoksConsole                                    0.0.1      PSFoks
    Function        Get-FoksKeyValue                                   0.0.1      PSFoks
    Function        Get-FoksModKeyPaths                                0.0.1      PSFoks
    Function        Remove-FoksKeyValue                                0.0.1      PSFoks
    Function        Set-FoksPassPhrase                                 0.0.1      PSFoks
    ```


    **PS> Get-Help Get-FoksModKeyPath -full**

    To get help on individual functions within **PSFoks**

***

## **Version Changes**

| Version | Date | Description
| :------- | :------- | :-------------
| 0.0.1 | 2025-08-14 | Initial release
