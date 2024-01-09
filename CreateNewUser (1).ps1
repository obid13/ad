function TranslitToLAT {
    param([string]$inString)
    $Translit_To_LAT = @{
        [char]'а' = "a"
        [char]'А' = "a"
        [char]'б' = "b"
        [char]'Б' = "b"
        [char]'в' = "v"
        [char]'В' = "v"
        [char]'г' = "g"
        [char]'Г' = "g"
        [char]'д' = "d"
        [char]'Д' = "d"
        [char]'е' = "e"
        [char]'Е' = "e"
        [char]'ё' = "e"
        [char]'Ё' = "e"
        [char]'ж' = "zh"
        [char]'Ж' = "zh"
        [char]'з' = "z"
        [char]'З' = "z"
        [char]'и' = "i"
        [char]'И' = "i"
        [char]'й' = "i"
        [char]'Й' = "i"
        [char]'к' = "k"
        [char]'К' = "k"
        [char]'л' = "l"
        [char]'Л' = "l"
        [char]'м' = "m"
        [char]'М' = "m"
        [char]'н' = "n"
        [char]'Н' = "n"
        [char]'о' = "o"
        [char]'О' = "o"
        [char]'п' = "p"
        [char]'П' = "p"
        [char]'р' = "r"
        [char]'Р' = "r"
        [char]'с' = "s"
        [char]'С' = "s"
        [char]'т' = "t"
        [char]'Т' = "t"
        [char]'у' = "u"
        [char]'У' = "u"
        [char]'ф' = "f"
        [char]'Ф' = "f"
        [char]'х' = "kh"
        [char]'Х' = "kh"
        [char]'ц' = "ts"
        [char]'Ц' = "ts"
        [char]'ч' = "ch"
        [char]'Ч' = "ch"
        [char]'ш' = "sh"
        [char]'Ш' = "sh"
        [char]'щ' = "shch"
        [char]'Щ' = "shch"
        [char]'ъ' = "ie" # "``"
        [char]'Ъ' = "ie" # "``"
        [char]'ы' = "y" # "y`"
        [char]'Ы' = "y" # "Y`"
        [char]'ь' = "" # "`"
        [char]'Ь' = "" # "`"
        [char]'э' = "e" # "e`"
        [char]'Э' = "e" # "E`"
        [char]'ю' = "iu"
        [char]'Ю' = "iu"
        [char]'я' = "ia"
        [char]'Я' = "ia"
        [char]' ' = " "
        }
    $outChars=""
    foreach ($c in $inChars = $inString.ToCharArray()) {
        if ($Translit_To_LAT[$c] -cne $Null ) {
            $outChars += $Translit_To_LAT[$c]
            }
        else {
            $outChars += $c
            }
        }
        $outChars = $outChars.Substring(0,1).ToUpper() + $outChars.Substring(1).ToLower()
        Write-Output $outChars
        }

do {$FirstName = Read-Host "Enter firstname"} while([string]::IsNullOrWhiteSpace($FirstName))
$FirstName = TranslitToLAT $FirstName
do {$LastName = Read-Host "Enter lastname"} while([string]::IsNullOrWhiteSpace($LastName))
$LastName = TranslitToLAT $LastName
do {$surname = Read-Host "Enter surname"} while([string]::IsNullOrWhiteSpace($surname))
$surname = TranslitToLAT $surname
do {$Department = Read-Host "Enter department"} while([string]::IsNullOrWhiteSpace($Department))
do {$JobTitle = Read-Host "Enter job title"} while([string]::IsNullOrWhiteSpace($JobTitle))


function Generate-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length
    )
 
    $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$%!@^&()'.ToCharArray()
 
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
  
    $rng.GetBytes($bytes)
  
    $result = New-Object char[]($length)
  
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
    }
 
    return -join $result
}

function CreateUser {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FirstName,

        [Parameter(Mandatory=$true)]
        [string]$LastName,

        [Parameter(Mandatory=$true)]
        [string]$surname,

        [Parameter(Mandatory=$true)]
        [string]$Department,

        [Parameter(Mandatory=$true)]
        [string]$JobTitle
        )
    
    $OU = "OU=EnabledUsers,OU=Staff,DC=corp,DC=loc"
    $SAN = $FirstName.Substring(0,1).ToLower()+$LastName.ToLower()
    $index = 1
    while ((Get-ADUser -Filter "samaccountname -eq '$SAN'") -ne $null) {
        $index++
        $SAN = $FirstName.Substring(0,$index).ToLower()+$LastName.ToLower()
        }
    $name = $FirstName + " " + $LastName
    If (Get-ADUser -Filter "name -eq '$name'") {
        $name = $LastName + " " + $FirstName + " " + $surname
        }
    If (Get-ADUser -Filter "name -eq '$name'") {
        $name = $FirstName + " " + $surname + " " + $LastName
        }
    $passw_p = Generate-RandomPassword 14
    $passw_s = $passw_p | ConvertTo-SecureString -AsPlainText -Force

    New-ADUser -Name $name -DisplayName $name -SamAccountName $SAN -UserPrincipalName "$SAN@avo.uz" -AccountPassword $passw_s  -Enabled:$true `
        -GivenName $FirstName -Surname $LastName -Department $Department -Title $JobTitle -EmailAddress "$SAN@avo.uz" `
        -ChangePasswordAtLogon:$true -Path $OU -PassThru

    Add-ADGroupMember -Identity AD-AzureAD-Sync -Members $SAN
    Add-ADGroupMember -Identity AzureMFA-Enabled-ONPREM -Members $SAN
    Add-ADGroupMember -Identity License_MS365_E3 -Members $SAN

    "login: corp\$SAN"
    "UPN: $SAN@avo.uz"
    "Password: $passw_p"

    }

CreateUser -FirstName $FirstName -LastName $LastName -surname $surname -Department $Department -JobTitle $JobTitle