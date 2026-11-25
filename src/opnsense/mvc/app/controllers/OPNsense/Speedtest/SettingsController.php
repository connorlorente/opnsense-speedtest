<?php

namespace OPNsense\Speedtest;

class SettingsController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->settingsForm = $this->getForm('settings');
        $this->view->pick('OPNsense/Speedtest/settings');
    }
}
