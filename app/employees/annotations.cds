using AdminService as service from '../../srv/admin-service';

annotate service.Employees with @(
    UI.HeaderInfo     : {
        TypeName      : '{i18n>EmployeeTypeName}',
        TypeNamePlural: '{i18n>EmployeeTypeNamePlural}',
        Title         : {Value: name},
        Description   : {Value: userID}
    },

    UI.LineItem       : [
        {Value: name},
        {Value: userID},
        {Value: email},
        {Value: manager_ID},
        {Value: active},
    ],

    UI.SelectionFields: [
        name,
        active,
        manager_ID,
    ],

        UI.Facets             : [{
        $Type : 'UI.ReferenceFacet',
        ID    : 'DetailsFacet',
        Label : '{i18n>DetailsSection}',
        Target: '@UI.FieldGroup#Details'
    }],

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
            { $Type: 'Common.ValueListParameterInOut',       LocalDataProperty: manager_ID, ValueListProperty: 'ID' },
            { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'name' },
            { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'userID' },
            { $Type: 'Common.ValueListParameterConstant',    ValueListProperty: 'active', Constant: 'true' }
        ]
    };
};
