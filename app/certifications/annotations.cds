using CertService as service from '../../srv/cert-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem       : [
        {Value: certificate.code},
        {Value: certificate.name},
        {Value: employee.name},
        {Value: status},
        {Value: plannedFor},
        {Value: validUntil},
        {
            Value      : daysUntilExpiry,
            Criticality: expiryCriticality
        },

    ],

    UI.SelectionFields: [
        status,
        validUntil,
        isEarned,
    ],
);

annotate service.EmployeeCertifications with {
    certificate     @Common.Label: '{i18n>Certificate}';
    employee        @Common.Label: '{i18n>Employee}';
    status          @Common.Label: '{i18n>Status}';
    earnedOn        @Common.Label: '{i18n>EarnedOn}';
    plannedFor      @Common.Label: '{i18n>PlannedFor}';
    validUntil      @Common.Label: '{i18n>ValidUntil}';
    isEarned        @Common.Label: '{i18n>IsEarned}';
    evidenceUrl     @Common.Label: '{i18n>EvidenceUrl}';
    daysUntilExpiry @Common.Label: '{i18n>DaysLeft}';
};

annotate service.Certifications with {
    code   @Common.Label: '{i18n>CertCode}';
    name   @Common.Label: '{i18n>CertName}';
    issuer @Common.Label: '{i18n>Issuer}';
};

annotate service.Employees with {
    name @Common.Label: '{i18n>EmployeeName}';
};
