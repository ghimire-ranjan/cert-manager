using AdminService as service from '../../srv/admin-service';

// Admin app to maintain the exam catalogue (list + edit page, no delete)
annotate service.Certifications with @(
    UI.HeaderInfo         : {
        TypeName      : '{i18n>ExamTypeName}',
        TypeNamePlural: '{i18n>ExamTypeNamePlural}',
        Title         : {Value: code},
        Description   : {Value: name}
    },

    UI.LineItem           : [
        {Value: code},
        {Value: name},
        {Value: issuer},
    ],

    UI.SelectionFields    : [
        code,
        issuer,
    ],

    UI.Facets             : [{
        $Type : 'UI.ReferenceFacet',
        ID    : 'DetailsFacet',
        Label : '{i18n>DetailsSection}',
        Target: '@UI.FieldGroup#Details'
    }],

    UI.FieldGroup #Details: {Data: [
        {Value: code},
        {Value: name},
        {Value: issuer},
    ]}
);
