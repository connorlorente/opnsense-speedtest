/* Shared by the Speed Test page and the dashboard widget (classic script, also importable as a module). */
window.speedtestGauges = function (s) {
    var C = 2 * Math.PI * 40, ARC = 0.75 * C;  // 270 degree gauge

    function gauge(label, value) {
        var known = typeof value === 'number';
        // full scale = the fastest result on record, so no line speed has to be configured
        var frac = known && s.max ? Math.min(value / s.max, 1) : 0;
        var text = known ? String(Math.round(value)) : '-';
        return '<div style="text-align:center;margin:5px 10px" role="img" aria-label="' + label + ': ' + text + ' Mbit/s">' +
            '<svg viewBox="0 0 100 100" width="110" height="110" fill="none" stroke-width="9" stroke-linecap="round">' +
            '<circle cx="50" cy="50" r="40" stroke="rgba(128,128,128,0.25)" transform="rotate(135 50 50)" stroke-dasharray="' + ARC + ' ' + C + '"/>' +
            '<circle cx="50" cy="50" r="40" stroke="#a4cf7a" transform="rotate(135 50 50)" stroke-dasharray="' + (ARC * frac) + ' ' + C + '"/>' +
            '<text x="50" y="56" text-anchor="middle" font-size="18" font-weight="bold" fill="currentColor">' + text + '</text>' +
            '</svg><div><b>' + label + '</b></div><div>Mbit/s</div></div>';
    }

    return '<div style="display:flex;flex-wrap:wrap;justify-content:center">' +
        gauge('Download', s.down) + gauge('30-day avg down', s.avg_down) +
        gauge('Upload', s.up) + gauge('30-day avg up', s.avg_up) + '</div>';
};
