# Public failure evidence is a fixed vocabulary, never raw guest/tool output.
function Get-HostedDiagnosticSignals {
    param([object[]]$Records)
    $signals=@();$instance='';$launch=''
    foreach($record in $Records){
        $line=[string]$record.Text
        if($line -cmatch '^LOG_TAIL=.+[\\/]runtime[\\/]instances[\\/](?<instance>[a-z0-9-]{1,63})[\\/]logs[\\/]serial-(?<launch>[a-f0-9]{32})\.log; lines=[0-9]+$'){
            $instance=$Matches.instance;$launch=$Matches.launch
            if(@('ezvm010-source','ezvm010-stateful','ezvm010-imported','ezvm012-secondary','ezvm012-fresh') -cnotcontains $instance){$instance='';$launch=''}
        }elseif($line.StartsWith('LOG_TAIL=',[StringComparison]::Ordinal) -or $line.StartsWith('STATE_FILE=',[StringComparison]::Ordinal)){
            $instance='';$launch=''
        }
        $code='';$exitCode='';$stage='';$validationExit=$null
        if($line -cmatch '^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing: Attempted to kill init! exitcode=(?<exit>0x[0-9a-fA-F]{8})\s*$'){
            $code='guest-init-kernel-panic';$exitCode=$Matches.exit.ToLowerInvariant()
        }elseif($line -cmatch '^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing:'){$code='guest-kernel-panic'}
        elseif($line -cmatch '(?:EZVM_VENV_VALIDATION_FAILURE stage=|Python venv with pip is unavailable or exceeded its 90 second validation deadline \(stage=)(?<stage>create|prefix|pip|setup) exit=(?<status>[0-9]{1,3})(?:\)|\s|$)'){
            if([int]$Matches.status -le 255){$code='guest-venv-validation-failed';$stage=$Matches.stage;$validationExit=[int]$Matches.status}
        }
        elseif($line -cmatch 'Python venv with pip is unavailable or exceeded its 90 second validation deadline'){$code='guest-venv-validation-failed'}
        elseif($line -cmatch '^RUNLOC_POWERSHELL_ENTRY_FAILURE=Instance .+ did not reach authenticated SSH READY within [0-9]+ seconds\.'){$code='authenticated-ready-deadline'}
        elseif($line -cmatch '^EZVM010_GRACEFUL_CLEANUP_ERROR=.+runtime state remains STOPPING\.$'){$code='graceful-stop-unconfirmed'}
        $utc=[string]$record.Utc
        if($utc -cnotmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,7})?Z$'){$utc=''}
        if($code -and $signals.Count -lt 64){$signals+=@{code=$code;instance=$instance;launchId=$launch;guestExitCode=$exitCode;validationStage=$stage;validationExitCode=$validationExit;utc=$utc}}
    }
    return ,$signals
}
