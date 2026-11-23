param(
    [string]$AndroidSdk = $env:ANDROID_SDK_ROOT,
    [string]$Jdk = $env:JAVA_HOME,
    [string]$KeyStore = '.build/meiyitian-signing.p12',
    [string]$KeyAlias = 'meiyitian',
    [string]$ExpectedCertificateSha256,
    [string]$OutputApk = 'build/meiyitian.apk',
    [switch]$CreateSigningKey
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$KeyStore = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($KeyStore)
$OutputApk = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputApk)
if (!$AndroidSdk -or !$Jdk) { throw 'Set ANDROID_SDK_ROOT and JAVA_HOME, or pass -AndroidSdk and -Jdk.' }
if (!$env:MEIYITIAN_KEY_PASSWORD) { throw 'Set MEIYITIAN_KEY_PASSWORD in the current shell.' }
$env:JAVA_HOME = $Jdk
$toolsDir = Join-Path $AndroidSdk 'build-tools/35.0.1'
$androidJar = Join-Path $AndroidSdk 'platforms/android-35/android.jar'

function Invoke-BuildTool([string]$Path, [string[]]$Arguments) {
    & $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Build tool failed: $Path ($LASTEXITCODE)" }
}

if (!(Test-Path -LiteralPath $KeyStore)) {
    if (!$CreateSigningKey) { throw 'Signing key missing. Restore the original key for an upgrade, or pass -CreateSigningKey for a new installation.' }
    $keyParent = Split-Path -Parent ([IO.Path]::GetFullPath($KeyStore))
    New-Item -ItemType Directory -Force $keyParent | Out-Null
    Invoke-BuildTool "$Jdk/bin/keytool.exe" @('-genkeypair','-keystore',$KeyStore,'-storetype','PKCS12','-alias',$KeyAlias,'-storepass:env','MEIYITIAN_KEY_PASSWORD','-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=Meiyitian')
}
$work = Join-Path '.build' ('apk-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force "$work/classes","$work/dex" | Out-Null
Invoke-BuildTool "$toolsDir/aapt2.exe" @('compile','--dir','app/res','-o',"$work/resources.zip")
Invoke-BuildTool "$toolsDir/aapt2.exe" @('link','-I',$androidJar,'--manifest','app/AndroidManifest.xml','-A','app/assets','-o',"$work/base.apk","$work/resources.zip")
$source = @(Get-ChildItem app/src -Filter '*.java' -Recurse | ForEach-Object FullName)
Invoke-BuildTool "$Jdk/bin/javac.exe" (@('--release','8','-encoding','UTF-8','-cp',$androidJar,'-d',"$work/classes") + $source)
$classes = @(Get-ChildItem "$work/classes" -Filter '*.class' -Recurse | ForEach-Object FullName)
Invoke-BuildTool "$toolsDir/d8.bat" (@('--min-api','23','--lib',$androidJar,'--output',"$work/dex") + $classes)
Invoke-BuildTool "$Jdk/bin/jar.exe" @('uf',"$work/base.apk",'-C',"$work/dex",'classes.dex')
Invoke-BuildTool "$toolsDir/zipalign.exe" @('-f','4',"$work/base.apk","$work/aligned.apk")
Invoke-BuildTool "$toolsDir/apksigner.bat" @('sign','--ks',$KeyStore,'--ks-key-alias',$KeyAlias,'--ks-pass','env:MEIYITIAN_KEY_PASSWORD','--out',"$work/signed.apk","$work/aligned.apk")
$certificate = Invoke-BuildTool "$toolsDir/apksigner.bat" @('verify','--print-certs',"$work/signed.apk")
$certificate | Write-Output
if ($ExpectedCertificateSha256) {
    $expected = $ExpectedCertificateSha256.Replace(':','').Trim()
    if (!($certificate | Where-Object { $_ -match ('certificate SHA-256 digest: '+[regex]::Escape($expected)+'$') })) {
        throw 'APK certificate differs from the expected upgrade certificate.'
    }
}
New-Item -ItemType Directory -Force (Split-Path -Parent ([IO.Path]::GetFullPath($OutputApk))) | Out-Null
Copy-Item -LiteralPath "$work/signed.apk" -Destination $OutputApk -Force
Write-Output "APK: $([IO.Path]::GetFullPath($OutputApk))"

