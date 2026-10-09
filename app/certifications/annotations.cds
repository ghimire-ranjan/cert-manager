using CertService as service from '../../srv/cert-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem       : [
        {
            Value: certificate.code,
            Label: '{i18n>Certificate}'
        },
        {
            Value: certificate.name,
            Label: '{i18n>Name}'
        },
        {
            Value: employee.name,
            Label: '{i18n>Employee}'
        },
        {
            Value: status,
            Label: '{i18n>Status}'
        },
        {
            Value: plannedFor,
            Label: '{i18n>PlannedFor}'
        },
        {
            Value: validUntil,
            Label: '{i18n>ValidUntil}'
        },
        {
            Value      : daysUntilExpiry,
            Label      : '{i18n>DaysLeft}',
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
    isEarned @Common.Label : '{i18n>IsEarned}'
};

annotate service.EmployeeCertifications with {
    validUntil @Common.Label : '{i18n>ValidUntil}'
};

annotate service.EmployeeCertifications with {
    status @Common.Label : '{i18n>Status}'
};

