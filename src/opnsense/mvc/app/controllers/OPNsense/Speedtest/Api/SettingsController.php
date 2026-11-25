<?php

namespace OPNsense\Speedtest\Api;

use OPNsense\Base\ApiMutableModelControllerBase;
use OPNsense\Core\Backend;

class SettingsController extends ApiMutableModelControllerBase
{
    protected static $internalModelName = 'speedtest';
    protected static $internalModelClass = 'OPNsense\Speedtest\Speedtest';

    public function setAction()
    {
        $result = parent::setAction();
        if (($result['result'] ?? '') === 'saved') {
            // schedule lives in cron (see plugins.inc.d/speedtest.inc)
            (new Backend())->configdRun('speedtest cron_apply');
        }
        return $result;
    }
}
