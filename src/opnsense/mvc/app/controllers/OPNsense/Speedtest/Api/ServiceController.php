<?php

namespace OPNsense\Speedtest\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;

class ServiceController extends ApiControllerBase
{
    private function json($action)
    {
        return json_decode((new Backend())->configdRun($action), true) ?? [];
    }

    public function startAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        (new Backend())->configdRun('speedtest start');
        return ['status' => 'started'];
    }

    public function clearAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        return $this->json('speedtest clear');
    }

    public function installAction()
    {
        if (!$this->request->isPost()) {
            return ['status' => 'failed'];
        }
        return ['status' => 'ok', 'output' => trim((new Backend())->configdRun('speedtest install_cli'))];
    }

    public function statusAction()
    {
        return $this->json('speedtest status');
    }

    public function resultsAction()
    {
        return ['rows' => $this->json('speedtest results')];
    }

    public function summaryAction()
    {
        return $this->json('speedtest summary');
    }

    public function serversAction()
    {
        return $this->json('speedtest servers');
    }
}
