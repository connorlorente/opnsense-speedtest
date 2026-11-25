import '../speedtest_gauges.js';

export default class Speedtest extends BaseWidget {
    constructor() {
        super();
        this.tickTimeout = 60;
    }

    getMarkup() {
        return $('<div class="speedtest-gauges"></div>');
    }

    async onMarkupRendered() {
        await this.onWidgetTick();  // fill before the dashboard measures the widget
    }

    async onWidgetTick() {
        const summary = await this.ajaxCall('/api/speedtest/service/summary');
        $('.speedtest-gauges').html(window.speedtestGauges(summary));
    }
}
