sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"certifications/test/integration/pages/EmployeeCertificationsList",
	"certifications/test/integration/pages/EmployeeCertificationsObjectPage"
], function (JourneyRunner, EmployeeCertificationsList, EmployeeCertificationsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('certifications') + '/test/flp.html#app-preview',
        pages: {
			onTheEmployeeCertificationsList: EmployeeCertificationsList,
			onTheEmployeeCertificationsObjectPage: EmployeeCertificationsObjectPage
        },
        async: true
    });

    return runner;
});

