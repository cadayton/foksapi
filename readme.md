# FoksApi

A PowerShell script to provide a programmatic interface to [FOKS](https://foks.pub/).

All associated software is beta mode so only use it for testing purposes.

Review [FOKS](https://foks.pub/) to get information on it's implementation.

This script is focused on using **End-to-End Post-Quantum Encrypted Key-Value Store** feature.

## FoksApi Overview

The primary focus is to provide programmatic access to the key/value store functionality
implemented by FOKS. Currently, the foks command line interface is being used with the
thought of migrating to a REST Api as some future date.

To follow the examples below, you'll a working version of FOKS and PowerShell installed.
The script has been develop and tested on Linux in an OS neutral manner so should be working
on all OSes.

## FoksApi Operations

    KeyPaths       - Generate a list of current key/value pairs
    FindPaths      - List keys matching search expression
    Create         - Create a key/value pair
    Get            - Copy the value of a key/value pair to the clipboard
    Update         - Update a key/value pair with a new value
    Remove         - Remove a key/value pair
    Lock           - Require a passphrase to unlock FOKS
    Usage          - Display Server Usage Info
    passPhrase     - Set, Change, or Unlock the passphrase 
    SetRandomValue - Random 20 char passphrase created in the clipboard
    Usage          - Display Server Usage Info

***

## Creating a key/value Entry

  ```
  PS> FoksApi Create /myfirst/love dontkissandtell
  Created /myfirst/love/
  ```

  By default the last item name in the path is the key. If it is desired to have a different key name associated with the path, then the '-kvkey' parameter can be used.

  ```
  PS> FoksApi Create -kvpath /myfirst -kvalue dontkissandtell -kvkey love
  ```

  This command is yeilds the same results as the prior example.

  If the value has embedded spaces or characters that need to be escaped, then the value should be in single quotation marks.
  ***
## Updating key/value Entry

  ```
  PS> FoksApi Update /myfirst/love Traci   
  Updated /myfirst/love/
  ```

  Lets update the value with a 20 character randomized value

  ```
  PS> FoksApi Update /myfirst/love SetRandomValue
  Updated /myfirst/love/
  ```
***

## Retreiving a value from a key/value Entry

  ```
  PS> FoksApi Get /myfirst/love
  ```

  The associated value is copied to the clipboard.
***

## Review existing key/value Entries

  Once one has a large collection of key/value pairs, there is easy way to list your key/value entries.

  ```
  PS> FoksApi KeyPaths
  $HOME/FoksPaths.txt new file created
  ```

  The file generated is a dump of all the current key/value pairs.

  To list all key/value pairs to the console.

  ```
  PS> FoksApi FindPaths
  ```

  To search for specific paths

  ```
  PS> FoksApi FindPaths myfirst
  /myfirst/love
  ```
***

## Securing the FOKS implementation

  Once the FOKS system is no longer being actively used, it is wise to lock down FOKS with a passPhrase to keep it secure.

  Set a passphrase for FOKS. **Note the example below is using the foks cli.**

  ```
  foks passphrase set
  ```

  **Don't lose your passphrase**

  A secure passphrase can be generated as follows:

  ```
  FoksApi SetRandomValue
  ```

  The generated random value is copied to the clipboard.

  Enter the follow command to lock the FOKS implementation.

  ```
  PS> FoksApi Lock
  ```

  On each execution of FoksApi, it will check if FOKS is locked and prompt for a passphrase to unlock.

***

