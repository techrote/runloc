function Get-TimerProbeArguments {
    param([ValidateSet('default','off')][string]$Hpet,[string]$Image,[string]$FirmwareCode,[string]$FirmwareVariables,[string]$SerialLog)
    # Both controls retain APIC, six vCPUs, memory and the same fresh source disk.
    # No guest kernel option disables its timer validation.
    return @('-name','runloc-timer-diagnostic','-machine',$(if($Hpet -ceq 'off'){'q35,hpet=off'}else{'q35'}),
        '-accel','tcg,thread=multi','-cpu','max','-smp','6','-m','4096','-display','none','-monitor','none',
        '-serial',('file:'+$SerialLog),'-drive',('if=pflash,format=raw,readonly=on,file='+$FirmwareCode),
        '-drive',('if=pflash,format=raw,file='+$FirmwareVariables),'-drive',('if=none,id=osdisk,format=qcow2,file='+$Image),
        '-device','virtio-blk-pci,drive=osdisk,bootindex=0','-netdev','user,id=net0,ipv6=off,restrict=on',
        '-device','virtio-net-pci,netdev=net0','-boot','order=c,strict=on','-rtc','base=utc',
        '-snapshot','-no-user-config','-nodefaults','-no-reboot')
}
function Get-TimerProbeSignals {
    param([string]$Text)
    $panic=$Text -cmatch '(?m)^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing:'
    $ioApic=$Text -cmatch '(?m)^\[\s*[0-9]+\.[0-9]+\]\s+Kernel panic - not syncing: IO-APIC \+ timer doesn''t work!'
    $cpu6=$Text -cmatch '(?m)^\[\s*[0-9]+\.[0-9]+\]\s+(?:smp: Brought up 1 node, 6 CPUs|SMP: Total of 6 processors activated)'
    $init=$Text -cmatch '(?m)^\[\s*[0-9]+\.[0-9]+\]\s+Run /(?:sbin/)?init as init process'
    $kernel=[regex]::Match($Text,'(?m)^\[\s*[0-9]+\.[0-9]+\]\s+Linux version ([^\s]+)')
    return @{kernelVersion=$kernel.Groups[1].Value;kernelPanic=$panic;ioApicTimerPanic=$ioApic;kernelSixCpuObserved=$cpu6;kernelInitObserved=$init;earlyBootObserved=($cpu6 -and $init -and -not $panic)}
}

function Read-TimerProbeSerial {
    param([string]$Path)
    if(-not [IO.File]::Exists($Path)){return ''}
    $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try{
        if($stream.Length -gt 2097152){throw 'timer-probe-serial-limit'}
        $buffer=New-Object byte[] 2097153
        $count=0
        while($count -lt $buffer.Length){$read=$stream.Read($buffer,$count,$buffer.Length-$count);if($read -eq 0){break};$count+=$read}
        if($count -gt 2097152){throw 'timer-probe-serial-limit'}
        return [Text.Encoding]::UTF8.GetString($buffer,0,$count)
    }finally{$stream.Dispose()}
}
