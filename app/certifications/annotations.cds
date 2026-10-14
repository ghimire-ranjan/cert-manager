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
        {Value: certificate_ID},
        {Value: employee_ID},
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


// Pick a certification from the catalogue; the employee is filled in by the server
annotate service.EmployeeCertifications with {
    certificate @Common.Text: certificate.name
                @Common.TextArrangement: #TextOnly
                @Common.ValueList: {
                    CollectionPath: 'Certifications',
                    Parameters    : [
                        { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: certificate_ID, ValueListProperty: 'ID' },
                        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'code' },
                        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' }
                    ]
                };
    employee    @Common.Text: employee.name
                @Common.TextArrangement: #TextOnly
                @Common.FieldControl: #ReadOnly;
};

// In the value help, show the name instead of the ID
annotate service.Certifications with {
    ID @Common.Text: name @Common.TextArrangement: #TextOnly;
};

