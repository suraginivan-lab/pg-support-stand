# Pester-тесты: проверяют синтаксис и базовые гарантии скриптов (запуск: Invoke-Pester ./scripts/powershell)
Describe 'PowerShell-скрипты стенда' {
    $scripts = Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' | Where-Object Name -notlike '*.Tests.ps1'

    It '<_.Name> не содержит синтаксических ошибок' -ForEach $scripts {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It 'Sync-PgRolesFromAd поддерживает -WhatIf' {
        (Get-Command (Join-Path $PSScriptRoot 'Sync-PgRolesFromAd.ps1')).Parameters.ContainsKey('WhatIf') | Should -BeTrue
    }
}
