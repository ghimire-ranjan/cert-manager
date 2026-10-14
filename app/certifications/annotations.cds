using CertService as service from '../../srv/cert-service';

annotate service.EmployeeCertifications with @(
    UI.LineItem       : [
        {Value: certificate.code},
        {Value: certificate.name},
        {Value: employee.name},
        {Value: status_code},
        {Value: plannedFor},
        {Value: validUntil},
        {
            Value      : daysUntilExpiry,
            Criticality: expiryCriticality
        },

    ],

    UI.SelectionFields: [
        status_code,
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
        {Value: status_code},
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

