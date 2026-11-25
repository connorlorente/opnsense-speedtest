<div class="content-box">
    <div class="col-xs-12" style="padding-top:15px;padding-bottom:15px">
        {{ partial("layout_partials/base_form",['fields':settingsForm,'id':'frm_settings']) }}
        <button id="saveBtn" class="btn btn-primary">Save</button>
        <button id="serversBtn" class="btn btn-default">Find servers</button>
        <span id="saveMsg" role="status" style="margin-left:10px"></span>
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

    mapDataToFormUI({'frm_settings': '/api/speedtest/settings/get'}).done(function () {
        $('.selectpicker').selectpicker('refresh');
    });
    $('#saveBtn').click(function () {
        $('#saveMsg').text('');
        saveFormToEndpoint('/api/speedtest/settings/set', 'frm_settings', function () { $('#saveMsg').text('Saved.'); }, true);
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
});
</script>
