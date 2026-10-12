sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"approvals/test/integration/pages/EmployeeCertificationsList",
	"approvals/test/integration/pages/EmployeeCertificationsObjectPage"
], function (JourneyRunner, EmployeeCertificationsList, EmployeeCertificationsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('approvals') + '/test/flpSandbox.html#approvals-tile',
        pages: {
			onTheEmployeeCertificationsList: EmployeeCertificationsList,
			onTheEmployeeCertificationsObjectPage: EmployeeCertificationsObjectPage
        },
        async: true
    });

    return runner;
});

