using AdminService as service from '../../srv/admin-service';

annotate service.Employees with @(
    UI.HeaderInfo         : {
        TypeName      : '{i18n>EmployeeTypeName}',
        TypeNamePlural: '{i18n>EmployeeTypeNamePlural}',
        Title         : {Value: name},
        Description   : {Value: userID}
    },

    UI.LineItem           : [
        {Value: name},
        {Value: userID},
        {Value: email},
        {Value: manager_ID},
        {Value: active},
    ],

    UI.SelectionFields    : [
        name,
        active,
        manager_ID,
    ],

    UI.Facets             : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'DetailsFacet',
            Label : '{i18n>DetailsSection}',
            Target: '@UI.FieldGroup#Details'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'CertificationsFacet',
            Label : '{i18n>CertificationsSection}',
            Target: 'certifications/@UI.LineItem#ForEmployee'
        }
    ],


    UI.FieldGroup #Details: {Data: [
        {Value: name},
        {Value: userID},
        {Value: email},
        {Value: manager_ID},
        {Value: active},
    ]}
);


// Manager picker: only active employees, shown by name
annotate service.Employees with {
    manager @Common.ValueList: {
        CollectionPath: 'Employees',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: manager_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'userID'
            },
            {
                $Type            : 'Common.ValueListParameterConstant',
                ValueListProperty: 'active',
                Constant         : 'true'
            }
        ]
    };
};

// The employee page's certifications table, with the admin's buttons
annotate service.EmployeeCertifications with @(UI.LineItem #ForEmployee: [
    {Value: certificate.code},
    {Value: certificate.name},
    {Value: status_code},
    {Value: validUntil},
    {
        Value      : daysUntilExpiry,
        Criticality: expiryCriticality
    },
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
]);
