# Public failure evidence is a fixed vocabulary, never raw guest/tool output.
function Get-HostedDiagnosticSignals {
    param([object[]]$Records)
    $signals=@();$instance='';$launch='';$base='';$baseFile=''
    foreach($record in $Records){
        $line=[string]$record.Text
        $baseLine=$false
        if($line -cmatch '^BASE_LOG_TAIL=.+[\\/]runtime[\\/]bases[\\/]\.build-(?<build>[a-f0-9]{32})[\\/](?<file>failure\.json|serial\.log); bytes<=262144; lines<=200$'){
            $base=$Matches.build;$baseFile=$Matches.file;$instance='';$launch='';continue
        }elseif($line.StartsWith('BASE_LOG_TAIL=',[StringComparison]::Ordinal)){
            $base='';$baseFile='';$instance='';$launch='';continue
        }elseif($line.StartsWith('BASE_LOG_LINE=',[StringComparison]::Ordinal)){
            if(-not $base -or $line.Length -gt 8192){continue}
            # Unwrap only a local diagnostic copy. The host marker oracle still
            # receives the original BASE_LOG_LINE prefix, never guest markers.
            $line=$line.Substring(14);$baseLine=$true
            if($baseFile -ceq 'failure.json'){
                if($line -cmatch '^\s*"message"\s*:\s*(?<json>"(?:[^"\\]|\\.)*")\s*,?\s*$'){
                    try{$decoded=('{"message":'+$Matches.json+'}')|ConvertFrom-Json;$line=[string]$decoded.message}catch{continue}
                }else{continue}
            }
        }elseif($line -cmatch '^LOG_TAIL=.+[\\/]runtime[\\/]instances[\\/](?<instance>[a-z0-9-]{1,63})[\\/]logs[\\/]serial-(?<launch>[a-f0-9]{32})\.log; lines=[0-9]+$'){
            $base='';$baseFile=''
            $instance=$Matches.instance;$launch=$Matches.launch
            if(@('ezvm010-source','ezvm010-stateful','ezvm010-imported','ezvm012-secondary','ezvm012-fresh') -cnotcontains $instance){$instance='';$launch=''}
        }elseif($line.StartsWith('LOG_TAIL=',[StringComparison]::Ordinal) -or $line.StartsWith('STATE_FILE=',[StringComparison]::Ordinal)){
            $instance='';$launch=''
            $base='';$baseFile=''
        }
        $code='';$exitCode='';$stage='';$validationExit=$null;$timeout=$null;$seedRequests=$null
        if($baseLine -and $baseFile -ceq 'failure.json' -and $line -cmatch '^Prepared-base guest provisioning exceeded its (?<limit>[0-9]{1,5}) second timeout\. Seed requests handled: (?<requests>[0-9]{1,7}); paths:'){
            if([int]$Matches.limit -ge 30 -and [int]$Matches.limit -le 86400 -and [int]$Matches.requests -le 1000000){$code='base-provisioning-deadline';$timeout=[int]$Matches.limit;$seedRequests=[int]$Matches.requests}
        }elseif($baseLine -and $baseFile -ceq 'failure.json' -and $line -ceq 'Guest baseline validation failed: cloud-init did not reach successful completion'){$code='base-cloud-init-failed'}
        elseif($baseLine -and $baseFile -ceq 'failure.json' -and $line.StartsWith('Guest baseline validation failed: missing commands:',[StringComparison]::Ordinal)){$code='base-required-tools-missing'}
        elseif($baseLine -and $baseFile -ceq 'failure.json' -and $line.StartsWith('Guest baseline validation failed:',[StringComparison]::Ordinal)){$code='base-guest-validation-failed'}
        elseif($baseLine -and $baseFile -ceq 'failure.json' -and $line -cmatch '^QEMU exited with code -?[0-9]{1,10} before a prepared base could be accepted\. '){$code='base-qemu-exit-failed'}
        elseif($line -cmatch '^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing: Attempted to kill init! exitcode=(?<exit>0x[0-9a-fA-F]{8})\s*$'){
            $code='guest-init-kernel-panic';$exitCode=$Matches.exit.ToLowerInvariant()
        }elseif($line -cmatch '^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing:'){$code='guest-kernel-panic'}
        elseif($line -cmatch '(?:EZVM_VENV_VALIDATION_FAILURE stage=|Python venv with pip is unavailable or exceeded its 90 second validation deadline \(stage=)(?<stage>create|prefix|pip|setup) exit=(?<status>[0-9]{1,3})(?:\)|\s|$)'){
            if([int]$Matches.status -le 255){$code='guest-venv-validation-failed';$stage=$Matches.stage;$validationExit=[int]$Matches.status}
        }
        elseif($line -cmatch 'Python venv with pip is unavailable or exceeded its 90 second validation deadline'){$code='guest-venv-validation-failed'}
        elseif($line -cmatch '^RUNLOC_POWERSHELL_ENTRY_FAILURE=Instance .+ did not reach authenticated SSH READY within [0-9]+ seconds\.'){$code='authenticated-ready-deadline'}
        elseif($line -cmatch '^EZVM010_GRACEFUL_CLEANUP_ERROR=.+runtime state remains STOPPING\.$'){$code='graceful-stop-unconfirmed'}
        elseif($baseLine -and $baseFile -ceq 'serial.log' -and $line -cmatch 'Temporary failure resolving'){$code='guest-dns-resolution-failed'}
        elseif($baseLine -and $baseFile -ceq 'serial.log' -and $line -cmatch 'No space left on device'){$code='guest-storage-full'}
        elseif($baseLine -and $baseFile -ceq 'serial.log' -and $line -cmatch '^EZVM_BASE_READY=1\s*$'){$code='base-ready-text-observed'}
        elseif($baseLine -and $baseFile -ceq 'serial.log' -and $line -cmatch '^EZVM_BASE_FAILURE_B64=[A-Za-z0-9+/=]{1,4096}\s*$'){$code='base-failure-text-observed'}
        $utc=[string]$record.Utc
        if($utc -cnotmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,7})?Z$'){$utc=''}
        if($code -and $signals.Count -lt 64){$signals+=@{code=$code;instance=$instance;launchId=$launch;guestExitCode=$exitCode;validationStage=$stage;validationExitCode=$validationExit;utc=$utc;
            baseBuildId=$(if($baseLine){$base}else{''});timeoutSeconds=$timeout;seedRequestCount=$seedRequests}}
    }
    return ,$signals
}

function Get-HostedDiagnosticCoverage {
    param([object[]]$Records)
    $headers=0;$lines=0;$truncated=0
    foreach($record in $Records){
        $text=[string]$record.Text
        if($text -cmatch '^BASE_LOG_TAIL=.+[\\/]runtime[\\/]bases[\\/]\.build-[a-f0-9]{32}[\\/](failure\.json|serial\.log); bytes<=262144; lines<=200$'){$headers++}
        if($text.StartsWith('BASE_LOG_LINE=',[StringComparison]::Ordinal)){
            $lines++
            if($text.EndsWith(' [diagnostic line truncated]',[StringComparison]::Ordinal)){$truncated++}
        }
    }
    return @{recordsAvailable=(@($Records).Count -gt 0);baseCapture=$(if($headers -gt 0){'observed'}else{'not-observed'});
        baseSectionCount=$headers;baseLineCount=$lines;lineTruncationCount=$truncated;boundedTailsOnly=$true;signalLimit=64}
}
