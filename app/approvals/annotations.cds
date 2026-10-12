using AdminService as service from '../../srv/admin-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem       : [
        {Value: employee.name},
        {Value: certificate.code},
        {Value: certificate.name},
        {Value: status},
        {Value: earnedOn},
        {
            $Type: 'UI.DataFieldWithUrl',
            Value: evidenceUrl,
            Url  : evidenceUrl
        },
        {Value: validUntil},
    ],

    UI.SelectionFields: [
        status,
        earnedOn,
    ],
);


annotate service.EmployeeCertifications with @(
    UI.HeaderInfo        : {
        TypeName      : '{i18n>TypeName}',
        TypeNamePlural: '{i18n>TypeNamePlural}',
        Title         : {Value: employee.name},
        Description   : {Value: certificate.name}
    },

    UI.Identification    : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.approve',
            Label : '{i18n>Approve}'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.reject',
            Label : '{i18n>Reject}'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.revoke',
            Label : '{i18n>Revoke}'
        },
    ],

    UI.Facets            : [{
        $Type : 'UI.ReferenceFacet',
        ID    : 'ReviewFacet',
        Label : '{i18n>ReviewSection}',
        Target: '@UI.FieldGroup#Review'
    }],

    UI.FieldGroup #Review: {Data: [
        {Value: certificate.code},
        {Value: status},
        {Value: earnedOn},
        {Value: validUntil},
        {
            $Type: 'UI.DataFieldWithUrl',
            Value: evidenceUrl,
            Url  : evidenceUrl
        },
    ]}
);
