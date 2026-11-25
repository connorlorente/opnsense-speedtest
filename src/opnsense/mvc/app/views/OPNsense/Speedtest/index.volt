<div class="content-box">
    <div id="noCli" class="alert alert-warning" style="display:none">
        Ookla Speedtest CLI is not installed.
        <button id="installBtn" class="btn btn-xs btn-primary">Install</button>
        <span id="installMsg"></span>
    </div>

    <div id="noLicense" class="alert alert-info" style="display:none">
        Tick <b>Accept Ookla terms</b> in Settings below and save before running a test.
    </div>

    <div class="col-xs-12">
        <button id="runBtn" class="btn btn-primary"><i class="fa fa-play fa-fw"></i> Run test</button>
        <span id="runMsg" style="margin-left:10px"></span>
        <hr/>
        <h3>Latest result</h3>
        <div id="latest" class="text-muted">No results yet.</div>
        <hr/>
        <h3>History (Mbit/s)
            <button id="clearBtn" class="btn btn-xs btn-default pull-right">Clear history</button>
        </h3>
        <div id="chart"></div>
        <table class="table table-condensed table-striped" id="hist">
            <thead><tr><th>Time</th><th>Down</th><th>Up</th><th>Ping (ms)</th><th>Jitter (ms)</th><th>Loss (%)</th><th>Server</th><th>ISP</th><th>Interface</th></tr></thead>
            <tbody></tbody>
        </table>
        <hr/>
        <h3>Settings</h3>
        {{ partial("layout_partials/base_form",['fields':settingsForm,'id':'frm_settings']) }}
        <button id="saveBtn" class="btn btn-primary">Save</button>
        <button id="serversBtn" class="btn btn-default">Find servers</button>
        <table class="table table-condensed table-hover" id="servers" style="display:none;margin-top:10px">
            <thead><tr><th>ID</th><th>Name</th><th>Location</th></tr></thead>
            <tbody></tbody>
        </table>
    </div>
</div>

<script>
$(function () {
    var serverField = '[id="speedtest.general.server_id"]';

    function cell(tr, text) { $('<td>').text(text === undefined || text === null ? '' : text).appendTo(tr); }

    function chart(rows) {
        var W = 700, H = 180, P = 30;
        if (rows.length < 2) { $('#chart').text('Not enough data yet.'); return; }
        var max = Math.max.apply(null, rows.map(function (r) { return Math.max(r.down, r.up); })) || 1;
        function pts(k) {
            return rows.map(function (r, i) {
                return (P + i * (W - 2 * P) / (rows.length - 1)).toFixed(1) + ',' +
                       (H - P - (r[k] / max) * (H - 2 * P)).toFixed(1);
            }).join(' ');
        }
        $('#chart').html('<svg viewBox="0 0 ' + W + ' ' + H + '" style="width:100%;max-height:220px">' +
            '<line x1="' + P + '" y1="' + (H - P) + '" x2="' + (W - P) + '" y2="' + (H - P) + '" stroke="#999"/>' +
            '<text x="2" y="' + P + '" font-size="11" fill="#999">' + Math.round(max) + '</text>' +
            '<polyline fill="none" stroke="#d94f00" stroke-width="2" points="' + pts('down') + '"/>' +
            '<polyline fill="none" stroke="#3a7ca5" stroke-width="2" points="' + pts('up') + '"/>' +
            '<text x="' + P + '" y="14" font-size="12" fill="#d94f00">Download</text>' +
            '<text x="' + (P + 90) + '" y="14" font-size="12" fill="#3a7ca5">Upload</text></svg>');
    }

    function loadResults() {
        $.get('/api/speedtest/service/results', function (d) {
            var rows = d.rows || [], tb = $('#hist tbody').empty();
            var good = rows.filter(function (r) { return r.ok; });
            chart(good.slice(-100));
            if (rows.length) {
                var l = rows[rows.length - 1];
                $('#latest').text(l.ok
                    ? 'Down ' + l.down + ' / Up ' + l.up + ' Mbit/s, ping ' + l.ping + ' ms, ' + l.server
                    : 'Last test failed: ' + l.error).removeClass('text-muted');
            }
            rows.slice().reverse().slice(0, 100).forEach(function (r) {
                var tr = $('<tr>').appendTo(tb);
                cell(tr, new Date(r.time * 1000).toLocaleString());
                if (r.ok) {
                    [r.down, r.up, r.ping, r.jitter, r.loss, r.server, r.isp, r.iface].forEach(function (v) { cell(tr, v); });
                } else {
                    $('<td colspan="8" class="text-danger">').text(r.error).appendTo(tr);
                }
            });
        });
    }

    var startGrace = 0;  // polls to wait for the background job to take its lock after Start
    function poll() {
        $.get('/api/speedtest/service/status', function (s) {
            $('#noCli').toggle(!s.cli);
            $('#noLicense').toggle(!s.license);
            $('#runBtn').prop('disabled', !s.cli || !s.license || s.running || startGrace > 0);
            if (s.running) startGrace = 0;
            if (s.running || startGrace-- > 0) {
                $('#runMsg').html('<i class="fa fa-spinner fa-spin"></i> Running...');
                setTimeout(poll, 2000);
            } else {
                $('#runMsg').text('');
                loadResults();
            }
        });
    }

    $('#runBtn').click(function () {
        $(this).prop('disabled', true);
        startGrace = 5;
        $.post('/api/speedtest/service/start', function () { setTimeout(poll, 1000); });
    });

    $('#clearBtn').click(function () {
        if (confirm('Delete all stored results?')) {
            $.post('/api/speedtest/service/clear', function () { $('#latest').text('No results yet.').addClass('text-muted'); loadResults(); });
        }
    });

    $('#installBtn').click(function () {
        $('#installMsg').text('Installing...');
        $.post('/api/speedtest/service/install', function (d) { $('#installMsg').text(d.output); poll(); });
    });

    mapDataToFormUI({'frm_settings': '/api/speedtest/settings/get'}).done(function () {
        $('.selectpicker').selectpicker('refresh');
    });
    $('#saveBtn').click(function () {
        saveFormToEndpoint('/api/speedtest/settings/set', 'frm_settings', poll, true);
    });

    $('#serversBtn').click(function () {
        var b = $(this).prop('disabled', true);
        $.get('/api/speedtest/service/servers', function (d) {
            var tb = $('#servers tbody').empty();
            (d.servers || []).forEach(function (s) {
                var tr = $('<tr style="cursor:pointer">').appendTo(tb);
                cell(tr, s.id); cell(tr, s.name); cell(tr, s.location + ', ' + s.country);
                tr.click(function () { $(serverField).val(s.id); });
            });
            $('#servers').show();
        }).always(function () { b.prop('disabled', false); });
    });

    poll();
});
</script>
