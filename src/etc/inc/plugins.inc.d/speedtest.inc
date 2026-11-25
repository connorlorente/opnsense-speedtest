<?php

function speedtest_cron()
{
    $jobs = [];
    $general = (new \OPNsense\Speedtest\Speedtest())->general;
    if ((string)$general->enabled === '1') {
        $n = max(1, min(24, (int)(string)$general->interval_hours));
        $hour = $n >= 24 ? '3' : '*/' . $n;
        $jobs[]['autocron'] = ['/usr/local/sbin/configctl speedtest start', '7', $hour];
    }
    return $jobs;
}
