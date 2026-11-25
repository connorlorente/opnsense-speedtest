<?php

namespace OPNsense\Speedtest;

class IndexController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->settingsForm = $this->getForm('settings');
        $this->view->pick('OPNsense/Speedtest/index');
    }
}
