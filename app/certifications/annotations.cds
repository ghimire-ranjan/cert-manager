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

annotate service.EmployeeCertifications with @(

    UI.HeaderInfo          : {
        TypeName      : '{i18n>TypeName}',
        TypeNamePlural: '{i18n>TypeNamePlural}',
        Title         : {Value: certificate.name},
        Description   : {Value: employee.name}
    },

    UI.Facets              : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneralFacet',
            Label : '{i18n>GeneralSection}',
            Target: '@UI.FieldGroup#General'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ValidityFacet',
            Label : '{i18n>ValiditySection}',
            Target: '@UI.FieldGroup#Validity'
        }
    ],

    UI.FieldGroup #General : {Data: [
        {Value: certificate.code},
        {Value: employee.name},
        {Value: status},
        {
            $Type: 'UI.DataFieldWithUrl',
            Value: evidenceUrl,
            Url  : evidenceUrl
        }

    ]},

    UI.FieldGroup #Validity: {Data: [
        {Value: plannedFor},
        {Value: earnedOn},
        {Value: validUntil},
        {
            Value      : daysUntilExpiry,
            Criticality: expiryCriticality
        }
    ]}
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
