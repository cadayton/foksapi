# **PSKeyBase 1.0.8**

A PowerShell 7 module implementing the following KeyBase functionality.

This module is functional on either Windows, Linux, or MacOS operating systems where PowerShell 7 is supported.

1. **KeyBase KVstore Explorer**

   A set of cmdlets for performing CRUD operations on key/value pairs in the KeyBase KVstore.  The NameSpace
   and entryKey metadata is obsured by using a random 12 characters in place of plain text values.

    See [KV-Explorer](https://cadayton.onrender.com/scripts/KV-Explorer.gif) in action from the **CLI**.

    See [Web-KVExplorer](https://cadayton.onrender.com/scripts/PW-KVExplorer.gif) in action from the **WEB**.

2. **KeyBase FileSystem Explorer** for displaying folders and files.

    See [KB-Explorer](https://cadayton.onrender.com/scripts/KB-Explorer.png) in action from the **CLI**.

3. **File Encryption** for encrypting a file or all files within a folder.

   The decryption token is maintained in the Keybase KV store by default. This default behavior
   can be overriden if it is desired to maintain the decryption token else where.

4. **KV store value** encryption and signing.

***
***

There is now a Web interface developed with Pode.Web for using the **KV-Explorer** feature along with the existing CLI interface.

For details about the Pode.Web implementation see [PW-KVExplorer](https://cadayton.onrender.com/PodeWeb/PW-KVExplorer.html)

***
***

Cmdlets starting with the **Show** verb are for human consumption while any other cmdlets are for programmatic consumption.

The **PSKeyBase** module KV store cmdlets are:

***
***

## **Version Changes**

| Version | Date | Description
| :------- | :------- | :-------------
| 1.0.8 | 2025-02-17 | Add-PSKEncryption -NoKB option no KeyBase client needed. Prompt to set passphrase
| 1.0.7 | 2023-02-07 | -keep option on Remove-PSKEncryption will surpress confirmation prompt
| 1.0.6 | 2022-05-11 | Added Web interface using Pode.Web for KV-Explorer feature
| 1.0.5 | 2021-10-16 | Added PSReadline console history log cmdlets
| 1.0.4 | 2021-09-19 | Added message encryption and signing cmdlets
| 1.0.3 | 2021-07-13 | Fixed invalid reference to Test-Privilege
| 1.0.2 | 2021-07-11 | File Encryption leveraging the KV store.
| 1.0.1 | 2021-04-18 | Parse namespace/entrykey correctly with embedded spaces
| 1.0.0 | 2021-03-25 | Initial release

***
***

## **PSReadline console history log cmdlets 1.0.6**

***

| Alias          | cmdlet                    | Description
|:---------------| :------------------------ | :---------------- |
|**KB-Bye**   | **Clear-PSKConsole**    | Removes the PSReadline console log and exits the session |
|**KB-Console**   | **Get-PSKConsole**   | Returns or displays current console log records |

Enhancements made to **KB-Encode** and **KB-Decode**.

***
***

## **Message encryption and signing cmdlets 1.0.4**

***

| Alias          | cmdlet                    | Description
|:---------------| :------------------------ | :---------------- |
|**KV-Encode**   | **Set-PSKSignedValue**    | Encrypts and signs a KV store value |
|**KV-Decode**   | **Show-PSKSignedValue**   | Decrypts and verifies the signature of a KV store value |
|**KB-Encode**   | **Set-PSKEncodeMessage**  | Encrypts and signs a message string or file |
|**KB-Decode**   | **Show-PSKEncodeMessage** | Decrypts and verifies the signature of a message or file |

For help on any of above cmdlets enter:

``` pwsh
  Get-Help KV-Enode -full

  OR

  Get-Help Set-PSKSignedValue -full
```

***
***

### KV store value encryption and signage

The use case for using an encrypted and signed KV store value is for validating a login to a Web Server using an
account name and password field.

Login to a Web Server will require the following steps.

``` pwsh
  KV-Encode -entryKey Pode9001 -namespace Web -Team ShareTeam
```

After **KV-Encode** completes the clipboard contains the encrypted KV store value and the signature of the keybase
account that acquired the KV store value.

In Web Server's Login user name field, the keybase account name is entered and in the password field the user enters **ctrl-v**
to copy the contents of the clipboard into the field.

The Web Server then.

  1. Verifies the contents of password field was signed by the keybase account and that the password is correct.
  2. On successful validation, the Web Servers then sets a new password for the KV store entry.

For testing purpose, execute **KV-Decode** to decrypt and display the value in the clipboard.

``` pswh
  KV-Decode
    Decrypted Value is: cV}9ZD07z2FuvY&:;CmgX\36).A!8?n4kKf+15yM  Verified: Authored by cadayton (you)  
```

### Message or File encryption and signage

There is malware in the wild that can monitor the clipboard for crypto currency address copied to the clipboard
and then replace that crypto currency address with a different address without you being aware of the change.

One can use **KB-Encode** and **KB-Decode** to encrypt and sign content sent to the clipboard or to a file

***

## **KeyBase KVstore cmdlets**

***

| Alias          | cmdlet                    | Description
|:---------------| :------------------------ | :---------------- |
|**KV-Explorer** | **Show-PKSNameSpaceHash** | Displays existing namespace/key pairs in a Grid View. Select an entry to perform CRUD operations |
|                | **Get-PSKNameSpaces**     | returns an object containing the namespaces in use. Not decoded. |
|                | **Get-PSKentryKeys**      | returns an object containing the namespace/key pairs. |
|                | **Get-PSKEntryValue**     | returns an object containing the value of a specified namespace/key pair. |
|                | **Show-PSKEntryValue**    | Displays the value of a specified namespace/key pair in a Grid View. |
|                | **Set-PSKEntryValue**     | Creates/Updates the value of a specified namespace/key pair. |
|                | **Remove-PSKentryKey**    | Deletes key/value pair in a specified namespace. |
|                | **Set-PKSConfiguration**  | Create/Update the configuration file. |
***
***

## **KeyBase FS cmdlets**

***
| Alias | cmdlet                           | Description
| :---------------| :--------------------- | :---------------- |
| **KB-Explorer** | **Show-PKSFileSystem** | Displays folders and files in a Grid View |
|                 | **Get-PKSCapacity**    | returns available capacity in the Keybase filesystem |
|                 | **Show-PKSCapacity**   | Outputs KeyBase filesytem capacity metrics |
|                 | **Get-PKSFileSystem**  | returns an object containing folders and files |

***
***

## **KeyBase Encryption cmdlets 1.0.2**

***
| cmdlet                 | Description
| :--------------------- | :---------------- |
| **Add-PSKEncryption** | Encrypts a specified file or all files in a specified directory |
| **Remove-PSKEncryption** | Decrypts a specified file or all files in a specified directory |
| **Set-PSKPassPhrase** | Return a 20 character random token |
| **Test-PSKPrivilege** | Returns true if the current process is running with elevated privilege |
| **Install-PSKGnuPg** | Installs the GNU Privacy Guard application for Windows or Linux |

The **Keybase encryption cmdlets** are new with version 1.0.2.

To upgrade **git clone keybase://team/psmodules/PSKeyBase** to a local directory and copy the *.md, *.psd1, and *.psm1 files to your PSKeyBase module installation folder.

The basic goal is to encrypt a file or files and have the decryption token maintained in the Keybase KV store.

## Add-PSKEncryption 1.0.8

``` pwsh
PS> Add-PSKEncryption -FolderPath test.log

OutPut:
NameSpace                  Team              entryKey                Revison
---------                  ----              --------                -------
TOOLAH-File (749e6f001f41) dayton,dayton     test.log (68a941536733)       1

Encrypt a file within the current working directory and store the decryption token in the KeyBase KV store.

After the file is successfully encrypted, the uncrypted version is removed.

A random decryption token is generated. (Default 20 characters)

The KVstore namespace value will be "<hostname>-File" and the key will be "test.log"
as shown in the command output.

On version 1.0.8, -NoKB option bypasses the need for the Keybase client and optionally
prompts for a manual passphrase input.

```

## Remove-PSKEncryption

``` pwsh
PS> Remove-PSKEncryption -FolderPath test.log.gpg

Output:
    Decrypting C:\myfolder\test.log.gpg to C:\myfolder\test.log (Y or N) : Y
    KV test.log (b388d70f1c63) removed in NameSpace: TOOLAH-File (6ed05cb2d822)

Prompts for confirmation to decrypt the file and then retrieves the decryption token from the Keybase KV store
unless the -NoKB option is set.

Using the -NoKB options requires manual input of the decrypt token

The encrypted file, test.log.gpg is removed.

If the option, '-Keep' was used above then the encrypted file will not be removed.
```

Execute the cmdlet, **Install-PSKGnuPg**, if the installation of the GNU Privacy Guard application is missing.

More details can be reviewed by executing Get-Help for each of the cmdlets.

I've only tested on Windows and Linux, but it should work on the MacOS too.

***
***
## **Installation of PSKeyBase**

This module can be installed by downloading the installation script [Install PSKeyBase](https://cadayton.onrender.com/scripts/Install-PSKeyBase.ps1) or by following the instructions below.

This module requires the installation of the **KeyBase** and **Git** software on the client.

I strongly recommend using the **Install PSKeyBase** link above to download the script, **Install-PKKeyBase.ps1** because it will verify all
dependencies are in place and install any other PowerShell module dependencies. If you are looking to just download the code for review, continue with the process outlined in the manual installation section below.

***

## **KeyBase KVstore Explorer**

![KV-Explorer](https://cadayton.onrender.com/scripts/KV-Explorer.png)

Executing the command, **KV-Explorer** (Show-PSKNameSpaceHash) will display a Grid View table showing the namespace/entryKey pairs within the specified KeyBase team.

The value shown in parathensis is the encoded metadata value that is stored on the KeyBase server. The unencoded value is only seen by the KeyBase client.

If you are using multiple KeyBase clients on different workstations, the data presented will be the same because the clients populate the hashtable from files that are maintained in the KeyBase filesystem.

The file, **KBnamespace.xml** is stored in the /keybase/private/keybaseID folder.  When the client makes changes the data is updated locally and synch'ed with the above keybase folder.  Synchronization with the Keybase filesystem is the default, but can be overriden by changing the configuration file.  See **Set-PSKConfiguration**.

For teams the file, **KBnamespace-teamname.xml** is stored in the /keybase/team/teamname folder.

By using the down/up arrows and the space bar, one can select a specific entry for operations.

After making a selection, press the **Enter** key to display the operations Grid-View.

![KV Operations](https://cadayton.onrender.com/scripts/KV-Operations.png)

The last 2 options **Add** and **Plain** create a new key/value pairing.  The **Plain** is available should you desire to not have the metadata encoded.

***
***

## **KeyBase FileSystem Explorer**

![KB-Explorer](https://cadayton.onrender.com/scripts/KB-Explorer.png)

Executing the command **KB-Explorer** (Show-PSKFileSystem) will display a Grid View table showing the folders and files within the specified KeyBase filesystem.

The title line displays the current path being referenced along with the available capacity in the KeyBase filesystem.

The **Filter** box is used for filtering the displayed content.

To navigate through the KeyBase directory structure, select a **DIR** record by using the arrow keys and the space bar. When the value **return** appears in the list, it can be selected to return to the parent folder.  After making a selected, press the enter key.

When a file is selected, the options to **'Copy, Remove, View, Run, or Execute'** will be presented. The **Run** option is currently only available when selecting a PowerShell script file with a '.ps1' extension.

***
***

## **Manual Installation of PSKeyBase**

Join the KeyBase **PSKeyBase** team

Download the **PSKeyBase** module

``` pwsh
git clone keybase://team/psmodules/PSKeyBase
```

The environmental variable '$env:PSModulePath' controls where the server will look for PowerShell modules.  My recommendation is to create new folder for your personal PowerShell modules and update the PSModulePath variable to include a reference this new folder.

Copy the folder created by 'git clone' to a folder location referenced in $env:PSModulePath. At a minimum the folder should have the follow files.

``` pwsh
PSKeyBase
PSKeyBase.psd1
PSKeyBase.psm1
PSKeyBase-cfg.xml
```

To verify that PowerShell 7 has recognized this module, start a NEW PowerShell console session and enter the following command.

``` pwsh
Get-Command -module PSKeyBase.
```

This should produce the following output.

    CommandType     Name                                               Version    Source
    -----------     ----                                               -------    ------
    Alias           KB-Explorer                                        1.0.8      PSKeyBase
    Alias           KV-EntryValue                                      1.0.8      PSKeyBase
    Alias           KV-Explorer                                        1.0.8      PSKeyBase
    Function        Add-PSKEncryption                                  1.0.8      PSKeyBase
    Function        Get-PSKCapacity                                    1.0.8      PSKeyBase
    Function        Get-PSKentryKeys                                   1.0.8      PSKeyBase
    Function        Get-PSKEntryValue                                  1.0.8      PSKeyBase
    Function        Get-PSKFileSystem                                  1.0.8      PSKeyBase
    Function        Get-PSKNameSpaces                                  1.0.8      PSKeyBase
    Function        Install-PSKGnuPg                                   1.0.8      PSKeyBase
    Function        Remove-PSKEncryption                               1.0.8      PSKeyBase
    Function        Remove-PSKentryKey                                 1.0.8      PSKeyBase
    Function        Set-PSKConfiguration                               1.0.8      PSKeyBase
    Function        Set-PSKEntryValue                                  1.0.8      PSKeyBase
    Function        Set-PSKPassPhrase                                  1.0.8      PSKeyBase
    Function        Show-PSKCapacity                                   1.0.8      PSKeyBase
    Function        Show-PSKEntryValue                                 1.0.8      PSKeyBase
    Function        Show-PSKFileSystem                                 1.0.8      PSKeyBase
    Function        Show-PSKNameSpaceHash                              1.0.8      PSKeyBase

The final step is to set the configuraton for your environment by executing the cmdlet.

``` pwsh
Set-PKSConfiguration
```

This command will update the file, **PSKeyBase-cfg.xml** located in the module root folder.

| variable      | Defaut        | Description
| :------------ | :----------   | :----------
| KEYBASE_BIN   | **none**      | Binary path location of the Keybase executable
| KEYBASE_TM    | KBID,KBID     | KeyBase ID is the default team name.
| KEYBASE_NS    | Namespace     | Default namespace value to use.
| KEYBASE_FP    | module folder | Path location for hashtable files
| KEYBASE_SYN   | sync          | Sync hashtable files with Keybase filesystem

***
***
