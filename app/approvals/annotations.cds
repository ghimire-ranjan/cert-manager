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
                {
            Value      : daysUntilExpiry,
            Criticality: expiryCriticality
        },

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


// Only offer the actions that fit the record's current status
annotate service.EmployeeCertifications with actions {
    approve @Core.OperationAvailable: ($self.status = 'Pending');
    reject  @Core.OperationAvailable: ($self.status = 'Pending');
    revoke  @Core.OperationAvailable: ($self.status = 'Verified'
    or                                 $self.status = 'Rejected');
};


//tabs use selction Variant
annotate service.EmployeeCertifications with @(
    UI.SelectionVariant #All     : {
        SelectOptions: [],
        Text         : '{i18n>TabAll}'
    },
    UI.SelectionVariant #Pending : {
        SelectOptions: [{
            PropertyName: status,
            Ranges      : [{
                Sign  : #I,
                Option: #EQ,
                Low   : 'Pending'
            }]
        }],
        Text         : '{i18n>TabPending}'
    },
    UI.SelectionVariant #Verified: {
        SelectOptions: [{
            PropertyName: status,
            Ranges      : [{
                Sign  : #I,
                Option: #EQ,
                Low   : 'Verified'
            }]
        }],
        Text         : '{i18n>TabVerified}'
    },
    UI.SelectionVariant #Rejected: {
        SelectOptions: [{
            PropertyName: status,
            Ranges      : [{
                Sign  : #I,
                Option: #EQ,
                Low   : 'Rejected'
            }]
        }],
        Text         : '{i18n>TabRejected}'
    },
);
