$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$protoRoot = $PSScriptRoot
$protoRootSGT = Join-Path $protoRoot "sgt"
$protoRootServices = Join-Path $protoRoot "services"

$outPath = Join-Path $env:git_root_csharp "models"

#*********************************
#iterate models and generate
gci $protoRootSgt -r | ? { $_.Extension -eq ".proto" } | % {
    Write-Host -NoNewline "Generating $($_.FullName)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    protoc.exe ($_.FullName | Resolve-Path -Relative) --csharp_out $outPath --csharp_opt=base_namespace
    Write-Host "    $($sw.ElapsedMilliseconds)ms"
}

#*********************************
#iterate services and generate
gci $protoRootServices -r | ? { $_.Extension -eq ".proto" } | % {
    Write-Host -NoNewLine "Generating $($_.FullName)"
    $serviceName = $_.BaseName.Substring(0,1).ToUpper() + $_.BaseName.Substring(1)
    $outPathService = Join-Path (Join-Path $outPath "Services") $serviceName
    if(!(Test-Path $outPathService)){ New-Item $outPathService -type directory }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    protoc.exe ($_.FullName | Resolve-Path -Relative) --csharp_out $outPathService --grpc_out $outPathService --plugin=protoc-gen-grpc=$env:grpc_plugin_path
    Write-Host "    $($sw.ElapsedMilliseconds)ms"
}