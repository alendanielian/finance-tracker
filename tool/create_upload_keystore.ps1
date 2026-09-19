[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$keystorePath = Join-Path $projectRoot 'android\app\upload-keystore.jks'
$propertiesPath = Join-Path $projectRoot 'android\key.properties'

if (-not (Test-Path -LiteralPath $keytool)) {
    throw "keytool not found: $keytool"
}
if (Test-Path -LiteralPath $keystorePath) {
    throw "Keystore already exists: $keystorePath"
}
if (Test-Path -LiteralPath $propertiesPath) {
    throw "Signing properties already exist: $propertiesPath"
}

Write-Host 'Creating the Finance Tracker upload keystore.'
Write-Host 'Passwords are entered directly into keytool and are not shown.'
Write-Host 'When asked for the key password, press Enter to reuse the store password.'
Write-Host ''

$keytoolArguments = @(
    '-genkeypair'
    '-v'
    '-keystore', $keystorePath
    '-storetype', 'JKS'
    '-keyalg', 'RSA'
    '-keysize', '2048'
    '-validity', '10000'
    '-alias', 'upload'
)
& $keytool @keytoolArguments

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host 'Re-enter the same password once so Gradle can use the keystore.'
$securePassword = Read-Host 'Keystore password' -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
    $securePassword
)

try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
        $passwordPointer
    )
    if ($plainPassword.Length -lt 6) {
        throw 'The password must contain at least 6 characters.'
    }

    # Java properties treat backslashes as escape characters.
    $propertiesPassword = $plainPassword.Replace('\', '\\')
    $properties = @(
        "storePassword=$propertiesPassword"
        "keyPassword=$propertiesPassword"
        'keyAlias=upload'
        'storeFile=upload-keystore.jks'
        ''
    ) -join [Environment]::NewLine

    [IO.File]::WriteAllText(
        $propertiesPath,
        $properties,
        [Text.UTF8Encoding]::new($false)
    )
}
finally {
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
    $plainPassword = $null
    $propertiesPassword = $null
}

Write-Host ''
Write-Host 'Created:'
Write-Host "  $keystorePath"
Write-Host "  $propertiesPath"
Write-Host 'Both files are ignored by Git.'
